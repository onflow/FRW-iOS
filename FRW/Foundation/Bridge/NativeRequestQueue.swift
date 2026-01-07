import Foundation

@objc
final class NativeRequestQueue: NSObject {
  @objc static let shared = NativeRequestQueue()

  private let queue = DispatchQueue(label: "com.flowwallet.nativeRequestQueue")
  private var isReady = false
  private var pending: [[String: Any]] = []

  @objc
  func post(requestId: String, eventName: String, paramsJson: String) {
    let payload: [String: Any] = [
      "requestId": requestId,
      "eventName": eventName,
      "paramsJson": paramsJson,
    ]

    queue.async {
      if self.isReady {
        NotificationCenter.default.post(name: .nativeRequest, object: nil, userInfo: payload)
      } else {
        self.pending.append(payload)
      }
    }
  }

  @objc
  func markReady() {
    queue.async {
      if self.isReady {
        return
      }

      self.isReady = true
      let pendingRequests = self.pending
      self.pending.removeAll()

      for payload in pendingRequests {
        NotificationCenter.default.post(name: .nativeRequest, object: nil, userInfo: payload)
      }
    }
  }
}
