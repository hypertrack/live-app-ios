import Branch
import HyperTrack
import Model
import Prelude
import Store
import SwiftUI
import UIKit

let appStateReceiver: ApplicationStateReceiver = ApplicationStateReceiver()

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  let store = Store(
    initialValue: AppState(),
    reducer: appReducer
  )
  let hyperTrackData = HyperTrackData()
  var deepLinkWorker: DeepLinkWorker?

  func scene(
    _ scene: UIScene,
    willConnectTo _: UISceneSession,
    options: UIScene.ConnectionOptions
  ) {
    // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
    // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
    // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

    let coloredNavAppearance = UINavigationBarAppearance()
    coloredNavAppearance.configureWithOpaqueBackground()
    coloredNavAppearance.backgroundColor = UIColor(named: "NavigationBarColor")
    UINavigationBar.appearance().standardAppearance = coloredNavAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = coloredNavAppearance
    UITableView.appearance().separatorStyle = .none
    UITableView.appearance().backgroundColor = .clear
    
    
    if let windowScene = scene as? UIWindowScene {
      let window = UIWindow(windowScene: windowScene)
    
      deepLinkWorker = DeepLinkWorker(
        store: store,
        hyperTrackData: hyperTrackData
      ) { [weak self] state in
        guard let self = self else { return }
          switch state {
          case .processing:
            window.rootViewController = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
          case .processinComplete:
            window.rootViewController = UIHostingController(
              rootView: ScreenCoordinator(
                searcher: LocationSearcher(data: self.hyperTrackData),
                hyperTrackData: self.hyperTrackData,
                apiClient: ApiClient(),
                permissionsProvider: PermissionsProvider()
              ).environmentObject(self.store)
            )
        }
      }
      
      self.window = window
      window.makeKeyAndVisible()
    }
  }

  func scene(_: UIScene, continue userActivity: NSUserActivity) {
    logDeepLink.log("Branch: scene.continueUserActivity")
    Branch.getInstance().continue(userActivity)
  }
}
