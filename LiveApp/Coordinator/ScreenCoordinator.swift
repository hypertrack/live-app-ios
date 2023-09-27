import Foundation
import HyperTrack
import Model
import Prelude
import Store
import SwiftUI

struct ScreenCoordinator: View {
  @EnvironmentObject var store: Store<AppState, Action>
  @State private var alertIdentifier: AlertIdentifier?
  @State private var sheetIdentifier: SheetIdentifier?
  private let eventReceiver = LiveEventReceiver()
  private let monitor: ReachabilityMonitor = ReachabilityMonitor()

  let searcher: LocationSearcher
  let hyperTrackData: HyperTrackData
  let apiClient: ApiClientProvider
  let permissionsProvider: PermissionsProvider
  
  private var animation: Animation? {
    switch store.value.viewIndex {
      case .loginView,
           .signUpView,
           .onboardView,
           .tellusView,
           .verifyView,
           .forgotPasswordView,
           .emailSentView:
        return nil
      default:
        return .easeIn
    }
  }

  var body: some View {
    logView.log("View changed to: \(store.value.viewIndex)")
    return ZStack {
      if store.value.viewIndex == .onboardView {
        OnboardView(inputData: self.hyperTrackData)
      } else if store.value.viewIndex == .loginView {
        loginView()
      } else if store.value.viewIndex == .signUpView {
        SignUpView(
          hyperTrackData: self.hyperTrackData,
          apiClient: self.apiClient
        )
      } else if store.value.viewIndex == .tellusView {
        TellusView(
          hyperTrackData: self.hyperTrackData,
          apiClient: self.apiClient
        )
      } else if store.value.viewIndex == .verifyView {
        VerifyView(
          hyperTrackData: self.hyperTrackData,
          apiClient: self.apiClient
        )
      } else if store.value.viewIndex == .forgotPasswordView {
        ForgotPasswordView(
          hyperTrackData: self.hyperTrackData,
          apiClient: self.apiClient
        )
      } else if store.value.viewIndex == .permissionsView {
        permissionsView()
      } else if store.value.viewIndex == .geofenceInputListView {
        geofenceInputListView()
      } else if store.value.viewIndex == .emailSentView {
        EmailSentView(hyperTrackData: self.hyperTrackData)
      } else if store.value.viewIndex == .destinationInputListView {
        destinationInputListView()
      } else if store.value.viewIndex == .trackingMapView {
        trackingMapView()
      } else if store.value.viewIndex == .primaryMapView {
        primaryMapView()
      } else if store.value.viewIndex == .editGeofenceView {
        editGeofenceView()
      } else if store.value.viewIndex == .deeplinkView {
        sharingDeepLinkView()
      } else if store.value.viewIndex == .metadataView {
        metadataMapView()
      } else if store.value.viewIndex == .homeAddressView {
        homeAddressView()
      }
    }
    .animation(animation)
    .onAppear { self.monitor.startMonitoring() }
    .onReceive(self.eventReceiver.$error) {
      guard let error = $0 else { return }
      logView.error("Received error: \(error)")
      errorReducer(
        &self.sheetIdentifier,
        &self.alertIdentifier,
        self.store,
        error
      )
    }
  }

  private func sharingDeepLinkView() -> some View {
    guard let pk = hyperTrackData.publishableKey
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    eventReceiver.unlock(pk: pk)
    return SharingDeepLinkView(
      alertIdentifier: $alertIdentifier,
      sheetIdentifier: $sheetIdentifier,
      apiClient: apiClient,
      hyperTrackData: hyperTrackData
    ).any
  }
  
  private func destinationInputListView() -> some View {
    guard let pk = hyperTrackData.publishableKey
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    searcher.removeSearchData()
    eventReceiver.unlock(pk: pk)
    return DestinationInputListView(
      searcher: searcher,
      monitor: monitor,
      alertIdentifier: $alertIdentifier,
      sheetIdentifier: $sheetIdentifier,
      hyperTrackData: hyperTrackData,
      apiClient: apiClient
    ).any
  }

