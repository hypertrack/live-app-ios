import Branch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [
      UIApplication.LaunchOptionsKey: Any
    ]?
  ) -> Bool {
    let branch = Branch.getInstance()
    branch.initSession(
      launchOptions: launchOptions,
      andRegisterDeepLinkHandler: { params, error in
        if let safe = params {
          LiveEventPublisher.postDeepLink()
          logDeepLink.log("Branch: \(safe)")
        } else {
          logDeepLink.error("Branch with error: \(String(describing: error))")
        }
      }
    )
    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(
    _: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options _: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(
      name: "Default Configuration",
      sessionRole: connectingSceneSession.role
    )
  }
}
