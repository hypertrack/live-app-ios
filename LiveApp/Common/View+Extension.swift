import Combine
import Foundation
import HyperTrack
import Model
import Store
import SwiftUI

func getExceptionPermissionsView(
  _ permissionsAction: ExceptionPermissionsView.PermissionAction,
  _ inputError: LiveError
) -> some View {
  return ExceptionPermissionsView(
    contentModel: ContentModel.getContentForLiveError(inputError),
    permissionAction: permissionsAction
  ).any
}
