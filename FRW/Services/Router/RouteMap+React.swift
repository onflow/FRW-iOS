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
    case profileSelection
    case getStarted
    case backupTip
    case migration
  }
}

extension RouteMap.ReactNative: RouterTarget {
  func onPresent(navi: UINavigationController) {
    switch self {
    case .sendAsset(let config):
      let props = RNBridge.InitialProps(screen: .sendAsset, sendToConfig: config?.toJSON())
      let vc = ReactNativeViewController(initialProps: props)
      navi.present(ReactNativeViewController(initialProps: props))
    case .profileSelection:
      let props = RNBridge.InitialProps(screen: .onboarding, sendToConfig: nil)
      let vc = ReactNativeViewController(initialProps: props)
      navi.pushViewController(vc)
    case .getStarted:
      let vc = ReactNativeViewController()
      vc.route = .getStarted
      navi.pushViewController(vc)
    case .backupTip:
      let props = RNBridge.InitialProps(screen: .backupTip, sendToConfig: nil)
      let vc = ReactNativeViewController(initialProps: props)
      vc.modalPresentationStyle = .fullScreen
      navi.present(vc)
    case .migration:
      let vc = ReactNativeViewController()
      vc.route = .migration
      navi.pushViewController(vc, animated: true)
    }
  }
}
