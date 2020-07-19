import Prelude
import SwiftUI
import ViewsComponents

struct LiveSignUpButtonStyle: ButtonStyle {
  init() {}

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .frame(height: 48)
      .background(Color("LivebtSignUpBackgroundColor"))
      .foregroundColor(Color("LivebtSignUpForegroundColor"))
      .cornerRadius(24)
      .modifier(RoundedEdge(
        width: 0.5,
        color: Color("LivebtSigUpBorderColor"),
        cornerRadius: 24
      ))
  }
}
