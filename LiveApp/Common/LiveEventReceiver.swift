import Combine
import Foundation
import HyperTrack
import Model
import SwiftUI

final class LiveEventReceiver {
  @Published var error: LiveError? = nil
  @Published var isTracking: Bool = false

  private let errorSubject = PassthroughSubject<LiveError, Never>()
  private let trackingSubject = PassthroughSubject<Notification, Never>()
  private var cancellables: [AnyCancellable] = []

  init() {
    bindInputs()
    bindOutputs()
  }

  private func bindInputs() {
    let startedTrackingPublisher = NotificationCenter.Publisher(
      center: .default, name: HyperTrack.startedTrackingNotification,
      object: nil
    )
    let stoppedTrackingPublisher = NotificationCenter.Publisher(
      center: .default, name: HyperTrack.stoppedTrackingNotification,
      object: nil
    )

    let trackingInputStream = startedTrackingPublisher
      .merge(with: stoppedTrackingPublisher)
      .share()
      .subscribe(trackingSubject)

    let unrecoverableErrorInputPublisher = NotificationCenter.Publisher(
      center: .default,
      name: HyperTrack.didEncounterUnrestorableErrorNotification, object: nil
    )
    let recoverableErrorInputPublisher = NotificationCenter.Publisher(
      center: .default,
      name: HyperTrack.didEncounterRestorableErrorNotification, object: nil
    )
    let errorInputPublisher = NotificationCenter.Publisher(
      center: .default,
      name: Notification.Name(rawValue: Constant.Notification.LiveError.name),
      object: nil
    )

    let errorInputStream = unrecoverableErrorInputPublisher
      .merge(with: recoverableErrorInputPublisher)
      .share()
      .compactMap { $0.hyperTrackTrackingError() }
      .map { LiveError(trackingError: $0) }
      .subscribe(errorSubject)

    let liveErrorInputStream = errorInputPublisher
      .share()
      .compactMap { $0.unpackError() }
      .subscribe(errorSubject)

    cancellables += [
      trackingInputStream,
      errorInputStream,
      liveErrorInputStream
    ]
  }

  private func bindOutputs() {
    let trackingStream = trackingSubject
      .map { notification in
        switch notification.name {
          case HyperTrack.startedTrackingNotification: return true
          case HyperTrack.stoppedTrackingNotification: return false
          default: return false
        }
      }
      .receive(on: RunLoop.main)
      .assign(to: \.isTracking, on: self)

    let errorStream = errorSubject
      .map { $0 }
      .receive(on: RunLoop.main)
      .assign(to: \.error, on: self)

    cancellables += [
      trackingStream,
      errorStream
    ]
  }
}

extension Notification {
  public func unpackError() -> LiveError? {
    if let error = userInfo?[Constant.Notification.LiveError.key]
      as? LiveError
    { return error } else { return nil }
  }
}
