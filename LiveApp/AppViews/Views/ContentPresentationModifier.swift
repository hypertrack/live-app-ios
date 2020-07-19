import Model
import Store
import SwiftUI
import ViewsComponents

struct ContentPresentationModifier: ViewModifier {
  @EnvironmentObject var store: Store<AppState, Action>
  @Binding var alertIdentifier: AlertIdentifier?
  @Binding var exceptionIdentifier: SheetIdentifier?
  var onAppear: (() -> Void)?
  var geofenceAlertDisappear: (() -> Void)?
  var shareURL: String?

  public func body(content: Content) -> some View {
    content
      .sheet(
        item: $exceptionIdentifier,
        onDismiss: {
          self.exceptionIdentifier = nil
        }, content: { exceptionId in
          self.getSheet(exceptionId)
        }
      )
      .alert(item: $alertIdentifier) { alertId in
        switch alertId.id {
        case .htError:
          let errorModel = ContentModel.getContentForLiveError(alertId.content)
          return Alert(
            title: Text(errorModel.title),
            message: Text(errorModel.subTitle),
            dismissButton: .default(Text("OK"), action: {
              errorActionReducer(
                &self.exceptionIdentifier,
                self.store,
                alertId.content
              )
            })
          )
        case .addedGeofence:
          return Alert(
            title: Text("Home location successfully added"),
            message: nil,
            dismissButton: .default(Text("OK"), action: {
              self.geofenceAlertDisappear?()
            })
          )
        }
    }
  }

  private func getSheet(_ sheetIdentifier: SheetIdentifier) -> some View {
    onAppear?()
    switch sheetIdentifier.id {
      case .permissions:
        return getExceptionPermissionsView(
          .requestPermissions,
          sheetIdentifier.content!
        ).any
      case .permissionsSettings:
        return getExceptionPermissionsView(
          .custom,
          sheetIdentifier.content!
        ).any
      case .share:
        return ShareView(activityItems: [sheetIdentifier.sheetData!], callback: { _, completed, _, _ in
          sheetIdentifier.callBack?(completed)
        }).any
    }
  }
}
