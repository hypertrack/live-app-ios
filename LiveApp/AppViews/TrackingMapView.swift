import HyperTrack
import HyperTrackViews
import Model
import Prelude
import Store
import SwiftUI
import ViewsComponents

struct TrackingMapView: View {
  @EnvironmentObject var store: Store<AppState, Action>
  @ObservedObject var hyperTrackUpdater: HyperTrackUpdater
  @ObservedObject var monitor: ReachabilityMonitor
  @Binding var alertIdentifier: AlertIdentifier?
  @Binding var sheetIdentifier: SheetIdentifier?
  @State private var isTracking = false
  @State private var isAutoZoomEnabled = true
  @State private var isActivityIndicatorVisible = false
  @State private var isTripsDetailVisible = false
  @State private var vibisleView: TrackingMapViewState = .share

  private var hyperTrackData: HyperTrackData
  private var apiClient: ApiClientProvider
  private var eventReceiver: LiveEventReceiver

  enum TrackingMapViewState {
    case tripList
    case share
  }

  init(
    monitor: ReachabilityMonitor,
    alertIdentifier: Binding<AlertIdentifier?>,
    sheetIdentifier: Binding<SheetIdentifier?>,
    inputData: HyperTrackData,
    apiClient: ApiClientProvider,
    eventReceiver: LiveEventReceiver,
    state: TrackingMapViewState
  ) {
    self.monitor = monitor
    _alertIdentifier = alertIdentifier
    _sheetIdentifier = sheetIdentifier
    hyperTrackData = inputData
    self.apiClient = apiClient
    self.eventReceiver = eventReceiver
    _vibisleView = State(initialValue: state)
    hyperTrackUpdater = HyperTrackUpdater(
      inputData: hyperTrackData
    )
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .top) {
        TripMapView(
          movementStatus: self.$hyperTrackUpdater
            .movementStatusWithSelectedTrip,
          isAutoZoomEnabled: self.$isAutoZoomEnabled
        )
        self.showTopView(geometry)
        self.showViewWithState(
          state: self.vibisleView,
          geometry: geometry
        )
        if self.isActivityIndicatorVisible {
          LottieView()
        }
      }
      .disabled(self.isActivityIndicatorVisible)
      .edgesIgnoringSafeArea(.all)
      .modifier(ContentPresentationModifier(
        alertIdentifier: self.$alertIdentifier,
        exceptionIdentifier: self.$sheetIdentifier
      ))
      .onAppear {
        self.isActivityIndicatorVisible = true
        self.isTripsDetailVisible = false
        self.isTracking = HyperTrack.isTracking
        self.hyperTrackUpdater.createAllSubscriptions()
      }
      .onDisappear {
        self.isTripsDetailVisible = false
        self.isActivityIndicatorVisible = false
        self.hyperTrackUpdater.cancelAllSubscriptions()
      }
      .onReceive(self.hyperTrackUpdater.$userMovementStatus) {
        guard let movementStatus = $0 else { return }
        self.movementStatusHandler(movementStatus)
      }
      .onReceive(self.hyperTrackUpdater.$movementStatusWithSelectedTrip) {
        guard let _ = $0 else { return }
        self.handleTripSubscription()
      }
      .onReceive(self.eventReceiver.$isTracking) {
        self.isTracking = $0
      }
      .onReceive(self.monitor.$isReachable) {
        if $0, !self.hyperTrackUpdater.connectionEstablished {
          self.hyperTrackUpdater.createAllSubscriptions()
        } else {
          self.hyperTrackUpdater.cancelAllSubscriptions()
        }
      }
      .onReceive(appStateReceiver.$didBecomeActive) {
        if $0.name == UIApplication.didBecomeActiveNotification {
          self.hyperTrackUpdater.createAllSubscriptions()
        }
      }
      .onReceive(appStateReceiver.$didEnterBackground) {
        if $0.name == UIApplication.didEnterBackgroundNotification {
          self.hyperTrackUpdater.cancelAllSubscriptions()
        }
      }
    }
  }
}

extension TrackingMapView {
  private func showTopView(_ geometry: GeometryProxy) -> some View {
    return HStack(spacing: 0.0) {
      if self.vibisleView == .share {
        VStack {
          Button(action: {
            self.completeTrip {
              switch $0 {
                case let .failure(error):
                  DispatchQueue.main.async {
                    self.isActivityIndicatorVisible = false
                  }
                  LiveEventPublisher.postError(error: error)
                case .success:
                  DispatchQueue.main.async {
                    self.isActivityIndicatorVisible = false
                    self.hyperTrackData.update(.completedTrip)
                    self.store.update(.updateFlow(.destinationInputListView))
                  }
              }
            }
          }) {
            Image("backButton")
          }
          .padding(.top, 5)
          .padding(.leading, 8)
          .shadow(radius: 1, y: 3)
          Spacer()
        }
      }
      Spacer()
      VStack {
        StatusHTView(isTracking: self.$isTracking)
        HStack {
          Spacer()
          Button(action: {
            self.isAutoZoomEnabled.toggle()
          }) {
            Image("zoom_icon")
              .resizable()
              .frame(width: 50, height: 50)
          }
          .opacity(self.isAutoZoomEnabled ? 0.0 : 1.0)
          .shadow(radius: 1, y: 3)
        }
        .padding(.top, 10)
        .padding(.trailing, 8)
        Spacer()
      }
    }
    .padding(
      .top,
      geometry.safeAreaInsets.top > 20 ? geometry.safeAreaInsets
        .top : 35
    )
  }

