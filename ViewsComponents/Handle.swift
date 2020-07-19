import SwiftUI

public struct Handle: View {
  private let handleThickness = CGFloat(5.0)

  public init() {}

  public var body: some View {
    RoundedRectangle(cornerRadius: handleThickness / 2.0)
      .frame(width: 40, height: handleThickness)
      .foregroundColor(Color("HandleColor"))
      .padding(5)
  }
}
