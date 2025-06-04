//
//  ProfileAvatar.swift
//  FRW
//
//  Created by cat on 6/4/25.
//

import Kingfisher
import SwiftUI

struct ProfileInfoView: View {
    var userInfo: UserInfo

    var body: some View {
        HStack(spacing: 16) {
            ProfileAvatar(avatar: userInfo.avatar)
            Text("\(userInfo.nickname)")
                .font(.inter(size: 14, weight: .bold))
                .foregroundColor(Color.Summer.Text.primary)
        }
    }
}

struct ProfileAvatar: View {
    var avatar: String?
    var size: CGFloat = 40
    var cornerRadius: CGFloat = 8

    var body: some View {
        KFImage.url(URL(string: avatar?.convertedAvatarString() ?? AppPlaceholder.image))
            .placeholder {
                Image("placeholder")
                    .resizable()
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .cornerRadius(cornerRadius)
    }
}

// MARK: -

extension UserInfo {
    static let empty = UserInfo(avatar: AppPlaceholder.image, nickname: "lilico".localized, username: "lilico".localized, private: nil, address: nil)
}

#Preview {
    ProfileAvatar()
}
