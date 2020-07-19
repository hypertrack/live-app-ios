import SwiftUI

public struct LiveTextFieldStyle: TextFieldStyle {
  public var color: Color
  public init(color: Color) {
    self.color = color
  }

  public func _body(
    configuration: TextField<Self._Label>
  ) -> some View {
    VStack(spacing: 4) {
      configuration
      Rectangle()
        .foregroundColor(self.color)
        .frame(height: 1.0, alignment: .bottom)
    }.padding(.top, 6)
  }
}
