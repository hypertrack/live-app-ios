import Foundation
import Model

final class LiveEventPublisher {
  static func postError(error: Error) {
    DispatchQueue.main.async {
      NotificationCenter.default.post(
        name: NSNotification.Name(
          rawValue: Constant.Notification.LiveError.name
        ),
        object: nil,
        userInfo: [Constant.Notification.LiveError.key: error]
      )
    }
  }

  static func postDeepLink() {
    DispatchQueue.main.async {
      NotificationCenter.default.post(
        name: NSNotification.Name(
          rawValue: Constant.Notification.LiveDeepLink.name
        ),
        object: nil,
        userInfo: nil
      )
    }
  }
}
