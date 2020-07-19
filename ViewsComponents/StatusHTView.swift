import Prelude
import SwiftUI

public struct StatusHTView: View {
  @State private var isInfoTrackingViewEnabled = false
  @Binding var isTracking: Bool

  public init(isTracking: Binding<Bool>) {
    _isTracking = isTracking
  }

  public var body: some View {
    HStack {
      Spacer()
      if self.isInfoTrackingViewEnabled {
        HStack {
          Text("\(self.isTracking ? "Tracking is active" : "Tracking is disabled")")
            .font(
              Font.system(size: 14)
                .weight(.medium))
            .foregroundColor(Color("TitleColor"))
            .frame(height: 32)
            .padding(.leading, 11)
            .padding(.trailing, 16)
        }
        .background(Color("NavigationBarColor"))
        .cornerRadius(8)
        .shadow(radius: 1, y: 3)
        Spacer()
          .frame(width: 16)
      }
      Button(action: {
        self.isInfoTrackingViewEnabled.toggle()
      }) {
        Text(self.isTracking ? "Active" : "Inactive")
          .font(
            Font.system(size: 12)
              .weight(.medium))
      }
      .foregroundColor(Color.white)
      .padding([.top, .bottom], 5)
      .padding([.leading, .trailing], 8)
      .background(self
        .isTracking ? Color(UIColor.primary_1) : Color(UIColor.context_3))
      .cornerRadius(14)
    }
    .frame(height: 32)
    .padding(.trailing, 8)
  }
}
