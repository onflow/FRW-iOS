//
//  RouteMap+Dev.swift
//  FRW
//
//  Created by cat on 10/9/25.
//

import Foundation
import UIKit

extension RouteMap {
  enum Developer {
    case deleteSE
  }
}

extension RouteMap.Developer: RouterTarget {
  func onPresent(navi: UINavigationController) {
    switch self {
    case .deleteSE:
      navi.push(content: DeleteSEKeychain())
    }
  }
}
