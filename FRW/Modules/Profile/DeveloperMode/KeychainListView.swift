//
//  KeychainListView.swift
//  FRW
//
//  Created by cat on 2024/4/26.
//

import SwiftUI

struct KeychainListView: RouteableView {
    // MARK: Internal

    var title: String {
        "All Keys on Local"
    }

    var body: some View {
        ScrollView {
            Section {
                ForEach(0 ..< viewModel.seList.count, id: \.self) { index in
                    let item = viewModel.seList[index]
                    KeychainListView.Item(info: item, isCurrent: isCurrentKey(info: item)) { _ in

                    } onDelete: { _ in
                    }
                }
            } header: {
                HStack {
                    Text("Secret Key (\(viewModel.seList.count))")
                    Spacer()
                }
                .frame(height: 52)
            }
            .visibility(!viewModel.seList.isEmpty ? .visible : .gone)

            Section {
                ForEach(0 ..< viewModel.seItem.count, id: \.self) { index in
                    let item = viewModel.seItem[index]
                    KeychainListView.Item(info: item, isCurrent: isCurrentKey(info: item)) { _ in
                    } onDelete: { _ in }
                }
            } header: {
                HStack {
                    Text("New Secret Key (\(viewModel.seItem.count))")
                    Spacer()
                }
                .frame(height: 52)
            }
            .visibility(!viewModel.seItem.isEmpty ? .visible : .gone)

            Section {
                ForEach(0 ..< viewModel.spItem.count, id: \.self) { index in
                    let item = viewModel.spItem[index]
                    KeychainListView.Item(info: item, isCurrent: isCurrentKey(info: item), onClick: { _ in

                    }) { _ in
                    }
                }
            } header: {
                HStack {
                    Text("Seed Phrase (\(viewModel.spItem.count))")
                    Spacer()
                }
                .frame(height: 52)
            }
            .visibility(!viewModel.spItem.isEmpty ? .visible : .gone)

            Section {
                ForEach(0 ..< viewModel.pkItem.count, id: \.self) { index in
                    let item = viewModel.pkItem[index]
                    KeychainListView.Item(info: item, isCurrent: isCurrentKey(info: item)) { _ in
                    } onDelete: { _ in
                    }
                }
            } header: {
                HStack {
                    Text("Private Key (\(viewModel.pkItem.count))")
                    Spacer()
                }
                .frame(height: 52)
            }
            .visibility(!viewModel.pkItem.isEmpty ? .visible : .gone)

            Section {
                ForEach(0 ..< viewModel.localList.count, id: \.self) { index in
                    let item = viewModel.localList[index]
                    itemView(item)
                }
            } header: {
                HStack {
                    Text("Local(\(viewModel.localList.count))")
                    Spacer()
                }
                .frame(height: 52)
            }
            .visibility(!viewModel.localList.isEmpty ? .visible : .gone)

            Section {
                ForEach(0 ..< viewModel.remoteList.count, id: \.self) { index in
                    let item = viewModel.remoteList[index]
                    itemView(item)
                }
            } header: {
                HStack {
                    Text("Remote(\(viewModel.remoteList.count))")
                    Spacer()
                }
                .frame(height: 52)
            }
            .visibility(!viewModel.remoteList.isEmpty ? .visible : .gone)

            Section {
                ForEach(0 ..< $viewModel.multiICloudBackUpList.count, id: \.self) { index in
                    let item = viewModel.multiICloudBackUpList[index]
                    KeychainListView.Item(info: item, isCurrent: isCurrentKey(info: item)) { _ in
                    } onDelete: { _ in }
                }
            } header: {
                HStack {
                    Text("iCloud Multiple Backup(\($viewModel.multiICloudBackUpList.count))")
                    Spacer()
                }
                .frame(height: 52)
            }
            .visibility(!$viewModel.remoteList.isEmpty ? .visible : .gone)
        }
        .safeAreaInset(edge: .bottom, content: {
//            Button {
//                viewModel.clearAllKey()
//            } label: {
//                Text("Clear All")
//            }
        })
        .padding(.horizontal, 16)
        .applyRouteable(self)
        .tracedView(self)
    }

    func itemView(_ item: [String: Any]) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.getKey(item: item))
                    .font(.inter(size: 16))
                    .foregroundStyle(Color.Theme.Accent.red)
                    .lineLimit(2)
                Text(viewModel.mnemonicValue(item: item))
                    .font(.inter(size: 16))
                    .foregroundStyle(Color.Theme.Text.black8)
                    .lineLimit(3)
            }
            Spacer()
            Button {
                UIPasteboard.general.string =
                    viewModel.getKey(item: item) + "\n" +
                    viewModel.mnemonicValue(item: item)
            } label: {
                Image(systemName: "doc.on.doc.fill")
                    .frame(width: 24, height: 24)
            }
        }
        .frame(height: 80)
        .background(Color.Theme.Background.silver)
    }

    func isCurrentKey(info: [String: String]) -> Bool {
        let key = info["userId"]
        return UserManager.shared.activatedUID == key
    }

    // MARK: Private

    @ObservedObject
    private var viewModel = KeychainListViewModel()
}

extension KeychainListView {
    struct Item: View {
        var info: [String: String]
        var isCurrent: Bool
        var onClick: ([String: String]) -> Void
        var onDelete: (String) -> Void
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(info["userId"] ?? "")
                        .font(.inter(size: 16))
                        .foregroundStyle(isCurrent ? Color.Theme.Accent.orange : Color.Theme.Text.black8)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.Theme.Background.grey)

                VStack {
                    ForEach(sorting: info, id: \.self) { key, value in
                        if key != "userId" {
                            HStack {
                                Text(key.uppercasedFirstLetter())
                                    .font(.inter(size: 14))
                                    .foregroundStyle(Color.Theme.Text.black8)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Text(value)
                                    .font(.inter(size: 14, weight: .bold))
                                    .foregroundStyle(Color.Theme.Text.black3)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(16)
                .background(Color.Theme.Background.grey.opacity(0.6))

                HStack(spacing: 12) {
//                    Button {
//                        onDelete(info["userId"] ?? "")
//                    } label: {
//                        Text("Delete")
//                            .font(.inter(size: 12))
//                            .padding(4)
//                    }

                    Button {
                        UIPasteboard.general.string = info.toJSONString()
                        HUD.success(title: "Copy Success")
                    } label: {
                        Text("Copy")
                            .font(.inter(size: 12))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .background(Color.Theme.Background.grey.opacity(0.6))
                .frame(maxWidth: .infinity)
            }
            .cornerRadius(16)
            .onTapGesture {
                onClick(info)
            }
        }
    }
}

#Preview {
    KeychainListView.Item(info: ["userId": "ac12312312", "public Key": "123123", "index": "2"], isCurrent: false) { _ in
    } onDelete: { _ in
    }
}
