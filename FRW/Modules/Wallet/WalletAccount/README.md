# WalletUser API

WalletUser 提供简单的静态 API 来管理钱包账户的显示信息（emoji 和 name）。

## 使用方式

### 获取或创建用户

```swift
// 获取账户的显示信息（如果不存在会自动创建并分配 emoji）
let user = WalletUser.get(address: "0x123456")
print(user.emoji)  // 🐼
print(user.name)   // "Panda"
```

### 更新用户信息

```swift
// 更新账户信息
WalletUser.update(address: "0x123456", emoji: .lion, name: "My Wallet")

// 使用 emoji 的默认名称
WalletUser.update(address: "0x123456", emoji: .panda)
```

### 多用户支持

```swift
// 为特定用户获取账户信息
let user = WalletUser.get(address: "0x123456", userId: "user1")

// 为特定用户更新
WalletUser.update(address: "0x123456", emoji: .lion, userId: "user1")
```

## API 参考

### WalletUser 结构

```swift
struct WalletUser {
    var emoji: WalletEmoji       // 账户图标
    var name: String              // 账户名称
    var address: String           // 钱包地址
    var network: Flow.ChainID     // 网络 ID
}
```

### 静态方法

```swift
// 获取或创建用户
static func get(address: String, userId: String? = nil) -> WalletUser

// 更新用户信息
static func update(address: String, emoji: WalletEmoji, name: String? = nil, userId: String? = nil)
```

## 特性

✅ **自动 Emoji 分配** - 新账户会自动分配未使用的 emoji
✅ **网络隔离** - 同一地址在不同网络被视为不同账户
✅ **多用户支持** - 每个用户有独立的账户列表
✅ **简单 API** - 只需要知道 `WalletUser` 类型

## 内部实现

- `WalletUserRepository` - 存储层（内部实现，不对外暴露）
- `WalletAccount` - 向后兼容层（已标记为 deprecated）

## 迁移指南

### 旧代码（继续工作）

```swift
var account = WalletAccount()
let user = account.readInfo(at: "0x123")
account.update(at: "0x123", emoji: .panda)
```

### 新代码（推荐）

```swift
let user = WalletUser.get(address: "0x123")
WalletUser.update(address: "0x123", emoji: .panda)
```

更简洁、更直观！