  private func showViewWithState(
    state: TrackingMapViewState,
    geometry: GeometryProxy
  ) -> some View {
    switch state {
      case .share:
        return ZStack {
          VStack {
            Spacer()
            Button(action: {
              self.shareAction { isShare in
                if isShare {
                  self.vibisleView = .tripList
                  self.hyperTrackData.update(.updateShareVisibilityStatus(false))
                }
              }
            }) {
              HStack {
                Spacer()
                Text("Share")
                  .font(
                    Font.system(size: 20)
                      .weight(.bold))
                  .foregroundColor(Color.white)
                Spacer()
              }
            }
            .buttonStyle(LiveGreenButtonStyle(true))
            .padding([.trailing, .leading], 64)
            .padding(
              .bottom,
              geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets
                .bottom : 24
            )
          }
        }.any
      case .tripList:
        return ZStack {
          if self.isTripsDetailVisible {
            TripDetails(
              hyperTrackUpdater: self.hyperTrackUpdater,
              inputData: self.hyperTrackData,
              endButtonAction:
              { self.endTripAction() }
            )
            { self.shareAction(completion: { _ in }) }
              .disabled(!self.monitor.isReachable)
          }
        }.any
    }
  }

  private func shareAction(completion: @escaping (Bool) -> Void) {
    guard let tripId = hyperTrackData.tripId else { return }
    let trips = hyperTrackUpdater.userMovementStatus?.trips
      .first(where: { $0.id == tripId })
    if let data = trips?.views.shareURL.absoluteString {
      let shareData: String
      if let estimate = self.hyperTrackUpdater.movementStatusWithSelectedTrip?.trips.first?.destination?.estimate {
        switch estimate {
          case let .relevant(route):
            let eta = DateFormatter.stringDate(Date().addingTimeInterval(TimeInterval(route.remainingDuration)))
            shareData = "Will be there by \(eta). Track my live location here \(data)"
          default:
            shareData = "Track my live location here \(data)"
        }
      } else {
        shareData = "Track my live location here \(data)"
      }
      sheetIdentifier = SheetIdentifier(
        id: .share,
        sheetData: shareData,
        callBack: completion
      )
    }
  }

  private func endTripAction() {
    completeTrip {
      switch $0 {
        case let .failure(error):
          DispatchQueue.main.async {
            self.isTripsDetailVisible = true
            self.isActivityIndicatorVisible = false
          }
          LiveEventPublisher.postError(error: error)
        case .success:
          self.hyperTrackData.update(.completedTrip)
      }
    }
  }

  private func completeTrip(
    _ completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let tripId = hyperTrackData.tripId else { return }
    isActivityIndicatorVisible = true
    isTripsDetailVisible = false
    hyperTrackUpdater.setRemovedTripId(tripId)
    apiClient.completeTrip(hyperTrackData, tripId) { completion($0) }
  }

  private func movementStatusHandler(_ movementStatus: MovementStatus?) {
    guard let movementStatus = movementStatus else { return }
    logView.log("MovementStatus received")
    if !movementStatus.trips.isEmpty {
      let isTripAvailable = !movementStatus.trips
        .contains { $0.id == self.hyperTrackData.tripId }

      if isTripAvailable {
        hyperTrackData.update(.insertTripId(movementStatus.trips.sorted {
          $0.startedAt < $1.startedAt
          }
          .first?.id ?? ""))
        hyperTrackUpdater.createMovementStatusWithSelectedTripSubscription()
      }
    } else {
      logView.log("MovementStatus received has empty trips Set")
      hyperTrackUpdater.cancelAllSubscriptions()
      DispatchQueue.main.async {
        self.isActivityIndicatorVisible = false
        self.isTripsDetailVisible = false
        if self.store.value.viewIndex != .primaryMapView {
          self.hyperTrackData.update(.updateShareVisibilityStatus(false))
          self.store.update(.updateFlow(.primaryMapView))
        }
      }
    }
  }

  private func handleTripSubscription() {
    logView.log("MovementStatus for current trip received.")
    if let estimate = self.hyperTrackUpdater.movementStatusWithSelectedTrip?.trips.first?.destination?.estimate {
      switch estimate {
        case .generating:
          logView.log("Estimate is generating")
        case .relevant:
          logView.log("Estimate is relevant")
          isActivityIndicatorVisible = false
          isTripsDetailVisible = true
        case let .irrelevant(reason: reason):
          logView.log("Estimate is irrelevant for reason: \(reason)")
          isActivityIndicatorVisible = false
          isTripsDetailVisible = true
      }
    } else {
      logView.log("Estimate is nil")
      isActivityIndicatorVisible = false
      isTripsDetailVisible = true
    }
  }
}
