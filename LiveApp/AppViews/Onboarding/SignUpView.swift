import AWSMobileClient
import Model
import Prelude
import Store
import SwiftUI
import ViewsComponents

private final class Input: ObservableObject {
  @Published var companyName: String = ""
  @Published var email: String = ""
  @Published var password: String = ""
}

struct SignUpView: View {
  @EnvironmentObject var store: Store<AppState, Action>
  @ObservedObject private var inputText: Input
  @ObservedObject private var keyboard: KeyboardResponder = KeyboardResponder()
  @State private var errorMessage: String
  @State private var isActivityIndicatorVisible: Bool = false

  private let hyperTrackData: HyperTrackData
  private let apiClient: ApiClientProvider

  init(
    hyperTrackData: HyperTrackData,
    apiClient: ApiClientProvider
  ) {
    self.hyperTrackData = hyperTrackData
    self.apiClient = apiClient
    _errorMessage = State(initialValue: self.hyperTrackData.errorMessage)
    inputText = Input()
    inputText.companyName = hyperTrackData.companyName
    inputText.email = hyperTrackData.email
    inputText.password = hyperTrackData.password
  }

  var body: some View {
    return GeometryReader { _ in
      ZStack {
        VStack {
          Text("Sign up a new account")
            .font(
              Font.system(size: 24)
                .weight(.semibold))
            .foregroundColor(Color("TitleColor"))
            .padding(.top, 44)
          Text("Free 100k events per month. No credit card required.")
            .font(
              Font.system(size: 14)
                .weight(.medium))
            .foregroundColor(Color(UIColor.tertiary_5_m))
          HStack {
            Rectangle()
              .frame(width: 24, height: 8)
              .foregroundColor(self
                .checkRegistrationData() ? Color(UIColor.tertiary_5_m) :
                Color(UIColor.context_1))
              .cornerRadius(4)
            Rectangle()
              .frame(width: 8, height: 8)
              .foregroundColor(Color(UIColor.tertiary_5_m))
              .cornerRadius(4)
          }
          VStack(alignment: .leading) {
            Text("Company or product name (optional)")
              .font(
                Font.system(size: 14)
                  .weight(.semibold))
              .foregroundColor(Color(UIColor.tertiary_4_mdark))
            TextField("", text: self.$inputText.companyName)
              .frame(height: 21)
              .textFieldStyle(LiveTextFieldStyle(
                color: Color(UIColor.tertiary_5_m)
              ))
            Text("Email address")
              .font(
                Font.system(size: 14)
                  .weight(.semibold))
              .foregroundColor(Color(UIColor.tertiary_4_mdark))
              .padding(.top, 17)
            TextField("", text: self.$inputText.email)
              .textContentType(.emailAddress)
              .keyboardType(.emailAddress)
              .frame(height: 21)
              .textFieldStyle(LiveTextFieldStyle(
                color: Color(UIColor.tertiary_5_m)
              ))
            Text("Password")
              .font(
                Font.system(size: 14)
                  .weight(.semibold))
              .foregroundColor(Color(UIColor.tertiary_4_mdark))
              .padding(.top, 17)
            SecureField("", text: self.$inputText.password)
              .frame(height: 21)
              .textContentType(.password)
              .textFieldStyle(LiveTextFieldStyle(
                color: Color(UIColor.tertiary_5_m)
              ))
            if !self.errorMessage.isEmpty {
              Text(self.errorMessage)
                .font(
                  Font.system(size: 14)
                    .weight(.medium))
                .foregroundColor(Color(UIColor.context_3))
            }
          }
          .padding(.top, 39)
          .padding([.leading, .trailing], 16)
          HStack {
            self.backButton
            self.nextButton
          }
          .padding(.top, 55)
          .padding([.leading, .trailing], 44)
          Spacer()
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .background(Color("BackgroundColor"))
        .edgesIgnoringSafeArea(.all)
        if self.isActivityIndicatorVisible {
          LottieView()
            .edgesIgnoringSafeArea(.all)
        }
      }
    }
    .onReceive(self.keyboard.$isKeyboardShown) {
      if $0 { self.errorMessage = "" }
    }
    .modifier(HideKeyboard())
  }

  var backButton: some View {
    Button(action: {
      self.store.update(.updateFlow(.loginView))
    }) {
      HStack {
        Spacer()
        Text("Back")
          .font(
            Font.system(size: 20)
              .weight(.bold))
          .foregroundColor(Color("SignUpBackButtonTitleColor"))
        Spacer()
      }
    }
    .frame(height: 48)
  }

  var nextButton: some View {
    Button(action: {
      self.nextAction()
    }) {
      HStack {
        Spacer()
        Text("Next")
          .font(
            Font.system(size: 20)
              .weight(.bold))
        Spacer()
      }
    }
    .buttonStyle(LiveGreenButtonStyle(false))
    .frame(height: 48)
    .disabled(self.checkRegistrationData())
  }

  func checkRegistrationData() -> Bool {
    if !inputText.email.isEmpty,
      !inputText.password.isEmpty {
      return false
    } else {
      return true
    }
  }

  private func nextAction() {
    hyperTrackData.update(.updateRegistrationData(
      companyName: inputText.companyName,
      email: inputText.email,
      password: inputText.password
    ))
    store.update(.updateFlow(.tellusView))
  }
}
