import Model
import Prelude
import Store
import SwiftUI

public struct ExceptionPermissionsView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var permissionAction: PermissionAction
  private let permissionsProvier = PermissionsProvider()
  private var contentModel: ContentModel
  private let gesture = DragGesture()

  enum PermissionAction {
    case requestPermissions
    case custom
  }

  init(
    contentModel: ContentModel,
    permissionAction: PermissionAction
  ) {
    self.contentModel = contentModel
    _permissionAction = State(initialValue: permissionAction)
  }

  public var body: some View {
    PermissionsViewContent(self.contentModel) {
      switch self.permissionAction {
        case .requestPermissions:
          self.permissionsProvier.requestPermissions()
        case .custom:
          self.getiOSSettings()
      }
    }
    .highPriorityGesture(self.gesture)
    .onReceive(self.permissionsProvier.$isFullAccessGranted) { output in
      if output {
        self.presentationMode.wrappedValue.dismiss()
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
    .onReceive(self.permissionsProvier.$motionPermissionsStatus) { status in
      if case PermissionsProvider.PermissionsStatus.denied = status {
        self.permissionAction = .custom
      }
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
        UIApplication.shared.endEditing()
      }
    }
  }

  private func getiOSSettings() {
    guard let deppLink = URL(string: contentModel.deepLink ?? "")
      else { return }
    UIApplication.shared.open(deppLink)
    presentationMode.wrappedValue.dismiss()
  }
}
