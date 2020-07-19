import SwiftUI

public struct RoundedEdge: ViewModifier {
  let width: CGFloat
  let color: Color
  let cornerRadius: CGFloat

  public init(width: CGFloat, color: Color, cornerRadius: CGFloat) {
    self.width = width
    self.color = color
    self.cornerRadius = cornerRadius
  }

  public func body(content: Content) -> some View {
    content.cornerRadius(cornerRadius - width)
      .padding(width)
      .background(color)
      .cornerRadius(cornerRadius)
  }
}
