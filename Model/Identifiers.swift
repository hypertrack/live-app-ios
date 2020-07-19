import Foundation
import SwiftUI

public struct AlertIdentifier: Identifiable {
  public var id: AlertType
  public var content: LiveError

  public init(id: AlertType, content: LiveError = LiveError.unknown("")) {
    self.id = id
    self.content = content
  }

  public enum AlertType {
    case addedGeofence, htError
  }
}

public struct SheetIdentifier: Identifiable {
  public var id: ExceptionType
  public var sheetData: String?
  public var content: LiveError?
  public var callBack: ((Bool) -> Void)?

  public init(
    id: ExceptionType,
    sheetData: String? = nil,
    content: LiveError? = nil,
    callBack: ((Bool) -> Void)? = nil
  ) {
    self.id = id
    self.sheetData = sheetData
    self.content = content
    self.callBack = callBack
  }

  public enum ExceptionType {
    case permissions, permissionsSettings, share
  }
}
