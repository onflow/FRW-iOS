# COA (Cadence Owned Account) Reference

Complete reference for all COA-related scenarios in the Flow Reference Wallet (FRW) project.

## Table of Contents

- [Overview](#overview)
- [1. Account Architecture](#1-account-architecture)
- [2. Cadence Transactions](#2-cadence-transactions)
- [3. Bridge Scenarios](#3-bridge-scenarios)
- [4. Balance Queries](#4-balance-queries)
- [5. EVM Integration](#5-evm-integration)
- [6. Send Workflow](#6-send-workflow)
- [7. Testing Scenarios](#7-testing-scenarios)
- [8. iOS Native Integration](#8-ios-native-integration)
- [9. Future Planning](#9-future-planning)

## Overview

**COA (Cadence Owned Account)** is a Flow EVM account owned by a Cadence account. It serves as a bridge between Flow's Cadence VM and EVM, enabling:

- Flow accounts to interact with EVM smart contracts
- Bridging assets between Flow and EVM environments
- Managing EVM addresses through Cadence ownership
- Cross-VM asset transfers (FT and NFT)

**Key Distinction**: COA vs EOA (Externally Owned Account)
- **COA**: Cadence-owned EVM account, controlled by Flow account keys
- **EOA**: Traditional EVM account with its own private key

## 1. Account Architecture

### 1.1 Account Type Definition

**Location**: `packages/wallet/src/account.ts`

```typescript
/**
 * Chain-Owned Account (COA) - matches iOS COA
 */
export class COA implements FlowVMProtocol {
  readonly vm = FlowVM.EVM;
  readonly address: string; // EVM address
  readonly chainID: FlowChainID;
}
```

**Account Class Integration**:
```typescript
export class Account implements FlowVMProtocol {
  // ... other properties
  childs?: ChildAccount[];
  coa?: COA;  // Optional COA attachment

  get hasCOA(): boolean {
    return this.coa !== undefined;
  }

  get hasLinkedAccounts(): boolean {
    return this.hasChild || this.hasCOA;
  }
}
```

**References**:
- `packages/wallet/src/account.ts:19-24` - COA class definition
- `packages/wallet/src/account.ts:43` - Account.coa property
- `packages/wallet/src/account.ts:64-70` - COA detection helpers

### 1.2 Account Type System

**Location**: `docs/epics/eoa-support.md`

```typescript
interface Account {
  address: string;
  type: 'EOA' | 'Flow' | 'ChildAccount' | 'COA';
  derivationPath?: string; // For EOA accounts
  publicKey: string;
}
```

**Architecture Evolution**:
- Current: COA model (Cadence-owned EVM accounts)
- Future: Hybrid EOA/COA model (see [Future Planning](#9-future-planning))

**References**:
- `docs/epics/eoa-support.md:48` - Account type definitions
- `docs/epics/eoa-support.md:6` - COA to EOA/COA hybrid transition

## 2. Cadence Transactions

### 2.1 COA Creation

**Transaction**: `packages/cadence/src/cadence/EVM/transaction/create_coa.cdc`

Creates a COA and deposits initial Flow tokens into it.

```cadence
transaction(amount: UFix64) {
    execute {
        let coa <- EVM.createCadenceOwnedAccount()
        coa.deposit(from: <-self.sentVault)

        let storagePath = StoragePath(identifier: "evm")!
        let publicPath = PublicPath(identifier: "evm")!
        self.auth.storage.save<@EVM.CadenceOwnedAccount>(<-coa, to: storagePath)
        let addressableCap = self.auth.capabilities.storage.issue<&EVM.CadenceOwnedAccount>(storagePath)
        self.auth.capabilities.unpublish(publicPath)
        self.auth.capabilities.publish(addressableCap, at: publicPath)
    }
}
```

**Service Methods**:
- `apps/extension/src/background/controller/wallet.ts:890` - `createCOA(amount)`
- `apps/extension/src/background/controller/wallet.ts:891` - `createCoaEmpty()`
- `apps/extension/src/background/controller/wallet.ts:892-893` - `trackCoaCreation(txID, errorMessage?)`

### 2.2 COA Withdrawal

**Transaction**: `packages/cadence/src/cadence/EVM/transaction/withdraw_coa.cdc`

Withdraws Flow tokens from COA to a Flow address.

```cadence
transaction(amount: UFix64, address: Address) {
    prepare(signer: auth(Storage, EVM.Withdraw) &Account) {
        let coa = signer.storage.borrow<auth(EVM.Withdraw) &EVM.CadenceOwnedAccount>(
            from: /storage/evm
        ) ?? panic("Could not borrow reference to the COA!")

        let withdrawBalance = EVM.Balance(attoflow: 0)
        withdrawBalance.setFLOW(flow: amount)
        self.sentVault <- coa.withdraw(balance: withdrawBalance) as! @FlowToken.Vault
    }

    execute {
        let receiver = account.capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        receiver.deposit(from: <-self.sentVault)
    }
}
```

**Service Method**:
- `apps/extension/src/background/controller/wallet.ts:928-929` - `withdrawFlowEvm(amount, address)`

### 2.3 COA Link Management

**Service Methods**:
- `apps/extension/src/background/controller/wallet.ts:931` - `coaLink()` - Link COA to account
- `apps/extension/src/background/controller/wallet.ts:932` - `checkCoaLink()` - Verify COA link status

**References**:
- `packages/cadence/src/cadence/EVM/transaction/create_coa.cdc` - COA creation
- `packages/cadence/src/cadence/EVM/transaction/withdraw_coa.cdc` - COA withdrawal

## 3. Bridge Scenarios

### 3.1 Fungible Token (FT) Bridging

#### Flow → EVM

**Strategy**: `FlowToEvmTokenStrategy`
**Location**: `packages/workflow/src/send/tokenStrategies.ts:130-158`

Transfers tokens from Flow account to EVM environment.

**Strategy**: `FlowTokenBridgeToEvmStrategy`
**Location**: `packages/workflow/src/send/tokenStrategies.ts:160-180`

Bridges tokens using Flow EVM Bridge protocol.

#### EVM → Flow

**Strategy**: `EvmToFlowCoaWithdrawalStrategy`
**Location**: `packages/workflow/src/send/tokenStrategies.ts:185-204`

Withdraws tokens from COA to Flow account.

```typescript
export class EvmToFlowCoaWithdrawalStrategy implements TransferStrategy {
  canHandle(payload: SendPayload): boolean {
    const { sender, receiver, assetType, proposer, type } = payload;
    return (
      type === 'token' &&
      assetType === 'evm' &&
      sender !== receiver &&
      receiver === proposer &&
      this.isFlowAddress(receiver)
    );
  }

  async execute(payload: SendPayload): Promise<any> {
    const { amount, receiver } = payload;
    const formattedAmount = safeConvertToUFix64(amount);
    return await this.cadenceService.withdrawCoa(formattedAmount, receiver);
  }
}
```

**Strategy**: `EvmToFlowTokenBridgeStrategy`
**Location**: `packages/workflow/src/send/tokenStrategies.ts:206-230`

**Transaction**: `packages/cadence/src/cadence/Bridge/transactions/bridge_tokens_from_evm_to_flow_v3.cdc`

Bridges fungible tokens from EVM to Cadence using the FlowEVMBridge.

```cadence
transaction(vaultIdentifier: String, amount: UInt256, recipient: Address) {
    let coa: auth(EVM.Bridge) &EVM.CadenceOwnedAccount

    prepare(signer: auth(BorrowValue) &Account) {
        // Borrow a reference to the signer's COA
        self.coa = signer.storage.borrow<auth(EVM.Bridge) &EVM.CadenceOwnedAccount>(from: /storage/evm)
            ?? panic("Could not borrow COA from provided gateway address")
    }
}
```

#### Child Account → COA

**Strategy**: `ChildToParentTokenStrategy`
**Location**: `packages/workflow/src/send/tokenStrategies.ts:55-77`

Transfers tokens from child account to parent's COA.

```typescript
async execute(payload: SendPayload): Promise<any> {
  const { proposer, receiver, coaAddr, flowIdentifier, sender, amount } = payload;

  // Send child tokens to parent account
  if (receiver === proposer) {
    const formattedAmount = safeConvertToUFix64(amount);
    return await this.cadenceService.transferChildFt(flowIdentifier, sender, formattedAmount);
  }

  // Bridge to COA (Cadence Owned Account)
  if (receiver === coaAddr) {
    const formattedAmount = safeConvertToUFix64(amount);
    return await this.cadenceService.bridgeChildFtToEvm(flowIdentifier, sender, formattedAmount);
  }

  // Send to other child accounts
  const formattedAmount = safeConvertToUFix64(amount);
  return await this.cadenceService.transferChildFtToChild(flowIdentifier, sender, receiver, formattedAmount);
}
```

**Cadence Transactions**:
- `packages/cadence/src/cadence/HybridCustody/transactions/bridge_child_ft_to_evm.cdc` - Bridge child FT to EVM
- `packages/cadence/src/cadence/HybridCustody/transactions/bridge_child_ft_to_evm_address.cdc` - Bridge to specific EVM address
- `packages/cadence/src/cadence/HybridCustody/transactions/bridge_child_ft_from_evm.cdc` - Bridge from EVM to child

**References**:
- `packages/workflow/src/send/tokenStrategies.ts:66-70` - COA address matching logic

### 3.2 NFT Bridging

#### Flow → EVM

**Cadence Transactions**:
- `packages/cadence/src/cadence/Bridge/transactions/bridge_nft_to_evm_with_payer.cdc` - Bridge single NFT
- `packages/cadence/src/cadence/Bridge/transactions/bridge_nft_to_evm_address_with_payer.cdc` - Bridge to specific address
- `packages/cadence/src/cadence/Bridge/transactions/batch_bridge_nft_to_evm_with_payer.cdc` - Batch bridge NFTs
- `packages/cadence/src/cadence/Bridge/transactions/batch_bridge_nft_to_evm_address_with_payer.cdc` - Batch to specific address

#### EVM → Flow

**Cadence Transactions**:
- `packages/cadence/src/cadence/Bridge/transactions/bridge_nft_from_evm_with_payer.cdc` - Bridge single NFT from EVM
- `packages/cadence/src/cadence/Bridge/transactions/bridge_nft_from_evm_to_flow_with_payer.cdc` - Bridge to Flow account
- `packages/cadence/src/cadence/Bridge/transactions/batch_bridge_nft_from_evm_with_payer.cdc` - Batch bridge from EVM
- `packages/cadence/src/cadence/Bridge/transactions/batch_bridge_nft_from_evm_to_flow_with_payer.cdc` - Batch to Flow

#### Child Account → COA

**Strategy**: `ChildToParentNFTStrategy`
**Location**: `packages/workflow/src/send/nftStrategies.ts:45-77`

Transfers NFTs from child account to parent's COA.

```typescript
async execute(payload: SendPayload): Promise<any> {
  const { proposer, receiver, coaAddr, flowIdentifier, sender, ids } = payload;

  // Send child NFT to parent account
  if (receiver === proposer) {
    return await this.cadenceService.batchTransferChildNft(flowIdentifier, sender, ids);
  }

  // Bridge to COA (Cadence Owned Account)
  if (receiver === coaAddr) {
    return await this.cadenceService.batchBridgeChildNftToEvmWithPayer(
      flowIdentifier,
      sender,
      ids
    );
  }

  // Send to other child accounts
  return await this.cadenceService.batchTransferChildNftToChild(
    flowIdentifier,
    sender,
    receiver,
    ids
  );
}
```

**Cadence Transactions**:
- `packages/cadence/src/cadence/HybridCustody/transactions/bridge_child_nft_from_evm.cdc` - Bridge child NFT from EVM
- `packages/cadence/src/cadence/HybridCustody/transactions/batch_bridge_child_nft_to_evm_with_payer.cdc` - Batch bridge to EVM
- `packages/cadence/src/cadence/HybridCustody/transactions/batch_bridge_child_nft_to_evm_address_with_payer.cdc` - Batch to specific address
- `packages/cadence/src/cadence/HybridCustody/transactions/batch_bridge_child_nft_from_evm_with_payer.cdc` - Batch from EVM

**Strategy**: `ChildToChildNFTFromEvmStrategy`
**Location**: `packages/workflow/src/send/nftStrategies.ts:83-113`

Handles EVM NFT transfers between child accounts through COA.

```typescript
canHandle(payload: SendPayload): boolean {
  const { childAddrs, receiver, assetType, sender, coaAddr, type } = payload;
  return (
    type === 'nft' &&
    childAddrs.length > 0 &&
    childAddrs.includes(receiver) &&
    assetType === 'evm' &&
    sender === coaAddr  // Sender is COA
  );
}
```

**References**:
- `packages/workflow/src/send/nftStrategies.ts:55-62` - COA address matching for NFT transfers

## 4. Balance Queries

### 4.1 Service Layer

**Location**: `packages/services/src/FlowService.ts`

```typescript
/**
 * Get the balance for any address (Flow or EVM)
 * Uses the existing CadenceService which handles both Flow and EVM addresses intelligently
 * @param address - The Flow or EVM address
 * @returns Promise<number> - Balance in FLOW tokens
 */
async getCoaBalance(address: string): Promise<number> {
  try {
    await this.ensureInitialized();

    const result = await cadenceService.getFlowBalanceForAnyAccounts([address]);
    const balance = result[address];

    if (balance !== undefined && balance !== null) {
      return parseFloat(balance.toString());
    } else {
      // If no balance found, it might be an invalid address or no COA exists
      throw new Error('No balance found for address');
    }
  } catch (_error) {
    logger.error('Error fetching balance via CadenceService', _error);
    throw new Error(
      'Failed to fetch balance via CadenceService. The address may be invalid or the COA may not exist.'
    );
  }
}

/**
 * Get the EVM balance for an EVM address
 * @param evmAddress - The EVM address (hex string with 0x prefix)
 * @returns Promise<number> - Balance in FLOW tokens
 */
async getEvmBalance(evmAddress: string): Promise<number> {
  // The CadenceService handles both Flow and EVM addresses, so we can use the same method
  return this.getCoaBalance(evmAddress);
}

/**
 * Get the EVM address for a Flow address
 * @param flowAddress - The Flow address
 * @returns Promise<string | null> - The EVM address or null if no COA exists
 */
async getEvmAddress(_flowAddress: string): Promise<string | null> {
  // TODO: Implement this using CadenceService if needed
  logger.warn('FlowService: getEvmAddress not yet implemented via CadenceService');
  return null;
}
```

**References**:
- `packages/services/src/FlowService.ts:59-88` - `getCoaBalance` and `getEvmBalance` methods
- `packages/services/src/FlowService.ts:117-122` - `getEvmAddress` (planned implementation)

### 4.2 Store Layer

**Location**: `packages/stores/src/types.ts`

```typescript
export interface SendStoreState {
  // ... other properties

  // Balance management
  balances: {
    coa: Record<string, BalanceData>; // keyed by flowAddress
    evm: Record<string, BalanceData>; // keyed by evmAddress
  };
}

export interface SendStoreActions {
  // ... other actions

  // Balance actions
  fetchCoaBalance: (flowAddress: string) => Promise<void>;
  fetchEvmBalance: (evmAddress: string) => Promise<void>;
  getCoaBalance: (flowAddress: string) => BalanceData | null;
  getEvmBalance: (evmAddress: string) => BalanceData | null;
  clearBalances: () => void;
  clearBalanceForAddress: (type: 'coa' | 'evm', address: string) => void;
}
```

**Implementation**: `packages/stores/src/sendStore.ts`

```typescript
// Balance state initialization
balances: {
  coa: {},
  evm: {},
},

// Fetch COA balance
fetchCoaBalance: async (flowAddress: string) => {
  const currentBalances = get().balances;

  // Set loading state for this address
  set({
    balances: {
      ...currentBalances,
      coa: {
        ...currentBalances.coa,
        [flowAddress]: {
          ...currentBalances.coa[flowAddress],
          loading: true,
          error: null,
        },
      },
    },
  });

  try {
    const flow = flowService();
    const balance = await flow.getCoaBalance(flowAddress);

    const updatedBalances = get().balances;
    set({
      balances: {
        ...updatedBalances,
        coa: {
          ...updatedBalances.coa,
          [flowAddress]: {
            balance,
            loading: false,
            error: null,
          },
        },
      },
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Failed to fetch COA balance';
    logger.error('Error fetching COA balance:', error);

    const updatedBalances = get().balances;
    set({
      balances: {
        ...updatedBalances,
        coa: {
          ...updatedBalances.coa,
          [flowAddress]: {
            ...updatedBalances.coa[flowAddress],
            loading: false,
            error: errorMessage,
          },
        },
      },
    });
  }
},
```

**Token Store Integration**:
- `packages/stores/src/tokenStore.ts:129-130` - EVM account COA balance query
- `packages/stores/src/tokenStore.query.ts:338-339` - TanStack Query COA balance fetching

**References**:
- `packages/stores/src/types.ts:103` - Balance data structure
- `packages/stores/src/types.ts:141-146` - Balance action definitions
- `packages/stores/src/sendStore.ts:58-60` - Balance state initialization
- `packages/stores/src/sendStore.ts:180-219` - `fetchCoaBalance` implementation

## 5. EVM Integration

### 5.1 Contract Calls

**Single Contract Call**: `packages/cadence/src/cadence/EVM/transaction/call_contract.cdc`

Calls an EVM smart contract through COA.

```cadence
transaction(
  to: String,
  data: String,
  gasLimit: UInt64,
  value: UInt
) {
  let coa: auth(EVM.Call) &EVM.CadenceOwnedAccount

  prepare(signer: auth(BorrowValue) &Account) {
    self.coa = signer.storage.borrow<auth(EVM.Call) &EVM.CadenceOwnedAccount>(from: /storage/evm)
      ?? panic("Could not borrow COA from provided gateway address")
  }

  execute {
    let result = self.coa.call(
      to: EVM.EVMAddress.fromHex(to),
      data: data.decodeHex(),
      gasLimit: gasLimit,
      value: EVM.Balance(attoflow: UInt(value))
    )
  }
}
```

**Batch Contract Calls**: `packages/cadence/src/cadence/EVM/transaction/batch_call_contract.cdc`

Executes multiple contract calls in a single transaction.

### 5.2 Flow to EVM Address Transfer

**Transaction**: `packages/cadence/src/cadence/EVM/transaction/transfer_flow_to_evm_address.cdc`

Transfers Flow tokens to an EVM address through COA.

```cadence
transaction(amount: UFix64, to: String) {
  let coa: auth(EVM.Call) &EVM.CadenceOwnedAccount
  let sentVault: @FlowToken.Vault

  prepare(signer: auth(BorrowValue, Storage) &Account) {
    self.coa = signer.storage.borrow<auth(EVM.Call) &EVM.CadenceOwnedAccount>(from: /storage/evm)
      ?? panic("Could not borrow COA")

    let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
      from: /storage/flowTokenVault
    ) ?? panic("Could not borrow reference to the owner's Vault!")

    self.sentVault <- vaultRef.withdraw(amount: amount) as! @FlowToken.Vault
  }

  execute {
    self.coa.deposit(from: <-self.sentVault)
    // Transfer to EVM address
  }
}
```

### 5.3 COA Ownership Proof

**Location**: `apps/extension/src/background/controller/provider/controller.ts`

Generates cryptographic proof of COA ownership for dApp interactions.

```typescript
interface COAOwnershipProof {
  keyIndices: bigint[];
  address: Uint8Array;
  capabilityPath: string;
  signatures: Uint8Array[];
}

function createAndEncodeCOAOwnershipProof(
  keyIndices: bigint[],
  address: Uint8Array,
  capabilityPath: string,
  signatures: Uint8Array[]
): Uint8Array {
  const proof: COAOwnershipProof = {
    keyIndices,
    address,
    capabilityPath,
    signatures,
  };

  // RLP encode the proof
  const encoded = encode([
    proof.keyIndices,
    proof.address,
    utf8ToBytes(proof.capabilityPath),
    proof.signatures,
  ]);

  return encoded;
}
```

**References**:
- `apps/extension/src/background/controller/provider/controller.ts:37-40` - Interface definition
- `apps/extension/src/background/controller/provider/controller.ts:53-77` - Encoding implementation

## 6. Send Workflow

### 6.1 Payload Definition

**Location**: `packages/workflow/src/send/types.ts`

```typescript
export interface SendPayload {
  type: 'token' | 'nft';
  assetType: 'flow' | 'evm';
  sender: string; // Sending address
  receiver: string; // Receiving address
  proposer: string; // Transaction proposer (parent account)
  childAddrs: string[]; // Child account addresses
  ids: number[]; // NFT token IDs (for NFT transfers)
  amount: string; // Token amount to transfer
  decimal: number; // Token decimal places
  coaAddr: string; // User's COA (Cadence Owned Account) address
  tokenContractAddr: string; // Token contract address (Flow or EVM format)
}
```

**Key Field**: `coaAddr`
- Required field in all send operations
- Used to identify user's COA for bridging operations
- Enables strategy matching for COA-related transfers

**References**:
- `packages/workflow/src/send/types.ts:15` - `coaAddr` field definition

### 6.2 Strategy Pattern Integration

**Location**: `packages/workflow/src/send/context.ts`

```typescript
export function createSendContext(cadenceService: CadenceService): SendContext {
  const context = new SendContext();

  // Register token transfer strategies
  context.addStrategy(new ChildToParentTokenStrategy(cadenceService));
  context.addStrategy(new ChildToChildTokenStrategy(cadenceService));
  context.addStrategy(new ChildToOthersTokenStrategy(cadenceService));
  context.addStrategy(new EvmToEvmTokenStrategy(cadenceService));
  context.addStrategy(new EvmToFlowCoaWithdrawalStrategy(cadenceService)); // COA withdrawal
  context.addStrategy(new EvmToFlowTokenBridgeStrategy(cadenceService));
  context.addStrategy(new FlowToEvmTokenStrategy(cadenceService));
  context.addStrategy(new FlowToFlowTokenStrategy(cadenceService));
  context.addStrategy(new FlowTokenBridgeToEvmStrategy(cadenceService));

  // Register NFT transfer strategies
  context.addStrategy(new ChildToParentNFTStrategy(cadenceService));
  context.addStrategy(new ChildToChildNFTStrategy(cadenceService));
  context.addStrategy(new ChildToChildNFTFromEvmStrategy(cadenceService)); // EVM NFT via COA
  context.addStrategy(new ChildToOthersNFTStrategy(cadenceService));
  context.addStrategy(new EvmToEvmNFTStrategy(cadenceService));
  context.addStrategy(new FlowToEvmNFTStrategy(cadenceService));
  context.addStrategy(new FlowToFlowNFTStrategy(cadenceService));

  return context;
}
```

**COA-Related Strategies**:
1. `EvmToFlowCoaWithdrawalStrategy` - Withdraws from COA to Flow
2. `ChildToParentTokenStrategy` - Bridges child tokens to parent's COA
3. `ChildToParentNFTStrategy` - Bridges child NFTs to parent's COA
4. `ChildToChildNFTFromEvmStrategy` - Transfers EVM NFTs between children via COA

**References**:
- `packages/workflow/src/send/context.ts:72` - COA withdrawal strategy registration
- All bridging strategies use `coaAddr` for address matching

## 7. Testing Scenarios

### 7.1 Unit Tests

**Wallet Package Tests**: `packages/wallet/src/__tests__/accounts.test.ts`

```typescript
describe('Account Classes', () => {
  describe('COA (Chain-Owned Account)', () => {
    it('should create COA with EVM address', () => {
      const address = '0x1234567890abcdef1234567890abcdef12345678';
      const network: FlowChainID = 'flow-mainnet';

      const coa = new COA(address, network);

      expect(coa.address).toBe(address);
      expect(coa.chainID).toBe(network);
      expect(coa.vm).toBe('EVM');
    });

    it('should create COA with testnet', () => {
      const address = '0xabcdef1234567890abcdef1234567890abcdef12';
      const network: FlowChainID = 'flow-testnet';

      const coa = new COA(address, network);

      expect(coa.address).toBe(address);
      expect(coa.chainID).toBe(network);
    });
  });
});
```

**Workflow Tests**:
- `packages/workflow/tests/send.ft.test.ts` - FT sending tests (including COA scenarios)
- `packages/workflow/tests/send.nft.test.ts` - NFT sending tests (including COA scenarios)
- `packages/workflow/tests/send.ft.script.test.ts` - FT script-based tests
- `packages/workflow/tests/send.nft.script.test.ts` - NFT script-based tests
- `packages/workflow/tests/query.test.ts` - Query tests with COA balance queries

**References**:
- `packages/wallet/src/__tests__/accounts.test.ts:7-33` - COA unit tests

### 7.2 E2E Tests

**Extension E2E Tests**:
- `apps/extension/e2e/transaction/ft-transaction.test.ts` - FT transaction flows
- `apps/extension/e2e/transaction/nft-transaction.test.ts` - NFT transaction flows
- `apps/extension/e2e/transaction/cadence-transaction.test.ts` - Cadence transaction tests

**Test Utilities**: `apps/extension/e2e/utils/helper.ts`

Contains helper functions for E2E tests involving COA operations.

### 7.3 Test Annotations

**Location**: `apps/extension/src/background/controller/__tests__/controller.test.ts:293`

```typescript
// Below gets an EOA address, not the Flow or COA address. So don't do this
// const recoveredAddress = bufferToHex(pubToAddress(recoveredPubKey)).toLowerCase();
// const expectedSignerAddress = mockEvmAddress.toLowerCase();
```

**Important Note**: This annotation highlights the critical distinction between:
- **EOA Address**: Derived from EVM private key
- **COA Address**: Owned by Flow Cadence account
- **Flow Address**: Cadence blockchain address

**References**:
- Test data: `apps/extension/src/core/service/__tests__/test-data/test-groups.ts`
- API test results: `apps/extension/src/core/service/__tests__/test-data/api-test-results.ts`

## 8. iOS Native Integration

### 8.1 Service Layer

**Wallet Manager**: `.git/modules/apps/react-native/ios/FRW/Services/Manager/Wallet/`
- `WalletManager.swift` - Core wallet management with COA support
- `WalletManager+Getter.swift` - COA getter methods
- `WalletManger+Account.swift` - COA account management

**EVM Account Manager**: `.git/modules/apps/react-native/ios/FRW/Services/Manager/EVMAccountManager.swift`
- COA creation and management for iOS
- EVM account integration with Flow accounts

**WalletConnect Handler**: `.git/modules/apps/react-native/ios/FRW/Services/Manager/WalletConnect/WalletConnectEVMHandler.swift`
- Handles EVM dApp connections via COA
- Signs transactions using COA

**Flow Network**: `.git/modules/apps/react-native/ios/FRW/Services/Network/FlowNetwork.swift`
- Network layer for COA operations
- Cadence transaction execution for COA

### 8.2 Model Layer

**Flow Account Model**: `.git/modules/apps/react-native/ios/FRW/Foundation/Model/FWAccount.swift`
- COA as part of Flow account structure
- Account type discrimination (Flow vs COA vs Child)

**Cadence Model**: `.git/modules/apps/react-native/ios/FRW/Services/FlowCoin/Model/CadenceModel.swift`
- Cadence transaction models for COA operations

### 8.3 UI Layer

**Side Menu**: `.git/modules/apps/react-native/ios/FRW/Modules/Wallet/SideMenu/`
- `SideMenuView.swift` - COA account display
- `SideMenuViewModel.swift` - COA account state management

**Send Flow**: `.git/modules/apps/react-native/ios/FRW/Modules/Wallet/Send/WalletSendAmountViewModel.swift`
- COA balance checks
- COA withdrawal flows

**Move Asset Flow**: `.git/modules/apps/react-native/ios/FRW/Modules/Wallet/MoveAsset/ViewModel/`
- `MoveTokenViewModel.swift` - Token bridging to/from COA
- `MoveSingleNFTViewModel.swift` - Single NFT bridging via COA
- `MoveNFTsViewModel.swift` - Batch NFT bridging via COA

**NFT Transfer**: `.git/modules/apps/react-native/ios/FRW/Modules/NFT/NFTTransferView.swift`
- NFT transfers involving COA

**EVM Enable Flow**: `.git/modules/apps/react-native/ios/FRW/Modules/EVM/ViewModel/EVMEnableViewModel.swift`
- COA creation flow
- EVM feature enablement via COA

### 8.4 Bridge Layer

**Native Bridge**: `.git/modules/apps/react-native/ios/FRW/Foundation/Bridge/`
- `RCTNativeFRWBridge.mm` - React Native bridge for COA operations
- `TurboModuleSwift.swift` - Turbo module with COA methods
- `SendToConfig+Helper.swift` - COA address handling in send flows
- `NativeToRNModel.swift` - COA data serialization for React Native

### 8.5 Configuration

**Scripts**: `.git/modules/apps/react-native/ios/FRW/Resource/Json/scripts.json`
- Cadence scripts for COA queries

**Service Config**: `.git/modules/apps/react-native/ios/FRW/App/Env/ServiceConfig.swift`
- COA service endpoints configuration

### 8.6 Tracking

**Event Tracking**: `.git/modules/apps/react-native/ios/FRW/Services/Track/`
- `EventTrack+Transaction.swift` - COA transaction tracking
- `EventTrack+General.swift` - COA creation/linking events
- `EventTrackName.swift` - COA-related event names

**References**:
- iOS Podfile: `.git/modules/apps/react-native/ios/Podfile.lock`
- Xcode project: `.git/modules/apps/react-native/ios/FRW.xcodeproj/project.pbxproj`

## 9. Future Planning

### 9.1 EOA Support Epic

**Document**: `docs/epics/eoa-support.md`

**Overview**: Transition from COA-only model to hybrid EOA/COA support.

**Key Changes**:
1. **Account Model Evolution**
   - Current: Mnemonic → Flow Account → COA (EVM access)
   - Future: Mnemonic → EOA (native EVM) + Flow Account + COA

2. **Architecture Challenges**
   - COA vs EOA have fundamentally different signing patterns
   - COA: Cadence account signs for EVM operations
   - EOA: Direct EVM private key signing

3. **Migration Path**
   - Maintain backward compatibility for existing COA users
   - Enable optional EOA creation from same mnemonic
   - Support both account types simultaneously

**Timeline**: 13-18 weeks total
- Milestone 1: Core EOA implementation (6-8 weeks)
- Milestone 2: Security & sync (4-6 weeks)
- Milestone 3: Migration & compatibility (3-4 weeks)

**References**:
- `docs/epics/eoa-support.md:6` - COA to hybrid model transition
- `docs/epics/eoa-support.md:23-24` - COA vs EOA signing differences

### 9.2 Wallet Package Roadmap

**Document**: `packages/wallet/README.md`

**Planned Features**:
1. **COA Support**
   - Full COA (Cadence Owned Account) integration
   - Child account management with COA linking
   - Flow transaction signing for COA operations

2. **EVM Features**
   - Multi-network support (mainnet, testnet, custom)
   - Token balance queries for COA
   - EIP-712 typed data signing

3. **Advanced Security**
   - Hardware wallet support for COA
   - Secure element integration
   - Biometric authentication for COA operations

**References**:
- `packages/wallet/README.md:72` - Planned COA features

### 9.3 Key Architectural Changes

**Current Architecture**:
```
Mnemonic/Secure Enclave
    ↓
Flow Account (Cadence)
    ↓
COA (owned by Flow Account)
    ↓
EVM Access
```

**Future Architecture**:
```
Mnemonic
    ├─→ EOA (m/44'/60'/0'/0/x) - Native EVM
    └─→ Flow Account (m/44'/539'/0'/0/x)
          ↓
          COA (for Flow-EVM bridge)
```

**Benefits**:
- Native EVM dApp compatibility (EOA)
- Flow blockchain features (Flow Account)
- Seamless Flow-EVM bridging (COA)
- Single mnemonic for all account types

## Summary

COA (Cadence Owned Account) is deeply integrated throughout the FRW project across **9 major categories**:

1. **Account Architecture** - Core account type system and linked account management
2. **Cadence Transactions** - Creation, withdrawal, and linking operations
3. **Bridge Scenarios** - FT and NFT bridging between Flow and EVM
4. **Balance Queries** - Multi-layer balance fetching and caching
5. **EVM Integration** - Smart contract calls and ownership proofs
6. **Send Workflow** - Strategy pattern with COA address matching
7. **Testing** - Comprehensive unit and E2E test coverage
8. **iOS Native Integration** - Full native platform support
9. **Future Planning** - Evolution toward hybrid EOA/COA model

**Key Design Patterns**:
- Strategy Pattern for transfer operations
- Provider Pattern for service injection
- MVVM for state management
- Type-safe interfaces across all layers

**Critical Files**:
- `packages/wallet/src/account.ts` - Account architecture
- `packages/workflow/src/send/*` - Transfer strategies
- `packages/cadence/src/cadence/EVM/transaction/*` - COA transactions
- `packages/stores/src/sendStore.ts` - Balance management
- `docs/epics/eoa-support.md` - Future roadmap
