import HyperTrack
import Model
import Store
import SwiftUI
import ViewsComponents

struct PermissionsView: View {
  @EnvironmentObject var store: Store<AppState, Action>
  @State private var permissionAction: PermissionAction
  private let permissionsProvier: PermissionsProvider
  private let contentModel: ContentModel
  private let popAction: () -> Void

  enum PermissionAction {
    case requestPermissions
    case custom
  }

  init(
    permissionsProvier: PermissionsProvider,
    contentModel: ContentModel,
    permissionAction: PermissionAction,
    popAction: @escaping () -> Void
  ) {
    self.permissionsProvier = permissionsProvier
    self.contentModel = contentModel
    _permissionAction = State(initialValue: permissionAction)
    self.popAction = popAction
  }

  var body: some View {
    PermissionsViewContent(self.contentModel) {
      switch self.permissionAction {
        case .requestPermissions:
          self.permissionsProvier.requestPermissions()
        case .custom:
          self.getiOSSettings()
      }
    }
    .onReceive(self.permissionsProvier.$isFullAccessGranted) { output in
      if output {
        self.popAction()
      }
    }
    .onReceive(self.permissionsProvier.$locationPermissionsStatus) { status in
      if case PermissionsProvider.PermissionsStatus.denied = status {
        self.permissionAction = .custom
      } else if case PermissionsProvider.PermissionsStatus
        .notDetermined = status {
        self.permissionAction = .requestPermissions
      }
    }
  }

  /// Get settings URL
  private func getiOSSettings() {
    guard let deppLink = URL(string: contentModel.deepLink ?? "")
      else { return }
    UIApplication.shared.open(deppLink)
  }
}
