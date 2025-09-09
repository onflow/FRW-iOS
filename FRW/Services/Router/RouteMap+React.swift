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
  }
}

extension RouteMap.ReactNative: RouterTarget {
  func onPresent(navi: UINavigationController) {
    switch self {
    case .sendAsset(let config):
      let props = RNBridge.InitialProps(screen: .sendAsset, sendToConfig: config)
      navi.present(ReactNativeViewController(initialProps: props))
    }
  }
}
