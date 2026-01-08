//
//  RouteMap+React.swift
//  FRW
//
//  Created by cat on 8/6/25.
//

import Foundation
import UIKit

extension RouteMap {
  enum ReactNative {
    case sendAsset(RNBridge.SendToConfig?)
    case backupTip
  }
}

extension RouteMap.ReactNative: RouterTarget {
  func onPresent(navi: UINavigationController) {
    switch self {
    case .sendAsset(let config):
      let props = RNBridge.InitialProps(screen: .sendAsset, sendToConfig: config?.toJSON())
      navi.present(ReactNativeViewController(initialProps: props))
    case .backupTip:
      let props = RNBridge.InitialProps(screen: .backupTip, sendToConfig: nil)
      let vc = ReactNativeViewController(initialProps: props)
      vc.modalPresentationStyle = .fullScreen
      navi.present(vc)
    }
  }
}
