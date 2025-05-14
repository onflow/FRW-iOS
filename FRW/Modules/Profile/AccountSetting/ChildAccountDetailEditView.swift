//
//  ChildAccountDetailEditView.swift
//  Flow Wallet
//
//  Created by Selina on 13/7/2023.
//

import Combine
import Kingfisher
import SwiftUI
import SwiftUIX
import UIKit

// MARK: - ChildAccountDetailEditViewModel.NewAccountInfo

extension ChildAccountDetailEditViewModel {
    class NewAccountInfo {
        var imageURL: String?
        var name: String = ""
        var desc: String = ""

        var newImage: UIImage? {
            didSet {
                imageURL = nil
            }
        }
    }
}

// MARK: - ChildAccountDetailEditViewModel

class ChildAccountDetailEditViewModel: ObservableObject {
    // MARK: Lifecycle

    init(childAccount: ChildAccount) {
        self.childAccount = childAccount
        newInfo = NewAccountInfo()
        newInfo.name = childAccount.name ?? ""
        newInfo.desc = childAccount.description ?? ""
        newInfo.imageURL = childAccount.icon
    }

    // MARK: Internal

    @Published
    var childAccount: ChildAccount
    @Published
    var imagePickerShowFlag = false
    @Published
    var newInfo: NewAccountInfo

    @objc
    func saveAction() {
        if newInfo.name.trim.count > 100 {
            HUD.error(title: "name must be less than 100 characters")
            return
        }

        if newInfo.desc.trim.count > 1000 {
            HUD.error(title: "description must be less than 1000 characters")
            return
        }

        HUD.loading()

        Task {
            do {
                if let image = newInfo.newImage, newInfo.imageURL == nil {
                    let newURL = await FirebaseStorageUtils.upload(
                        avatar: image,
                        removeQuery: false
                    )
                    if newURL == nil {
                        HUD.dismissLoading()
                        HUD.error(title: "upload avatar failed")
                        return
                    }

                    newInfo.imageURL = newURL
                }

                let txId = try await FlowNetwork.editChildAccountMeta(
                    childAccount.addr ?? "",
                    name: newInfo.name.trim,
                    desc: newInfo.desc.trim,
                    thumbnail: newInfo.imageURL?.trim ?? ""
                )
                let holder = TransactionManager.TransactionHolder(id: txId, type: .editChildAccount)

                DispatchQueue.main.async {
                    HUD.dismissLoading()
                    TransactionManager.shared.newTransaction(holder: holder)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        Router.route(to: RouteMap.Profile.backToAccountSetting)
                    }
                }
            } catch {
                log.error("edit failed", context: error)
                HUD.dismissLoading()
                HUD.error(title: "request_failed".localized)
            }
        }
    }

    func pickAvatarAction() {
        imagePickerShowFlag = true
    }
}

// MARK: - ChildAccountDetailEditView

struct ChildAccountDetailEditView: RouteableView {
    // MARK: Lifecycle

    init(vm: ChildAccountDetailEditViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    // MARK: Internal

    @StateObject
    var vm: ChildAccountDetailEditViewModel

    var title: String {
        "edit".localized
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack {
                avatarEditCell
                divider
                nameEditCell
                divider
                descEditCell
            }
            .background(Color.LL.bgForIcon)
            .cornerRadius(16)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundFill(Color.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
        .sheet(isPresented: $vm.imagePickerShowFlag) {
            ImagePicker(image: $vm.newInfo.newImage)
        }
    }

    var avatarEditCell: some View {
        Button {
            vm.pickAvatarAction()
        } label: {
            HStack(spacing: 0) {
                Text("avatar".localized)
                    .font(.inter(size: 16, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text)

                Spacer()

                if let image = vm.newInfo.newImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .cornerRadius(25)
                        .padding(.trailing, 15)
                } else {
                    KFImage.url(URL(string: vm.newInfo.imageURL ?? ""))
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .cornerRadius(25)
                        .padding(.trailing, 15)
                }

                Image("icon-black-right-arrow")
                    .renderingMode(.template)
                    .foregroundColor(Color.LL.Neutrals.text2)
            }
            .padding(.all, 16)
        }
    }

    var nameEditCell: some View {
        HStack(spacing: 16) {
            Text("name".localized)
                .font(.inter(size: 16, weight: .medium))
                .foregroundColor(Color.LL.Neutrals.text)

            TextEditor(text: $vm.newInfo.name)
                .font(.inter(size: 16))
                .foregroundColor(Color.LL.Neutrals.note)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 30)
                .scrollContentBackground(.hidden)
        }
        .padding(.all, 16)
    }

    var descEditCell: some View {
        HStack(spacing: 16) {
            Text("description".localized)
                .font(.inter(size: 16, weight: .medium))
                .foregroundColor(Color.LL.Neutrals.text)

            TextEditor(text: $vm.newInfo.desc)
                .font(.inter(size: 16))
                .foregroundColor(Color.LL.Neutrals.note)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 30)
                .scrollContentBackground(.hidden)
        }
        .padding(.all, 16)
    }

    var divider: some View {
        Divider()
            .foregroundColor(.LL.Neutrals.background)
            .padding(.horizontal, 16)
    }

    func configNavigationItem(_ navigationItem: UINavigationItem) {
        let saveBtn = UIButton(type: .custom)
        let bgImage = UIImage.image(withColor: UIColor(named: "button.color")!)
        let textColor = UIColor(named: "button.text")
        saveBtn.setBackgroundImage(bgImage, for: .normal)
        saveBtn.setTitleColor(textColor, for: .normal)
        saveBtn.setTitle("save".localized)
        saveBtn.titleLabel?.font = .interSemiBold(size: 14)
        saveBtn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        saveBtn.sizeToFit()
        saveBtn.clipsToBounds = true
        saveBtn.layer.cornerRadius = saveBtn.bounds.height / 2
        saveBtn.addTarget(vm, action: Selector("saveAction"), for: .touchUpInside)

        let saveItem = UIBarButtonItem(customView: saveBtn)
        navigationItem.rightBarButtonItem = saveItem
    }
}
