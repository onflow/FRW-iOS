/// https://gist.github.com/drekka/17c38ec226cb819312580719651163e5
/// Property wrapper that acts the same as @AppStorage, but also provides a ``Publisher`` so that non-View types
/// can receive value updates.

import Foundation
import Combine
import SwiftUI

@propertyWrapper
struct PublishedAppStorage<T: RawRepresentable> {
  private let key: String
  private let defaultValue: T

  init(wrappedValue value: T, key: String) {
      self.key = key
      self.defaultValue = value
  }

  var wrappedValue: T {
    get {
      UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
    }
    set {
      UserDefaults.standard.set(newValue, forKey: key)
    }
  }

  public static subscript<EnclosingSelf: ObservableObject>(
    _enclosingInstance object: EnclosingSelf,
    wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, T>,
    storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PublishedAppStorage<T>>
  ) -> T {
    get {
      return object[keyPath: storageKeyPath].wrappedValue
    }
    set {
      (object.objectWillChange as? ObservableObjectPublisher)?.send()
      UserDefaults.standard.set(newValue, forKey: object[keyPath: storageKeyPath].key)
    }
  }
}
