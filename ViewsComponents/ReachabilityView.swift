import Model
import Prelude
import SwiftUI

public struct ReachabilityView: View {
  var state: ReachabilityViewDisplayState = .center

  public enum ReachabilityViewDisplayState {
    case fillwidth
    case center
  }

  public init(state: ReachabilityViewDisplayState = .center) {
    self.state = state
  }

  public var body: some View {
    GeometryReader { _ in
      HStack(spacing: 0.0) {
        Image("icOffline")
          .padding(.leading, 19.0)
        Text("No connection")
          .font(
            Font.system(size: 14)
              .weight(.medium))
          .foregroundColor(Color(UIColor.tertiary_7_white))
          .padding(.leading, 11.0)
          .padding(.trailing, self.state == .center ? 19.0 : 0.0)
        if self.state == .fillwidth {
          Spacer()
        }
      }
      .frame(height: 32.0)
      .background(Color(UIColor.context_1))
      .opacity(0.8)
      .cornerRadius(self.state == .center ? 16.0 : 0.0)
    }
    .frame(height: 32.0)
  }
}
