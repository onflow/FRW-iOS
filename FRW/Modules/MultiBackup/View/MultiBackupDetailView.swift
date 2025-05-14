//
//  MultiBackupDetailView.swift
//  FRW
//
//  Created by cat on 2024/1/7.
//

import MapKit
import SwiftUI

struct MultiBackupDetailView: RouteableView {
    // MARK: Lifecycle

    init(item: KeyDeviceModel) {
        _viewModel = StateObject(wrappedValue: MultiBackupDetailViewModel(item: item))
    }

    // MARK: Internal

    @StateObject
    var viewModel: MultiBackupDetailViewModel

    var title: String {
        "backup_detail".localized
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    Map(coordinateRegion: .constant(region()), annotationItems: annotations()) {
                        MapAnnotation(coordinate: $0) {
                            Image("map_pin_1")
                                .frame(width: 40, height: 51)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 136)
                    .cornerRadius(16)
                    Text(viewModel.item.multiBackupType()!.title + " " + "backup".localized)
                        .font(.inter(size: 16, weight: .bold))
                        .foregroundColor(Color.Theme.Text.black8)
                        .frame(height: 24)
                        .padding(.top, 8)

                    keyView
                        .padding(.top, 16)
                    backupInfo
                        .padding(.top, 24)
                }
                .padding(.horizontal, 18)
                .frame(maxHeight: .infinity)
            }

            Spacer()

            Button {
                viewModel.onDisplayPharse()
            } label: {
                Text("View Recovery Phrase".localized)
                    .foregroundColor(Color.white)
                    .font(.inter(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(.Theme.Accent.green)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 18)
            .visibility(viewModel.showPhrase ? .visible : .gone)

            Button {
                viewModel.onDelete()
            } label: {
                Text("delete_backup".localized)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(.Theme.Accent.red.opacity(0.12))
                    .cornerRadius(16)
                    .foregroundColor(Color.Theme.Accent.red)
                    .font(.inter(size: 16, weight: .semibold))
            }
            .padding(.horizontal, 18)
        }
        .applyRouteable(self)
        .tracedView(self)
        .halfSheet(showSheet: $viewModel.showRemoveTipView, autoResizing: true, backgroundColor: Color.LL.Neutrals.background) {
            DangerousTipSheetView(
                title: "account_key_revoke_title".localized,
                detail: "account_key_revoke_content".localized,
                buttonTitle: "hold_to_revoke".localized
            ) {
                viewModel.deleteMultiBackup()
            } onCancel: {
                viewModel.onCancelTip()
            }
        }
    }

    var keyView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text("key_location".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.Theme.Text.black3)
                Spacer()
            }

            HStack(spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Image(viewModel.item.backupInfo?.backupType().smallIcon ?? "")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(.trailing, 8)

                    Text("backup".localized + " - " + viewModel.item.multiBackupType()!.title)
                        .padding(.horizontal, 8)
                        .frame(height: 20)
                        .font(.inter(size: 10, weight: .bold))
                        .foregroundStyle(Color.Theme.Text.black3)
                        .background(Color.Theme.Text.black3.fixedOpacity())
                        .cornerRadius(4)

                    Spacer()

                    Text("multi_sign".localized)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .frame(height: 20)
                        .font(.inter(size: 9, weight: .bold))
                        .foregroundStyle(Color.Theme.Text.black3)
                        .background(Color.Theme.Text.black3.fixedOpacity())
                        .cornerRadius(4)

                    Image("icon-account-arrow-right")
                        .renderingMode(.template)
                        .foregroundColor(.LL.Neutrals.text)
                        .frame(width: 16, height: 16)
                        .padding(.leading, 16)
                }
                .frame(height: 52)
                .padding(.horizontal, 16)
                .background(.Theme.Background.grey)
                .cornerRadius(16)
            }
            .onTapGesture {
                Router.route(to: RouteMap.Profile.accountKeys)
            }
        }
    }

    var backupInfo: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("backup_info".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.Theme.Text.black3)
                Spacer()
            }

            Color.clear
                .frame(height: 8)

            VStack {
                DeviceInfoItem(
                    title: "application_tag".localized,
                    detail: viewModel.item.device.showApp()
                )
                Divider()
                    .background(Color.Theme.Line.line)
                    .padding(.vertical, 16)
                DeviceInfoItem(
                    title: "ip_address_tag".localized,
                    detail: viewModel.item.device.showIP()
                )
                Divider()
                    .background(Color.Theme.Line.line)
                    .padding(.vertical, 16)
                DeviceInfoItem(
                    title: "location".localized,
                    detail: viewModel.item.device.showLocation()
                )
                Divider()
                    .background(Color.Theme.Line.line)
                    .padding(.vertical, 16)
                DeviceInfoItem(
                    title: "entry_date_tag".localized,
                    detail: viewModel.item.device.showDate()
                )
            }
            .padding(.all, 16)
            .background(.Theme.Background.grey)
            .cornerRadius(16)
        }
    }

    func region() -> MKCoordinateRegion {
        let region = MKCoordinateRegion(
            center: viewModel.item.device.coordinate(),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        return region
    }

    func annotations() -> [CLLocationCoordinate2D] {
        [
            viewModel.item.device.coordinate(),
        ]
    }
}
