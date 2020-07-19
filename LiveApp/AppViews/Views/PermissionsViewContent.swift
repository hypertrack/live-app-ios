import Model
import SwiftUI
import ViewsComponents

struct PermissionsViewContent: View {
  private var model: ContentModel
  private var action: () -> Void

  init(
    _ model: ContentModel,
    _ action: @escaping () -> Void
  ) {
    self.model = model
    self.action = action
  }

  public var body: some View {
    return GeometryReader { geometry in
      VStack {
        Text(self.model.title)
          .font(
            Font.system(size: 22)
              .weight(.bold))
          .padding(.top, 104)
        Image("illustrations")
          .resizable()
          .scaledToFit()
          .padding(.top, 30)
          .padding([.leading, .trailing], 70)
        Text(self.model.subTitle)
          .font(
            Font.system(size: 14)
              .weight(.bold))
          .lineLimit(4)
          .padding(.top, 5)
          .padding([.leading, .trailing], 36)
        Spacer()
        Button(action: {
          self.action()
        }) {
          HStack {
            Spacer()
            Text(self.model.controlTitle)
              .font(
                Font.system(size: 20)
                  .weight(.bold))
              .foregroundColor(Color.white)
            Spacer()
          }
        }
        .buttonStyle(LiveGreenButtonStyle(false))
        .padding([.trailing, .leading], 64)
        .padding(
          .bottom,
          geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets
            .bottom : 24
        )
      }
      .navigationBarTitle("")
      .navigationBarHidden(true)
      .background(Color("BackgroundColor"))
      .edgesIgnoringSafeArea(.all)
    }
  }
}
