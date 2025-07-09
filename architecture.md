# FRW-iOS (Lilico) Wallet App Architecture and API Documentation

## Architecture Diagram

```
+--------------------------------------------------------------------------------------------------+
|                                     Flow Wallet iOS App (Lilico)                                  |
+--------------------------------------------------------------------------------------------------+
|                                                                                                  |
|  +----------------+    +----------------+    +----------------+    +----------------+            |
|  |                |    |                |    |                |    |                |            |
|  |  UI Components |    |    Managers    |    |    Services    |    |    Database    |            |
|  |                |    |                |    |                |    |                |            |
|  +-------+--------+    +-------+--------+    +-------+--------+    +-------+--------+            |
|          |                     |                     |                     |                      |
|          v                     v                     v                     v                      |
|  +----------------+    +----------------+    +----------------+    +----------------+            |
|  |                |    |                |    |                |    |                |            |
|  |   Animation    |    | AccountManager |    |   BugReport    |    |   DBManager    |            |
|  |   Component    |    | WalletManager  |    |     Cache      |    |                |            |
|  |   Extension    |    | UserManager    |    |     Crypto     |    |                |            |
|  |   UIKit        |    | SecurityManager|    |    Firebase    |    |                |            |
|  +----------------+    +----------------+    +----------------+    +----------------+            |
|                                |                                                                 |
|                                v                                                                 |
|  +----------------+    +----------------+    +----------------+    +----------------+            |
|  |                |    |                |    |                |    |                |            |
|  |  Network Layer |    |  FlowCoin API  |    | WalletConnect  |    |  Third-party   |            |
|  |                |    |                |    |                |    |  Integrations  |            |
|  +-------+--------+    +-------+--------+    +-------+--------+    +-------+--------+            |
|          |                     |                     |                     |                      |
+----------|---------------------|---------------------|---------------------|----------------------+
           |                     |                     |                     |
           v                     v                     v                     v
+----------+---------+ +---------+---------+ +---------+---------+ +---------+---------+
|                    | |                   | |                   | |                   |
| Lilico Backend API | |  Flow Blockchain  | | WalletConnect API | |   Firebase        |
| (API_HOST)         | |                   | |                   | |   Track           |
| (BASE_HOST)        | |                   | |                   | |   BugReport       |
|                    | |                   | |                   | |                   |
+--------------------+ +-------------------+ +-------------------+ +-------------------+
           |                     |                     |                     |
           v                     v                     v                     v
+----------+---------+ +---------+---------+ +---------+---------+ +---------+---------+
|                    | |                   | |                   | |                   |
| FlowNS             | | MoonPay           | | Flowscan          | | Firebase Cloud    |
| Key Indexer        | |                   | |                   | | Functions         |
|                    | |                   | |                   | |                   |
+--------------------+ +-------------------+ +-------------------+ +-------------------+
```

## App Architecture Overview

The FRW-iOS (Lilico) wallet app follows a modular architecture with clear separation of concerns:

1. **UI Components**: Handles user interface elements and interactions
   - Animation: UI animations and transitions
   - Component: Reusable UI components
   - Extension: UI-related extensions
   - UIKit: Custom UIKit implementations

2. **Managers**: Handles business logic and state management
   - AccountManager: User account management
   - WalletManager: Wallet functionality
   - UserManager: User profile and preferences
   - SecurityManager: Security features and authentication

3. **Services**: Shared services used across the app
   - BugReport: Error reporting and logging
   - Cache: Data caching
   - Crypto: Cryptographic operations
   - Firebase: Firebase integration

4. **Database**: Local data storage
   - DBManager: Database operations and management

5. **Network Layer**: Handles API communication with external services
   - Network components for API requests
   - FlowCoin API integration
   - WalletConnect integration
   - Third-party service integrations

### Key Components

#### Feature Modules
- **Wallet Module**: Core wallet functionality for managing crypto assets
- **NFT Module**: NFT management and display
- **Transaction Module**: Transaction creation, signing, and history
- **Swap Module**: Token swapping functionality
- **Browser Module**: In-app web browser for dApps
- **EVM Module**: Ethereum Virtual Machine compatibility
- **Profile Module**: User profile management
- **ChildAccount Module**: Child account management
- **Staking Module**: Token staking functionality

