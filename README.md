# BitFlow Protocol

<p align="center">
  <img src="https://img.shields.io/badge/Clarity-3.0-blue?style=for-the-badge" alt="Clarity Version">
  <img src="https://img.shields.io/badge/Bitcoin-L2-orange?style=for-the-badge" alt="Bitcoin L2">
  <img src="https://img.shields.io/badge/Stacks-DeFi-purple?style=for-the-badge" alt="Stacks DeFi">
</p>

**A Bitcoin-native decentralized exchange and automated market maker (AMM) built on Stacks, enabling seamless token swaps, liquidity provision, and yield farming with Bitcoin's security guarantees.**

## 🌟 Overview

BitFlow Protocol brings sophisticated DeFi capabilities to Bitcoin through the Stacks blockchain, offering a trustless and censorship-resistant trading environment that maintains Bitcoin's core principles. Built with security-first architecture and capital efficiency in mind, BitFlow enables users to participate in decentralized finance while benefiting from Bitcoin's robustness.

### Key Features

- **🔄 Automated Market Making**: Constant Product Market Maker (x*y=k) for predictable liquidity and efficient price discovery
- **💰 Dual-Token Liquidity Pools**: Create and participate in trading pairs with proportional reward distribution
- **🌾 Native Yield Farming**: Block-based reward accrual system with governance-controlled parameters  
- **⚡ Gas-Optimized Operations**: Cost-effective transactions optimized for Bitcoin L2 scaling
- **🛡️ Security-First Design**: Multi-token whitelist model with comprehensive access controls
- **🏛️ Governance Integration**: Decentralized parameter adjustment and protocol upgrades

## 🏗️ Architecture

BitFlow Protocol implements a sophisticated AMM with the following core components:

### Smart Contract Structure

```
contracts/
├── bitflow.clar       # Main AMM contract with all trading logic
└── ft-trait.clar      # SIP-010 Fungible Token trait interface
```

### Core Functionality

- **Liquidity Management**: Pool initialization, liquidity addition/removal
- **Token Swapping**: Efficient token exchanges with slippage protection  
- **Yield Farming**: Automated reward distribution to liquidity providers
- **Governance**: Owner-controlled parameters and token approvals

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (v18+ recommended)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/frank-adekunle/bitflow.git
   cd bitflow
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Verify installation**

   ```bash
   clarinet --version
   ```

### Development Setup

1. **Check contract syntax**

   ```bash
   clarinet check
   ```

2. **Run tests**

   ```bash
   npm test
   ```

3. **Run tests with coverage**

   ```bash
   npm run test:report
   ```

4. **Watch mode for development**

   ```bash
   npm run test:watch
   ```

## 📖 Usage

### Creating a Liquidity Pool

Initialize a new trading pair with initial liquidity:

```clarity
(contract-call? .bitflow initialize-pool
  .token-a-contract    ;; First token contract
  .token-b-contract    ;; Second token contract  
  u1000000             ;; Initial amount of token A (with decimals)
  u2000000             ;; Initial amount of token B (with decimals)
)
```

### Adding Liquidity

Provide liquidity to an existing pool:

```clarity
(contract-call? .bitflow add-liquidity
  .token-a-contract    ;; Token A contract
  .token-b-contract    ;; Token B contract
  u500000              ;; Amount of token A to add
  u1000000             ;; Amount of token B to add
  u450000              ;; Minimum LP shares to receive (slippage protection)
)
```

### Token Swapping

Execute a token swap with slippage protection:

```clarity
(contract-call? .bitflow swap-exact-tokens-for-tokens
  .token-input         ;; Input token contract
  .token-output        ;; Output token contract
  u1000000             ;; Exact input amount
  u950000              ;; Minimum output amount (slippage protection)
)
```

### Removing Liquidity

Withdraw your liquidity position:

```clarity
(contract-call? .bitflow remove-liquidity
  .token-a-contract    ;; Token A contract
  .token-b-contract    ;; Token B contract
  u500000              ;; LP shares to burn
  u480000              ;; Minimum token A to receive
  u960000              ;; Minimum token B to receive
)
```

### Harvesting Rewards

Claim accumulated yield farming rewards:

