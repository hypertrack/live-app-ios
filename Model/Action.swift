import Foundation
import Store
import SwiftUI

public enum Action {
  case updateFlow(ViewIndex)
}

/// applied new state at lastView
public func appReducer(_ state: inout AppState, newState: Action) {
  switch newState {
    case let .updateFlow(index):
      if state.viewIndex == index { return }
      state.viewIndex = index
  }
}
