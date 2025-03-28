//
//  BrowserSignTypedMessageView.swift
//  FRW
//
//  Created by cat on 2024/10/8.
//

import Kingfisher
import SwiftUI

// MARK: - BrowserSignTypedMessageView

struct BrowserSignTypedMessageView: View {
    // MARK: Lifecycle

    init(viewModel: BrowserSignTypedMessageViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    @StateObject
    var viewModel: BrowserSignTypedMessageViewModel

    var body: some View {
        VStack {
            titleView
            VStack {
                ScrollView(showsIndicators: false) {
                    VStack {
                        ForEach(0 ..< viewModel.list.count, id: \.self) { index in
                            if index > 0 {
                                Divider()
                                    .foregroundStyle(Color.Theme.Line.line)
                                    .padding(.vertical, 16)
                            }
                            BrowserSignTypedMessageView.Card(model: viewModel.list[index])
                        }
                    }
                    .padding(16)
                    .background(Color.Theme.Background.bg3)
                    .cornerRadius(16)
                }
            }

            Spacer()
            actionView
        }
        .padding(18)
        .backgroundFill(Color.Theme.BG.bg1)
    }

    var titleView: some View {
        HStack(alignment: .top, spacing: 18) {
            HStack {
                KFImage.url(URL(string: viewModel.logo ?? ""))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Text("browser_sign_message_request_from".localized)
                        .font(.inter(size: 14))
                        .foregroundColor(.Theme.Text.text4)

                    Text(viewModel.title)
                        .font(.inter(size: 16, weight: .bold))
                        .foregroundColor(.Theme.Text.text1)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 10)

            Button {
                viewModel.onCloseAction()
            } label: {
                Image("close_circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.leading, 10)
                    .padding(.bottom, 10)
            }
        }
    }

    var actionView: some View {
        WalletSendButtonView(allowEnable: .constant(true), buttonText: "hold_to_sign".localized) {
            viewModel.didChooseAction(true)
        }
    }
}

// MARK: BrowserSignTypedMessageView.Card

extension BrowserSignTypedMessageView {
    struct Card: View {
        var model: JSONValue

        var body: some View {
            VStack {
                titleView
                contentView()
            }
        }

        var titleView: some View {
            HStack {
                Text(model.title.uppercasedFirstLetter())
                    .font(.inter(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.Theme.Text.black8)
                Spacer()
                Text(model.content)
                    .font(.inter(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.Theme.Text.black)
            }
        }

        func contentView() -> some View {
            VStack {
                if let subValue = model.subValue {
                    if case let .object(dictionary) = subValue {
                        let keys = Array(dictionary.keys)
                        ForEach(0 ..< keys.count, id: \.self) { index in
                            let key = keys[index]
                            let value = dictionary[key]?.toString() ?? ""
                            HStack(spacing: 12) {
                                Text(key.uppercasedFirstLetter())
                                    .font(.inter(size: 14, weight: .semibold))
                                    .lineLimit(1)
                                    .foregroundStyle(Color.Theme.Text.black3)
                                Spacer()
                                Text(value)
                                    .font(.inter(size: 14, weight: .semibold))
                                    .truncationMode(.middle)
                                    .lineLimit(1)
                                    .foregroundStyle(Color.Theme.Text.black)
                            }
                            .frame(height: 20)
                        }
                    }
                    if case let .array(array) = subValue {
                        VStack {
                            ForEach(0 ..< array.count, id: \.self) { index in
                                let value = array[index]
                                innerCard(item: value)
                            }
                        }
                    }
                }
            }
        }

        func innerCard(item: JSONValue) -> some View {
            VStack {
                if case let .object(dictionary) = item {
                    let keys = Array(dictionary.keys)
                    ForEach(0 ..< keys.count, id: \.self) { index in
                        let key = keys[index]
                        let value = dictionary[key]?.toString() ?? ""
                        HStack(spacing: 12) {
                            Text(key.uppercasedFirstLetter())
                                .font(.inter(size: 14, weight: .semibold))
                                .lineLimit(1)
                                .foregroundStyle(Color.Theme.Text.black3)
                            Spacer()
                            Text(value)
                                .font(.inter(size: 14, weight: .semibold))
                                .truncationMode(.middle)
                                .lineLimit(1)
                                .foregroundStyle(Color.Theme.Text.black)
                                .frame(minWidth: 0, maxWidth: 120, alignment: .trailing)
                        }
                        .frame(height: 20)
                    }
                }
            }
            .padding(16)
            .background(.Theme.Background.fill1)
            .cornerRadius(8)
        }
    }
}

#Preview {
    BrowserSignTypedMessageView(viewModel: BrowserSignTypedMessageViewModel(
        title: "ABC",
        urlString: "http://",
        rawString: "{\"domain\":{\"name\":\"Ether Mail\",\"version\":\"1\",\"chainId\":747,\"verifyingContract\":\"0xcccccccccccccccccccccccccccccccccccccccc\"},\"message\":{\"from\":{\"name\":\"Cow\",\"wallet\":\"0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826\"},\"to\":{\"name\":\"Bob\",\"wallet\":\"0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\"},\"contents\":\"Hello, Bob!\"},\"primaryType\":\"Mail\",\"types\":{\"EIP712Domain\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"version\",\"type\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\"}],\"Person\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"wallet\",\"type\":\"address\"}],\"Mail\":[{\"name\":\"from\",\"type\":\"Person\"},{\"name\":\"to\",\"type\":\"Person\"},{\"name\":\"contents\",\"type\":\"string\"}]}}"
    ))
}
