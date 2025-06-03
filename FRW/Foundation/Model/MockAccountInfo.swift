import SwiftUI

struct MockAccountInfo: AccountInfoProtocol {
    var infoName: String
    var infoAddress: String
    var accountType: FWAccount.AccountType
    var walletMetadata: WalletAccount.User

    func avatar(isSelected: Bool, subAvatar: AvatarSource?) -> AvatarView {
        AvatarView(mainAvatar: .system("person.crop.circle.fill"), subAvatar: subAvatar, backgroundColor: Color.Summer.cards, isSelected: isSelected)
    }
}

extension MockAccountInfo {
    static func mockSamples() -> [MockAccountInfo] {
        [
            MockAccountInfo(
                infoName: "mainAccount",
                infoAddress: "0x1234567890abcdef",
                accountType: .main,
                walletMetadata: WalletAccount.User(emoji: .koala, address: "0x1234567890abcdef")
            ),
            MockAccountInfo(
                infoName: "Child",
                infoAddress: "0xabcdef1234567890",
                accountType: .child,
                walletMetadata: WalletAccount.User(emoji: .lion, address: "0xabcdef1234567890")
            ),
            MockAccountInfo(
                infoName: "EVM",
                infoAddress: "0x8e5b4a8e5b4a8e5b4a8e5b4a8e5b4a8e5b4a8e5b",
                accountType: .coa,
                walletMetadata: WalletAccount.User(emoji: .avocado, address: "0x8e5b4a8e5b4a8e5b4a8e5b4a8e5b4a8e5b4a8e5b")
            ),
        ]
    }
}

extension AccountModel {
    /// 生成一组典型的 AccountModel mock 测试数据
    static func mockSamples() -> [AccountModel] {
        let accounts = MockAccountInfo.mockSamples()
        return [
            AccountModel(account: accounts[0], mainAccount: nil, flowCount: "123.45", nftCount: 7),
            AccountModel(account: accounts[1], mainAccount: accounts[0], flowCount: "0.00", nftCount: 0),
            AccountModel(account: accounts[2], mainAccount: accounts[0], flowCount: "999.99", nftCount: 99),
        ]
    }
}
