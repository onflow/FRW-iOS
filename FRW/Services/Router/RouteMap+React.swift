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
    case selectAssets(RNBridge.SendToConfig?)
    case selectAddress(RNBridge.SendToConfig)
  }
}

extension RouteMap.ReactNative: RouterTarget {
  func onPresent(navi: UINavigationController) {
    switch self {
    case .selectAssets(let config):
      let props = try? config.toDictionary()
      navi.present(ReactNativeViewController(initialRoute: .selectAssets,initialProps: props))
    case .selectAddress(let config):
      let props = try? config.toDictionary()
      navi.present(ReactNativeViewController(initialRoute: .selectAddress,initialProps: props))
    }
  }
}


