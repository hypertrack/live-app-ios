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
    guard let pk = hyperTrackData.publishableKey,
      let hypertrackPublishableKey = HyperTrack.PublishableKey(pk)
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    switch HyperTrack.makeSDK(publishableKey: hypertrackPublishableKey, automaticallyRequestPermissions: false) {
      case let .success(hypertrack):
        return SharingDeepLinkView(
          alertIdentifier: $alertIdentifier,
          sheetIdentifier: $sheetIdentifier,
          apiClient: apiClient,
          hyperTrackData: hyperTrackData,
          hyperTrack: hypertrack
        ).any
      case let .failure(error):
        switch error {
          case .developmentError:
            fatalError()
          case .productionError:
            return PermissionsView(
              permissionsProvier: permissionsProvider,
              contentModel: ContentModel.getContentForLiveError(LiveError(
                fatalError: error
              )),
              permissionAction: .custom
            ) {
              DispatchQueue.main
                .async { self.store.update(.updateFlow(.deeplinkView)) }
            }.any
        }
    }
  }
  
  private func destinationInputListView() -> some View {
    guard let pk = hyperTrackData.publishableKey,
      let hypertrackPublishableKey = HyperTrack.PublishableKey(pk)
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    searcher.removeSearchData()
    switch HyperTrack.makeSDK(publishableKey: hypertrackPublishableKey, automaticallyRequestPermissions: false) {
      case let .success(hypertrack):
        return DestinationInputListView(
          searcher: searcher,
          monitor: monitor,
          alertIdentifier: $alertIdentifier,
          sheetIdentifier: $sheetIdentifier,
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          hyperTrack: hypertrack
        ).any
      case let .failure(error):
        switch error {
          case .developmentError:
            fatalError()
          case .productionError:
            return PermissionsView(
              permissionsProvier: permissionsProvider,
              contentModel: ContentModel.getContentForLiveError(LiveError(
                fatalError: error
              )),
              permissionAction: .custom
            ) {
              DispatchQueue.main
                .async {
                  self.store.update(.updateFlow(.destinationInputListView))
                }
            }.any
        }
    }
  }

  private func editGeofenceView() -> some View {
    guard let pk = hyperTrackData.publishableKey,
      let hypertrackPublishableKey = HyperTrack.PublishableKey(pk)
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    searcher.removeSearchData()
    switch HyperTrack.makeSDK(publishableKey: hypertrackPublishableKey, automaticallyRequestPermissions: false) {
      case let .success(hypertrack):
        return EditGeofenceView(
          searcher: searcher,
          monitor: monitor,
          alertIdentifier: $alertIdentifier,
          sheetIdentifier: $sheetIdentifier,
          inputData: hyperTrackData,
          apiClient: apiClient,
          hyperTrack: hypertrack
        ).any
      case let .failure(error):
        switch error {
          case .developmentError:
            fatalError()
          case .productionError:
            return PermissionsView(
              permissionsProvier: permissionsProvider,
              contentModel: ContentModel.getContentForLiveError(LiveError(
                fatalError: error
              )),
              permissionAction: .custom
            ) {
              DispatchQueue.main
                .async {
                  self.store.update(.updateFlow(.editGeofenceView))
                }
            }.any
        }
    }
  }
  
  private func homeAddressView() -> some View {
    guard let pk = hyperTrackData.publishableKey,
      let hypertrackPublishableKey = HyperTrack.PublishableKey(pk)
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    searcher.removeSearchData()
    switch HyperTrack.makeSDK(publishableKey: hypertrackPublishableKey, automaticallyRequestPermissions: false) {
      case let .success(hypertrack):
        return ManuHomeAddressView(
          searcher: searcher,
          monitor: monitor,
          alertIdentifier: $alertIdentifier,
          sheetIdentifier: $sheetIdentifier,
          inputData: hyperTrackData,
          apiClient: apiClient,
          hyperTrack: hypertrack
        ).any
      case let .failure(error):
        switch error {
          case .developmentError:
            fatalError()
          case .productionError:
            return PermissionsView(
              permissionsProvier: permissionsProvider,
              contentModel: ContentModel.getContentForLiveError(LiveError(
                fatalError: error
              )),
              permissionAction: .custom
            ) {
              DispatchQueue.main
                .async {
                  self.store.update(.updateFlow(.homeAddressView))
                }
            }.any
        }
    }
  }

  private func trackingMapView() -> some View {
    guard let pk = hyperTrackData.publishableKey,
      let hypertrackPublishableKey = HyperTrack.PublishableKey(pk)
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    switch HyperTrack.makeSDK(publishableKey: hypertrackPublishableKey, automaticallyRequestPermissions: false) {
      case let .success(hypertrack):

        let shareVisibility = hyperTrackData.shareVisibilityStatus

        return TrackingMapView(
          monitor: monitor,
          alertIdentifier: $alertIdentifier,
          sheetIdentifier: $sheetIdentifier,
          inputData: hyperTrackData,
          apiClient: apiClient,
          hyperTrack: hypertrack,
          eventReceiver: eventReceiver,
          state: shareVisibility ? TrackingMapView.TrackingMapViewState.share : TrackingMapView.TrackingMapViewState.tripList
        ).any
      case let .failure(error):
        switch error {
          case .developmentError:
            fatalError()
          case .productionError:
            return PermissionsView(
              permissionsProvier: permissionsProvider,
              contentModel: ContentModel.getContentForLiveError(LiveError(
                fatalError: error
              )),
              permissionAction: .custom
            ) {
              DispatchQueue.main
                .async { self.store.update(.updateFlow(.trackingMapView)) }
            }.any
        }
    }
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
    guard let pk = hyperTrackData.publishableKey,
      let hypertrackPublishableKey = HyperTrack.PublishableKey(pk)
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    searcher.removeSearchData()
    switch HyperTrack.makeSDK(publishableKey: hypertrackPublishableKey, automaticallyRequestPermissions: false) {
      case let .success(hypertrack):
        return GeofenceInputListView(
          searcher: searcher,
          alertIdentifier: $alertIdentifier,
          sheetIdentifier: $sheetIdentifier,
          inputData: hyperTrackData,
          apiClient: apiClient,
          hyperTrack: hypertrack
        ).any
      case let .failure(error):
        switch error {
          case .developmentError:
            fatalError()
          case .productionError:
            return PermissionsView(
              permissionsProvier: permissionsProvider,
              contentModel: ContentModel.getContentForLiveError(LiveError(
                fatalError: error
              )),
              permissionAction: .custom
            ) {
              DispatchQueue.main
                .async {
                  self.store.update(.updateFlow(.geofenceInputListView))
                }
            }.any
        }
    }
  }

  private func loginView() -> some View {
    return LoginView(
      hyperTrackData: hyperTrackData,
      apiClient: apiClient,
      permissionsProvier: permissionsProvider
    )
  }

  private func primaryMapView() -> some View {
    guard let pk = hyperTrackData.publishableKey,
      let hypertrackPublishableKey = HyperTrack.PublishableKey(pk)
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    switch HyperTrack.makeSDK(publishableKey: hypertrackPublishableKey, automaticallyRequestPermissions: false) {
      case let .success(hypertrack):
        self.getMasterAccount(hyperTrack: hypertrack)
        return PrimaryMapView(
          monitor: monitor,
          alertIdentifier: $alertIdentifier,
          sheetIdentifier: $sheetIdentifier,
          inputData: hyperTrackData,
          hyperTrack: hypertrack,
          apiClient: apiClient,
          eventReceiver: eventReceiver
        ).any
      case let .failure(error):
        switch error {
          case .developmentError:
            fatalError()
          case .productionError:
            return PermissionsView(
              permissionsProvier: permissionsProvider,
              contentModel: ContentModel.getContentForLiveError(LiveError(
                fatalError: error
              )),
              permissionAction: .custom
            ) {
              DispatchQueue.main
                .async { self.store.update(.updateFlow(.primaryMapView)) }
            }.any
        }
    }
  }

  private func metadataMapView() -> some View {
    guard let pk = hyperTrackData.publishableKey,
      let hypertrackPublishableKey = HyperTrack.PublishableKey(pk)
      else {
        return LoginView(
          hyperTrackData: hyperTrackData,
          apiClient: apiClient,
          permissionsProvier: permissionsProvider
        ).any
    }
    switch HyperTrack.makeSDK(publishableKey: hypertrackPublishableKey, automaticallyRequestPermissions: false) {
      case let .success(hypertrack):
        self.startTracking(hyperTrack: hypertrack)
        return MetadataView(
          hyperTrackData: hyperTrackData,
          hyperTrack: hypertrack,
          action: {
            self.store.update(.updateFlow(.geofenceInputListView))
        }
        ).any
      case let .failure(error):
        switch error {
          case .developmentError:
            fatalError()
          case .productionError:
            return PermissionsView(
              permissionsProvier: permissionsProvider,
              contentModel: ContentModel.getContentForLiveError(LiveError(
                fatalError: error
              )),
              permissionAction: .custom
            ) {
              DispatchQueue.main
                .async { self.store.update(.updateFlow(.metadataView)) }
            }.any
        }
    }
  }
  
  private func startTracking(hyperTrack: HyperTrack) {
    if !hyperTrack.isRunning {
      apiClient.startTracking(self.hyperTrackData, hyperTrack.deviceID) { _ in
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
          hyperTrack.syncDeviceSettings()
        }
      }
    } else {
      logGeneral.log("Tracking already started.")
    }
  }
  
  private func stopTracking(hyperTrack: HyperTrack) {
    logGeneral.log("Call stopTracking.")
    apiClient.stopTracking(self.hyperTrackData, hyperTrack.deviceID) { _ in
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
        hyperTrack.syncDeviceSettings()
      }
    }
  }
  
  private func getMasterAccount(hyperTrack: HyperTrack) {
    if self.hyperTrackData.masterAccountEmail.isEmpty {
      self.apiClient.getMasterAccount(self.hyperTrackData, hyperTrack.deviceID) {
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