```clarity
(contract-call? .bitflow harvest-rewards
  .token-a-contract    ;; Pool token A
  .token-b-contract    ;; Pool token B
)
```

## 🔧 Configuration

### Protocol Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `REWARD-RATE-PER-BLOCK` | 10 | Base rewards per block for liquidity providers |
| `MIN-LIQUIDITY-FOR-REWARDS` | 100 | Minimum LP tokens required to earn rewards |
| `TRADING-FEE-BASIS-POINTS` | 300 | Trading fee (0.3% = 300/10000) |
| `MAX-REWARD-RATE` | 1,000,000 | Maximum governance-settable reward rate |

### Environment Configuration

The protocol supports multiple deployment environments:

- **Devnet**: Local development and testing
- **Testnet**: Public testing environment  
- **Mainnet**: Production deployment

Configuration files are located in the `settings/` directory.

## 🧪 Testing

BitFlow Protocol includes comprehensive test coverage using Clarinet SDK and Vitest:

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Run tests in watch mode
npm run test:watch

# Check contract syntax only
clarinet check
```

### Test Structure

```
tests/
├── bitflow.test.ts    # Core AMM functionality tests
└── ft-trait.test.ts   # Token trait implementation tests
```

## 📊 Economics

### Fee Structure

- **Trading Fee**: 0.3% (300 basis points) on all swaps
- **Protocol Fee**: Configurable percentage of trading fees for protocol development

### Yield Farming

- **Base Rewards**: 10 tokens per block for liquidity providers
- **Minimum Threshold**: 100 LP tokens required to earn rewards
- **Distribution**: Proportional to LP token holdings
- **Governance**: Reward rates adjustable by protocol governance

### Liquidity Incentives

- **Initial Liquidity**: Geometric mean of provided amounts `sqrt(x * y)`
- **Additional Liquidity**: Proportional shares based on existing pool ratios
- **Fair Distribution**: Time-weighted reward accumulation prevents gaming

## 🛡️ Security

### Security Features

- **Token Whitelist**: Only approved tokens can be traded
- **Access Controls**: Owner-only functions for critical operations
- **Input Validation**: Comprehensive checks on all user inputs
- **Slippage Protection**: Minimum output validation on swaps
- **Integer Overflow Protection**: Safe arithmetic operations throughout

### Audit Recommendations

1. **External Security Audit**: Recommended before mainnet deployment
2. **Formal Verification**: Consider formal verification of critical functions
3. **Bug Bounty Program**: Implement community-driven security testing
4. **Multi-sig Governance**: Use multi-signature for owner operations

## 🤝 Contributing

We welcome contributions from the community! Please see our contributing guidelines:

### Development Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`npm test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Standards

- Follow Clarity best practices and conventions
- Include comprehensive tests for all new functionality
- Update documentation for any API changes
- Ensure code passes all linting and formatting checks

## 📚 Documentation

### API Reference

Detailed function documentation is available in the contract source code. Key read-only functions:

- `get-pool-info`: Retrieve pool statistics and reserves
- `get-user-position`: Check user's liquidity position
- `get-swap-quote`: Calculate swap output without execution
- `get-reward-rate`: Current yield farming reward rate

### Integration Guides

- [Frontend Integration](docs/frontend-integration.md)
- [Wallet Integration](docs/wallet-integration.md)
- [API Documentation](docs/api-reference.md)

## 📋 Roadmap

### Phase 1: Core AMM (Current)

- ✅ Basic liquidity pools
- ✅ Token swapping
- ✅ Yield farming
- ✅ Comprehensive testing

### Phase 2: Advanced Features

- 🔄 Multi-hop routing
- 🔄 Flash loans
- 🔄 Advanced order types
- 🔄 Cross-chain bridges

### Phase 3: Governance & DAO

- ⏳ Governance token launch
- ⏳ Decentralized parameter control
- ⏳ Community treasury management
- ⏳ Protocol upgrade mechanisms

## 🌐 Community

- **Website**: [Coming Soon]
- **Discord**: [Join our community](https://discord.gg/bitflow)
- **Twitter**: [@BitFlowProtocol](https://twitter.com/BitFlowProtocol)
- **Telegram**: [BitFlow Community](https://t.me/bitflowprotocol)

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
