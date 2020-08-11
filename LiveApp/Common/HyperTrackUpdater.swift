import Combine
import HyperTrack
import HyperTrackViews
import Model

final class HyperTrackUpdater: ObservableObject {
  private var cancelViewsMovementStatusSubscription: Cancel?
  private var cancelMovementStatusWithSelectedTripSubscription: Cancel?
  private let hyperTrack: HyperTrack
  private let inputData: HyperTrackData
  private var hyperTrackViews: HyperTrackViews?
  private var removedTripId: String?
  @Published var userMovementStatus: MovementStatus? = nil
  @Published var movementStatusWithSelectedTrip: MovementStatus? = nil

  public var connectionEstablished = false

  init(
    hyperTrack: HyperTrack,
    inputData: HyperTrackData
  ) {
    self.hyperTrack = hyperTrack
    self.inputData = inputData
  }

  func setRemovedTripId(_ id: String) {
    removedTripId = id
  }

  func createUserMovementStatusSubscription() {
    if hyperTrackViews == nil {
      hyperTrackViews = HyperTrackViews(
        publishableKey: inputData.publishableKey ?? ""
      )
    }

    cancelViewsMovementStatusSubscription = hyperTrackViews?
      .subscribeToMovementStatusUpdates(
        for: hyperTrack.deviceID,
        completionHandler: { [weak self] result in
          guard let self = self else { return }
          switch result {
            case let .success(movementStatus):
              self.connectionEstablished = true
              let isTripContains = movementStatus.trips
                .contains { $0.id == self.removedTripId }
              if !isTripContains {
                self.userMovementStatus = movementStatus
              }
            case let .failure(error):
              self.connectionEstablished = false
              self.createUserMovementStatusSubscription()
          }
        }
      )
  }

  func createMovementStatusWithSelectedTripSubscription() {
    guard let tripId = inputData.tripId else { return }

    if hyperTrackViews == nil {
      hyperTrackViews = HyperTrackViews(
        publishableKey: inputData.publishableKey ?? ""
      )
    }

    cancelMovementStatusWithSelectedTripSubscription = hyperTrackViews?
      .subscribeToMovementStatusUpdates(
        for: hyperTrack.deviceID,
        withTripIDs: [tripId],
        completionHandler: { [weak self] result in
          guard let self = self else { return }
          switch result {
            case let .success(movementStatus):
              self.connectionEstablished = true
              self.movementStatusWithSelectedTrip = movementStatus
            case .failure:
              self.connectionEstablished = false
              self.createMovementStatusWithSelectedTripSubscription()
          }
        }
      )
  }

  func createAllSubscriptions() {
    if hyperTrackViews == nil {
      hyperTrackViews = HyperTrackViews(
        publishableKey: inputData.publishableKey ?? ""
      )
    }
    createUserMovementStatusSubscription()
    createMovementStatusWithSelectedTripSubscription()
  }

  func cancelAllSubscriptions() {
    cancelViewsMovementStatusSubscription = nil
    cancelMovementStatusWithSelectedTripSubscription = nil
    hyperTrackViews = nil
    connectionEstablished = false
  }
}
