import Prelude
import SwiftUI

public struct LiveGreenButtonStyle: ButtonStyle {
  public enum State {
    case normal
    case disabled
  }

  private let gradient = LinearGradient(
    gradient: Gradient(
      colors: [Color(UIColor.primary_1), Color(UIColor.primary_2)]
    ),
    startPoint: .leading,
    endPoint: .trailing
  )
  private let isShadowEnabled: Bool
  private let state: State

  public init(_ isShadowEnabled: Bool, state: State = .normal) {
    self.state = state
    self.isShadowEnabled = isShadowEnabled
  }

  public func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .frame(height: 48)
      .foregroundColor(Color.white)
      .background(beckgroundFromCurrentState(
        state: state,
        isPressed: configuration.isPressed
      ))
      .cornerRadius(24)
      .shadow(
        color: isShadowEnabled ? Color(UIColor.primary_1).opacity(0.3) : Color
          .clear,
        radius: 10,
        x: 0,
        y: 10.5
      )
  }

  private func beckgroundFromCurrentState(
    state: LiveGreenButtonStyle.State,
    isPressed: Bool
  ) -> some View {
    switch state {
      case .normal:
        if isPressed {
          return ZStack { self.gradient
            Color(UIColor.clear)
          }
        } else {
          return ZStack { self.gradient
            Color(UIColor.tertiary_1_black).opacity(0.16)
          }
        }
      case .disabled:
        return ZStack {
          LinearGradient(
            gradient: Gradient(colors: [Color.clear]),
            startPoint: .leading,
            endPoint: .trailing
          )
          Color(UIColor.tertiary_4_mdark).opacity(0.16)
        }
    }
  }
}
