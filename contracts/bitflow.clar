;; Title: BitFlow Protocol - Decentralized Exchange on Bitcoin
;; 
;; Summary: A Bitcoin-native automated market maker enabling seamless token swaps 
;; and liquidity provision on the Stacks blockchain with integrated yield farming.
;;
;; Description:
;; BitFlow Protocol brings sophisticated DeFi capabilities to Bitcoin through Stacks,
;; offering a decentralized exchange where users can create liquidity pools, provide
;; liquidity to earn rewards, execute efficient token swaps, and participate in yield
;; farming. Built with security-first principles and Bitcoin's robustness in mind,
;; BitFlow enables capital efficient trading while maintaining the trustless and
;; censorship-resistant properties that make Bitcoin the premier digital asset.
;;
;; Key Features:
;; - Constant Product Market Maker (x*y=k) for predictable liquidity
;; - Dual-token liquidity pools with proportional reward distribution  
;; - Native yield farming with block-based reward accrual
;; - Governance-controlled reward rate adjustments
;; - Multi-token support with whitelist security model
;; - Gas-optimized operations for cost-effective Bitcoin L2 transactions

;; Import fungible token trait interface
(use-trait ft-trait .ft-trait.ft-trait)

;; ERROR CONSTANTS
(define-constant ERR-INSUFFICIENT-FUNDS    (err u100))
(define-constant ERR-INVALID-AMOUNT        (err u101))
(define-constant ERR-POOL-NOT-EXISTS       (err u102))
(define-constant ERR-UNAUTHORIZED          (err u103))
(define-constant ERR-TRANSFER-FAILED       (err u104))
(define-constant ERR-INVALID-TOKEN         (err u105))
(define-constant ERR-INVALID-PAIR          (err u106))
(define-constant ERR-ZERO-AMOUNT          (err u107))
(define-constant ERR-MAX-AMOUNT-EXCEEDED   (err u108))
(define-constant ERR-DUPLICATE-TOKEN       (err u109))
(define-constant ERR-POOL-ALREADY-EXISTS   (err u110))

;; PROTOCOL CONSTANTS
(define-constant REWARD-RATE-PER-BLOCK     u10)        ;; Base rewards per block
(define-constant MIN-LIQUIDITY-FOR-REWARDS u100)       ;; Minimum LP tokens for rewards
(define-constant MAX-REWARD-RATE          u1000000)    ;; Maximum governance reward rate
(define-constant TRADING-FEE-BASIS-POINTS u300)        ;; 0.3% trading fee (300/10000)
(define-constant MAX-UINT                 u340282366920938463463374607431768211455)

;; STATE VARIABLES
(define-data-var contract-owner principal tx-sender)
(define-data-var reward-rate uint REWARD-RATE-PER-BLOCK)
(define-data-var protocol-fee-recipient principal tx-sender)

;; DATA MAPS

;; Whitelist of approved tokens for trading
(define-map approved-tokens 
    principal 
    { enabled: bool, added-at-block: uint }
)

;; Core liquidity pool storage
(define-map liquidity-pools 
    { token-x: principal, token-y: principal } 
    {
        total-liquidity: uint,
        reserve-x: uint,
        reserve-y: uint,
        created-at-block: uint,
        last-update-block: uint
    }
)

;; User liquidity positions and ownership shares
(define-map liquidity-positions 
    { user: principal, token-x: principal, token-y: principal } 
    { 
        shares: uint,
        last-claim-block: uint,
        total-deposited-x: uint,
        total-deposited-y: uint
    }
)

;; Yield farming reward tracking
(define-map farming-rewards 
    { user: principal, pool-token: principal } 
    { 
        accumulated-rewards: uint,
        last-reward-block: uint
    }
)

;; GOVERNANCE & ADMINISTRATION

;; Add token to approved trading list (Owner only)
(define-public (approve-token (token principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
        (asserts! (not (is-eq token (var-get contract-owner))) ERR-INVALID-TOKEN)
        (ok (map-set approved-tokens token { 
            enabled: true, 
            added-at-block: stacks-block-height 
        }))
    )
)

;; Update protocol reward rate (Owner only)
(define-public (update-reward-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
        (asserts! (<= new-rate MAX-REWARD-RATE) ERR-INVALID-AMOUNT)
        (var-set reward-rate new-rate)
        (ok true)
    )
)

;; Transfer ownership (Current owner only)
(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
        (var-set contract-owner new-owner)
        (ok true)
    )
)

;; CORE AMM FUNCTIONALITY

;; Initialize new liquidity pool with initial deposits
(define-public (initialize-pool 
    (token-x <ft-trait>) 
    (token-y <ft-trait>) 
    (initial-x uint) 
    (initial-y uint)
)
    (let (
        (token-x-principal (contract-of token-x))
        (token-y-principal (contract-of token-y))
        (ordered-pair (order-token-pair token-x-principal token-y-principal))
    )
        ;; Input validation
        (asserts! (is-valid-token-pair token-x-principal token-y-principal) ERR-INVALID-PAIR)
        (asserts! (and (> initial-x u0) (> initial-y u0)) ERR-INVALID-AMOUNT)
        
        ;; Ensure pool doesn't already exist
        (asserts! (is-none (map-get? liquidity-pools ordered-pair)) ERR-POOL-ALREADY-EXISTS)
        
        ;; Execute token transfers from user to contract
        (try! (contract-call? token-x transfer initial-x tx-sender (as-contract tx-sender) none))
        (try! (contract-call? token-y transfer initial-y tx-sender (as-contract tx-sender) none))
        
        ;; Initialize pool state
        (map-set liquidity-pools ordered-pair {
            total-liquidity: (calculate-initial-liquidity initial-x initial-y),
            reserve-x: initial-x,
            reserve-y: initial-y,
            created-at-block: stacks-block-height,
            last-update-block: stacks-block-height
        })
        
        ;; Grant initial LP tokens to pool creator
        (map-set liquidity-positions {
            user: tx-sender, 
            token-x: (get token-x ordered-pair), 
            token-y: (get token-y ordered-pair)
        } {
            shares: (calculate-initial-liquidity initial-x initial-y),
            last-claim-block: stacks-block-height,
            total-deposited-x: initial-x,
            total-deposited-y: initial-y
        })
        
        (ok true)
    )
)

