import SwiftUI

struct MockAccountInfo: AccountInfoProtocol {
    var infoName: String
    var infoAddress: String
    var tokenCount: String
    var nftCount: String
    var isMain: Bool
    var isCoa: Bool
    var walletMetadata: WalletAccount.User

    init(
        infoName: String = "测试账户",
        infoAddress: String = "0x1234567890abcdef",
        tokenCount: String = "10 Flow",
        nftCount: String = "5 NFT's",
        isMain: Bool = true,
        isCoa: Bool = false
    ) {
        self.infoName = infoName
        self.infoAddress = infoAddress
        self.tokenCount = tokenCount
        self.nftCount = nftCount
        self.isMain = isMain
        self.isCoa = isCoa
        walletMetadata = .init(emoji: .panda, address: "0x123123123")
    }

    func avatar(isSelected: Bool, subAvatar: AvatarSource?) -> AvatarView {
        AvatarView(mainAvatar: .system("person.crop.circle.fill"), subAvatar: subAvatar, backgroundColor: Color.Summer.cards, isSelected: isSelected)
    }
}

extension MockAccountInfo {
    static let linkAccount = MockAccountInfo(infoName: "你好", infoAddress: "0x1asdfer", tokenCount: "15 Flow", nftCount: "23 NFT's", isMain: false, isCoa: false)
    static let evmAccount = MockAccountInfo(infoName: "你好", infoAddress: "0x1asdfer", tokenCount: "15 Flow", nftCount: "23 NFT's", isMain: false, isCoa: true)
}
