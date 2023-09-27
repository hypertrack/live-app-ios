import Combine
import Foundation
import HyperTrack
import Model
import SwiftUI

final class LiveEventReceiver {
  @Published var error: LiveError? = nil
  @Published var isTracking: Bool = false

  private var isUnlocked = false
  private var hyperTrackCancellables: [HyperTrack.Cancellable] = []
  private var combineCancellables: [AnyCancellable] = []

  init() {
    combineCancellables.append(NotificationCenter.Publisher(
      center: .default,
      name: Notification.Name(rawValue: Constant.Notification.LiveError.name),
      object: nil
    )
      .compactMap { $0.unpackError() }
      .sink { liveError in
        self.error = .some(liveError)
      })
  }

  public func unlock(pk: String) {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let hypertrackDirectory = documentsDirectory.appendingPathComponent("hypertrack")
    let filePath = hypertrackDirectory.appendingPathComponent("publishable_key_dynamic")
    do {
        try FileManager.default.createDirectory(at: hypertrackDirectory, withIntermediateDirectories: true, attributes: nil)
    } catch {
        fatalError()
    }
    do {
      try pk.write(to: filePath, atomically: true, encoding: .utf8)
    } catch {
      fatalError()
    }
    guard !isUnlocked else { return }
    hyperTrackCancellables.append(HyperTrack.subscribeToErrors({ errors in
      for error in errors {
        self.error = LiveError(hyperTrackError: error)
      }
    }))

    hyperTrackCancellables.append(HyperTrack.subscribeToIsTracking({ isTracking in
      self.isTracking = isTracking
    }))
    isUnlocked = true
  }
}

extension Notification {
  public func unpackError() -> LiveError? {
    if let error = userInfo?[Constant.Notification.LiveError.key]
      as? LiveError
    { return error } else { return nil }
  }
}
