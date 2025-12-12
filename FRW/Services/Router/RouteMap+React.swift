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
  }
}

extension RouteMap.ReactNative: RouterTarget {
  func onPresent(navi: UINavigationController) {
    switch self {
    case .sendAsset(let config):
      let props = RNBridge.InitialProps(screen: .sendAsset, sendToConfig: config?.toJSON())
      navi.present(ReactNativeViewController(initialProps: props))
    case .profileSelection:
      let props = RNBridge.InitialProps(screen: .onboarding, sendToConfig: nil)
      navi.present(ReactNativeViewController(initialProps: props))
    case .getStarted:
      let vc = ReactNativeViewController()
      vc.route = .getStarted
      navi.pushViewController(vc)
    }
  }
}