  private func editGeofenceView() -> some View {
    guard let pk = hyperTrackData.publishableKey
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    searcher.removeSearchData()
    eventReceiver.unlock(pk: pk)
    return EditGeofenceView(
      searcher: searcher,
      monitor: monitor,
      alertIdentifier: $alertIdentifier,
      sheetIdentifier: $sheetIdentifier,
      inputData: hyperTrackData,
      apiClient: apiClient
    ).any
  }
  
  private func homeAddressView() -> some View {
    guard let pk = hyperTrackData.publishableKey
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    searcher.removeSearchData()
    eventReceiver.unlock(pk: pk)
    return ManuHomeAddressView(
      searcher: searcher,
      monitor: monitor,
      alertIdentifier: $alertIdentifier,
      sheetIdentifier: $sheetIdentifier,
      inputData: hyperTrackData,
      apiClient: apiClient
    ).any
  }

  private func trackingMapView() -> some View {
    guard let pk = hyperTrackData.publishableKey
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    eventReceiver.unlock(pk: pk)
    let shareVisibility = hyperTrackData.shareVisibilityStatus
    return TrackingMapView(
      monitor: monitor,
      alertIdentifier: $alertIdentifier,
      sheetIdentifier: $sheetIdentifier,
      inputData: hyperTrackData,
      apiClient: apiClient,
      eventReceiver: eventReceiver,
      state: shareVisibility ? TrackingMapView.TrackingMapViewState.share : TrackingMapView.TrackingMapViewState.tripList
    ).any
  }

  private func permissionsView() -> some View {
    PermissionsView(
      permissionsProvier: permissionsProvider,
      contentModel: ContentModel(.default),
      permissionAction: .requestPermissions
    ) {
      DispatchQueue.main.async {
        self.store.update(.updateFlow(.metadataView))
      }
    }
  }

  private func geofenceInputListView() -> some View {
    guard let pk = hyperTrackData.publishableKey
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    searcher.removeSearchData()
    eventReceiver.unlock(pk: pk)
    return GeofenceInputListView(
      searcher: searcher,
      alertIdentifier: $alertIdentifier,
      sheetIdentifier: $sheetIdentifier,
      inputData: hyperTrackData,
      apiClient: apiClient
    ).any
  }

  private func loginView() -> some View {
    return LoginView(
      hyperTrackData: hyperTrackData,
      apiClient: apiClient,
      permissionsProvier: permissionsProvider
    )
  }

  private func primaryMapView() -> some View {
    guard let pk = hyperTrackData.publishableKey
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    eventReceiver.unlock(pk: pk)
    self.getMasterAccount()
    return PrimaryMapView(
      monitor: monitor,
      alertIdentifier: $alertIdentifier,
      sheetIdentifier: $sheetIdentifier,
      inputData: hyperTrackData,
      apiClient: apiClient,
      eventReceiver: eventReceiver
    ).any
  }

  private func metadataMapView() -> some View {
    guard let pk = hyperTrackData.publishableKey
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    eventReceiver.unlock(pk: pk)
    self.startTracking()
    return MetadataView(
      hyperTrackData: hyperTrackData,
      action: {
        self.store.update(.updateFlow(.geofenceInputListView))
    }
    ).any
  }
  
  private func startTracking() {
    logGeneral.log("Starting Tracking")
    apiClient.startTracking(self.hyperTrackData, { _ in })
  }
  
  private func stopTracking() {
    logGeneral.log("Stopping Tracking")
    apiClient.stopTracking(self.hyperTrackData, { _ in })
  }
  
  private func getMasterAccount() {
    if self.hyperTrackData.masterAccountEmail.isEmpty {
      self.apiClient.getMasterAccount(self.hyperTrackData) {
        switch $0 {
        case let .success(masteraccount):
          DispatchQueue.main.async {
            self.hyperTrackData.masterAccountEmail = masteraccount
          }
        case .failure: break
        }
      }
    }
  }
}
