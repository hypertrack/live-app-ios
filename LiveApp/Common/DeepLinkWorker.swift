import Branch
import HyperTrack
import Model
import Store

public enum BranchState {
  case processing
  case processinComplete
}

enum CompletionState {
  case processing
  case checkingComplete
}

final class DeepLinkWorker {
  private let completion: (_ state: BranchState) -> Void
  let store: Store<AppState, Action>
  let hyperTrackData: HyperTrackData
  var isFirstStart: Bool = true
  
  init(store: Store<AppState, Action>, hyperTrackData: HyperTrackData, completion: @escaping (_ state: BranchState) -> Void = { _ in }) {
    self.store = store
    self.hyperTrackData = hyperTrackData
    self.completion = completion
    self.completion(.processing)
    NotificationCenter.default.addObserver(self, selector: #selector(workWithDeepLink), name: NSNotification.Name(
      rawValue: Constant.Notification.LiveDeepLink.name
    ), object: nil)
  }

  @objc func workWithDeepLink() {
    let installParams = Branch.getInstance().getLatestReferringParams()
    let branchPublishableKey = installParams?["publishable_key"] as? String ?? ""
    let appPublishableKey = hyperTrackData.publishableKey ?? ""
    let isAppPublishableKeyEmpty = appPublishableKey.isEmpty
    let isBranchPublishableKeyEmpty = branchPublishableKey.isEmpty
    
    
    switch (isAppPublishableKeyEmpty, isBranchPublishableKeyEmpty, self.isFirstStart) {
    case (true, true, true):
      self.isFirstStart = false
      self.completion(.processinComplete)
    case (false, _, true):
      self.isFirstStart = false
      self.completion(.processinComplete)
    case (true, false, _):
      self.isFirstStart = false
      logDeepLink.log("Deep link param is passed. Presenting PrimaryMapView screen. Payload: \(String(describing: installParams))")
      self.hyperTrackData.update(.insertPublishableKey(branchPublishableKey))
      self.hyperTrackData.update(.updateSignedInFromDeeplink(true))
      self.store.update(.updateFlow(.permissionsView))
      self.completion(.processinComplete)
    default:
      logDeepLink.error("Deep link param is wrong. Nothing to do")
    }
    
//    if let publishableKey = installParams?["publishable_key"] as? String {
//      guard !publishableKey.isEmpty else {
//        logDeepLink.error("Deep link param is wrong with, publishableKey: \(publishableKey)")
//        self.completion(.processinComplete)
//        return
//      }
//      if let insidePublishableKey = hyperTrackData.publishableKey, !insidePublishableKey.isEmpty {
//        logDeepLink.error("Deep link param is passed. But some user already logged in.")
//        self.completion(.processinComplete)
//        return
//      }
//      logDeepLink.log("Deep link param is passed. Presenting PrimaryMapView screen. Payload: \(String(describing: installParams))")
//      hyperTrackData.update(.insertPublishableKey(publishableKey))
//      hyperTrackData.update(.updateSignedInFromDeeplink(true))
//      store.update(.updateFlow(.permissionsView))
//      self.completion(.processinComplete)
//    } else {
//      logDeepLink.error("Deep link param is wrong. Payload: \(String(describing: installParams))")
//      if isFirstStart {
//        self.completion(.processinComplete)
//        isFirstStart = false
//      }
//    }
  }
}
