import Model
import Prelude
import Store
import SwiftUI
import ViewsComponents

struct OnboardView: View {
  @EnvironmentObject var store: Store<AppState, Action>
  private var inputData: HyperTrackData
  
  public init(inputData: HyperTrackData) {
    self.inputData = inputData
  }
  
  var body: some View {
    GeometryReader { geometry in
      VStack {
        Text("Welcome to HyperTrack Live!")
          .font(
            Font.system(size: 22)
              .weight(.bold))
          .padding(.top, 104)
        Image("illustrations")
          .resizable()
          .scaledToFit()
          .padding(.top, 30)
          .padding([.leading, .trailing], 70)
        VStack(alignment: .leading) {
          Text("Step 1: Sign in with a HyperTrack account")
            .padding(.top, 30)
            .padding([.leading, .trailing], 36)
          Text("Step 2: Allow use of location")
            .padding(.top, 5)
            .padding([.leading, .trailing], 36)
          Text("Step 3: Start sharing live location with ETA when on the way!")
            .padding(.top, 5)
            .padding([.leading, .trailing], 36)
        }
        Spacer()
        Button(action: {
          self.store.update(.updateFlow(.loginView))
        }) {
          HStack {
            Spacer()
            Text("I'm ready!")
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
      .onAppear {
        self.inputData.update(.updateSignedInFromDeeplink(true))
      }
    }
  }
}