#### Core Services
- **Security Services**: Secure key storage using iOS Secure Enclave
- **Network Services**: API communication and data fetching
- **Cache Services**: Local data caching and persistence
- **WalletConnect**: Integration with WalletConnect protocol
- **FlowCoin Services**: Flow blockchain interaction

#### External Integrations
- **Firebase**: Authentication and analytics
- **MoonPay**: Fiat-to-crypto on-ramp
- **Flowscan**: Blockchain explorer integration
- **FlowNS**: Flow Name Service integration

## External APIs

The app interacts with multiple external APIs:

### 1. Flow Blockchain API
- **Purpose**: Core blockchain interactions
- **Base URL**: Not directly specified, accessed through Flow SDK
- **Key Endpoints**:
  - Token operations (balance checks, transfers)
  - NFT operations
  - Account information
  - Transaction submission and monitoring

### 2. Alchemy API
- **Purpose**: NFT data retrieval
- **Base URL**: `https://flow-mainnet.g.alchemy.com/v2/twx0ea5rbnqjbg7ev8jb058pqg50wklj/`
- **Key Endpoints**:
  - `/getNFTs/`: Get NFTs owned by an address

### 3. Lilico Backend API
- **Purpose**: App-specific backend services
- **Base URL**: Configured via `Config.get(.lilico)`
- **Key Endpoints**:
  - `/v2/account/query`: Account queries
  - `/v1/account/transfers`: Account transfers
  - `/v1/account/tokentransfers`: Token transfers
  - Various endpoints for user, profile, NFT, token management

### 4. Lilico Web API
- **Purpose**: Web-specific functionality
- **Base URL**: Configured via `Config.get(.lilicoWeb)`
- **Key Endpoints**:
  - `/v2/evm/{address}/transactions`: EVM transactions

### 5. Flow Web API
- **Purpose**: Transaction templates and swaps
- **Base URL**: `https://web.api.wallet.flow.com/api/`
- **Key Endpoints**:
  - `/template`: Transaction templates
  - `/swap/v1/{network}/estimate`: Swap estimates

### 6. GitHub Repositories
- **Purpose**: Configuration data
- **Base URL**: `https://raw.githubusercontent.com`
- **Key Endpoints**:
  - `/Outblock/Assets/main/nft/nft.json`: NFT collections
  - `/Outblock/token-list-jsons/outblock/jsons/{network}/flow/{mode}.json`: Token lists
  - `/Outblock/token-list-jsons/outblock/jsons/{network}/flow/nfts.json`: NFT lists
  - `/Outblock/token-list-jsons/outblock/jsons/{network}/evm/{mode}.json`: EVM token lists

### 7. Firebase
- **Purpose**: Authentication and backend services
- **Integration**: Through FirebaseAuth SDK
- **Usage**: User authentication, anonymous sign-in, ID token generation

### 8. FlowScan API
- **Purpose**: Transaction history and account data
- **Access Method**: GraphQL queries through Lilico backend
- **Key Queries**: Account transactions, transfer counts

## Key Dependencies

- **Moya/CombineMoya**: Network request handling
- **Flow SDK**: Flow blockchain interactions
- **Web3Core/web3swift**: Ethereum blockchain interactions
- **FirebaseAuth**: Authentication
- **BigInt**: Large number handling
- **CryptoKit**: Cryptographic operations
- **Combine**: Reactive programming

## Security Features

- **Secure Enclave**: Private key storage in iOS Secure Enclave
- **Firebase Authentication**: User authentication
- **Token-based API Access**: Bearer token authentication for API calls

## Multi-Chain Support

The app supports multiple blockchain networks:
- **Flow**: Primary blockchain
- **Ethereum/EVM**: Through EVM compatibility module
- **Network Selection**: Supports mainnet and testnet environments

## Conclusion

The FRW-iOS (Lilico) wallet app is a comprehensive cryptocurrency wallet focused primarily on the Flow blockchain with EVM compatibility. It follows a modular architecture with clear separation of concerns and interacts with multiple external APIs to provide a complete wallet experience including token management, NFTs, transactions, and dApp interactions.
