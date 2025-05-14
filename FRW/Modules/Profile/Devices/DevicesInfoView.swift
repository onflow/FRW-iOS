//
//  DevicesInfoView.swift
//  FRW
//
//  Created by cat on 2023/10/30.
//

import MapKit
import SwiftUI

// MARK: - CLLocationCoordinate2D + Identifiable

extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude)-\(longitude)"
    }
}

// MARK: - DevicesInfoView

struct DevicesInfoView: RouteableView {
    // MARK: Lifecycle

    init(info: DeviceInfoModel) {
        self.info = info
        _viewModel = StateObject(wrappedValue: DevicesInfoViewModel(model: info))
    }

    // MARK: Internal

    var info: DeviceInfoModel
    @StateObject
    var viewModel: DevicesInfoViewModel

    var title: String {
        "device_info".localized
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
                    Color.clear
                        .frame(height: 8)
                    Text(info.showName())
                        .font(.inter(size: 16, weight: .bold))
                        .foregroundColor(Color.Theme.Text.black8)
                        .frame(height: 24)
                    Color.clear
                        .frame(height: 24)

                    keyView
                        .padding(.top, 16)

                    VStack {
                        HStack(spacing: 0) {
                            Text("device_info".localized)
                                .font(.inter(size: 14, weight: .bold))
                                .foregroundColor(Color.Theme.Text.black3)
                            Spacer()
                        }

                        VStack {
                            DeviceInfoItem(
                                title: "application_tag".localized,
                                detail: info.showApp()
                            )
                            Divider()
                                .background(Color.Theme.Line.line)
                                .padding(.vertical, 16)
                            DeviceInfoItem(title: "ip_address_tag".localized, detail: info.showIP())
                            Divider()
                                .background(Color.Theme.Line.line)
                                .padding(.vertical, 16)
                            DeviceInfoItem(title: "location".localized, detail: info.showLocation())
                            Divider()
                                .background(Color.Theme.Line.line)
                                .padding(.vertical, 16)
                            DeviceInfoItem(
                                title: "entry_date_tag".localized,
                                detail: info.showDate()
                            )
                        }
                        .padding(.all, 16)
                        .background(.Theme.Background.grey)
                        .cornerRadius(16)
                    }
                    .padding(.top, 24)
                }
                .padding(.horizontal, 18)
                .frame(maxHeight: .infinity)
            }

            Spacer()

            VStack {
                Button {
                    viewModel.onRevoke()
                } label: {
                    Text("revoke_device".localized)
                        .font(.inter(size: 16, weight: .semibold))
                        .foregroundStyle(Color.Theme.Text.white9)
                }
                .frame(height: 54)
                .frame(maxWidth: .infinity)
                .background(Color.Theme.Accent.red)
                .cornerRadius(16)
            }
            .padding(.horizontal, 18)
            .visibility(viewModel.showRevokeButton ? .visible : .gone)
        }
        .applyRouteable(self)
        .tracedView(self)
        .halfSheet(showSheet: $viewModel.showRemoveTipView, autoResizing: true, backgroundColor: Color.LL.Neutrals.background) {
            DangerousTipSheetView(
                title: "account_key_revoke_title".localized,
                detail: "account_key_revoke_content".localized,
                buttonTitle: "hold_to_revoke".localized
            ) {
                viewModel.revokeAction()
            } onCancel: {
                viewModel.onCancel()
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
                    Image(viewModel.keyIcon)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(.trailing, 8)

                    Text(viewModel.showKeyTitle)
                        .padding(.horizontal, 8)
                        .frame(height: 20)
                        .font(.inter(size: 12, weight: .bold))
                        .foregroundStyle(viewModel.showKeyTitleColor)

                    Spacer()

                    Text("full_access".localized)
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

    func region() -> MKCoordinateRegion {
        let region = MKCoordinateRegion(
            center: info.coordinate(),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        return region
    }

    func annotations() -> [CLLocationCoordinate2D] {
        [
            info.coordinate(),
        ]
    }
}

#Preview {
    DevicesInfoView(info: DeviceInfoModel.empty())
}