;; Add liquidity to existing pool
(define-public (add-liquidity 
    (token-x <ft-trait>) 
    (token-y <ft-trait>) 
    (amount-x uint) 
    (amount-y uint)
    (min-shares uint)
)
    (let (
        (token-x-principal (contract-of token-x))
        (token-y-principal (contract-of token-y))
        (ordered-pair (order-token-pair token-x-principal token-y-principal))
    )
        ;; Input validation
        (asserts! (is-valid-token-pair token-x-principal token-y-principal) ERR-INVALID-PAIR)
        (asserts! (and (> amount-x u0) (> amount-y u0)) ERR-INVALID-AMOUNT)
        
        (let (
            (pool (unwrap! (map-get? liquidity-pools ordered-pair) ERR-POOL-NOT-EXISTS))
            (optimal-y (calculate-optimal-amount amount-x (get reserve-x pool) (get reserve-y pool)))
        )
            ;; Ensure provided amounts maintain pool ratio
            (asserts! (>= amount-y optimal-y) ERR-INVALID-AMOUNT)
            
            ;; Calculate LP shares to mint
            (let (
                (shares-to-mint (calculate-liquidity-shares 
                    amount-x 
                    (get reserve-x pool) 
                    (get total-liquidity pool)
                ))
            )
                (asserts! (>= shares-to-mint min-shares) ERR-INSUFFICIENT-FUNDS)

                ;; Execute token transfers
                (try! (contract-call? token-x transfer amount-x tx-sender (as-contract tx-sender) none))
                (try! (contract-call? token-y transfer optimal-y tx-sender (as-contract tx-sender) none))
                
                ;; Update pool reserves
                (map-set liquidity-pools ordered-pair {
                    total-liquidity: (+ (get total-liquidity pool) shares-to-mint),
                    reserve-x: (+ (get reserve-x pool) amount-x),
                    reserve-y: (+ (get reserve-y pool) optimal-y),
                    created-at-block: (get created-at-block pool),
                    last-update-block: stacks-block-height
                })
                
                ;; Update user liquidity position
                (update-user-liquidity-position 
                    tx-sender 
                    (get token-x ordered-pair) 
                    (get token-y ordered-pair)
                    shares-to-mint
                    amount-x
                    optimal-y
                )
                
                (ok shares-to-mint)
            )
        )
    )
)

;; Remove liquidity from pool
(define-public (remove-liquidity 
    (token-x <ft-trait>) 
    (token-y <ft-trait>) 
    (shares-to-burn uint)
    (min-x uint)
    (min-y uint)
)
    (let (
        (token-x-principal (contract-of token-x))
        (token-y-principal (contract-of token-y))
        (ordered-pair (order-token-pair token-x-principal token-y-principal))
    )
        ;; Input validation
        (asserts! (is-valid-token-pair token-x-principal token-y-principal) ERR-INVALID-PAIR)
        (asserts! (> shares-to-burn u0) ERR-INVALID-AMOUNT)
        
        (let (
            (user-position (unwrap! 
                (map-get? liquidity-positions {
                    user: tx-sender, 
                    token-x: (get token-x ordered-pair), 
                    token-y: (get token-y ordered-pair)
                })
                ERR-UNAUTHORIZED
            ))
            (pool (unwrap! (map-get? liquidity-pools ordered-pair) ERR-POOL-NOT-EXISTS))
        )
            ;; Validate sufficient shares
            (asserts! (<= shares-to-burn (get shares user-position)) ERR-INSUFFICIENT-FUNDS)
            
            ;; Calculate withdrawal amounts
            (let (
                (withdraw-x (/ (* shares-to-burn (get reserve-x pool)) (get total-liquidity pool)))
                (withdraw-y (/ (* shares-to-burn (get reserve-y pool)) (get total-liquidity pool)))
            )
                ;; Validate minimum withdrawal amounts
                (asserts! (and (>= withdraw-x min-x) (>= withdraw-y min-y)) ERR-INSUFFICIENT-FUNDS)
                
                ;; Execute token transfers back to user
                (try! (as-contract (contract-call? token-x transfer withdraw-x tx-sender tx-sender none)))
                (try! (as-contract (contract-call? token-y transfer withdraw-y tx-sender tx-sender none)))
                
                ;; Update pool state
                (map-set liquidity-pools ordered-pair {
                    total-liquidity: (- (get total-liquidity pool) shares-to-burn),
                    reserve-x: (- (get reserve-x pool) withdraw-x),
                    reserve-y: (- (get reserve-y pool) withdraw-y),
                    created-at-block: (get created-at-block pool),
                    last-update-block: stacks-block-height
                })
                
                ;; Update user position
                (map-set liquidity-positions {
                    user: tx-sender, 
                    token-x: (get token-x ordered-pair), 
                    token-y: (get token-y ordered-pair)
                } {
                    shares: (- (get shares user-position) shares-to-burn),
                    last-claim-block: (get last-claim-block user-position),
                    total-deposited-x: (get total-deposited-x user-position),
                    total-deposited-y: (get total-deposited-y user-position)
                })
                
                (ok { withdrawn-x: withdraw-x, withdrawn-y: withdraw-y })
            )
        )
    )
)