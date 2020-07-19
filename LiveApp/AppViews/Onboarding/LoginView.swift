import AWSMobileClient
import Model
import Prelude
import Store
import SwiftUI
import ViewsComponents

struct LoginView: View {
  @EnvironmentObject var store: Store<AppState, Action>
  @State private var isActivityIndicatorVisible = false
  @State private var login: String = ""
  @State private var password: String = ""
  @State private var errorMessage: String = ""

  private var inputData: HyperTrackData
  private let apiClient: ApiClientProvider
  private let permissionsProvier: PermissionsProvider

  init(
    hyperTrackData: HyperTrackData,
    apiClient: ApiClientProvider,
    permissionsProvier: PermissionsProvider
  ) {
    inputData = hyperTrackData
    self.apiClient = apiClient
    self.permissionsProvier = permissionsProvier
    _login = State(initialValue: inputData.email)
  }

  var body: some View {
    return GeometryReader { geometry in
      ZStack {
        VStack {
          Text("Sign in to your account")
            .font(
              Font.system(size: 24)
                .weight(.semibold))
            .foregroundColor(Color("TitleColor"))
            .padding(.top, 44)
          VStack(alignment: .leading) {
            Text("Email address")
              .font(
                Font.system(size: 14)
                  .weight(.semibold))
              .foregroundColor(Color(UIColor.tertiary_4_mdark))
            TextField("", text: self.$login)
              .frame(height: 21)
              .textFieldStyle(LiveTextFieldStyle(
                color: Color(UIColor.tertiary_5_m)
              ))
              .textContentType(.emailAddress)
              .keyboardType(.emailAddress)
            Text("Password")
              .font(
                Font.system(size: 14)
                  .weight(.semibold))
              .foregroundColor(Color(UIColor.tertiary_4_mdark))
              .padding(.top, 33)
            SecureField("", text: self.$password) { self.makeLogin() }
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
          Button(action: {
            self.makeLogin()
          }) {
            HStack {
              Spacer()
              Text("Sign in")
                .font(
                  Font.system(size: 20)
                    .weight(.bold))
                .foregroundColor(Color.white)
              Spacer()
            }
          }
          .buttonStyle(LiveGreenButtonStyle(false))
          .padding(.top, 56)
          .padding([.trailing, .leading], 64)
          Spacer()
            .frame(height: 14)
          Button(action: {
            self.inputData.update(.updateRegistrationData(
              companyName: "",
              email: self.login,
              password: ""
            )
            )
            self.store.update(.updateFlow(.forgotPasswordView))
          }) {
            Text("Forgot Password?")
              .font(
                Font.system(size: 16)
                  .weight(.medium))
              .foregroundColor(Color(UIColor.context_1))
          }
          .padding()
          Spacer()
          Text("Don’t have an account?")
            .font(
              Font.system(size: 14)
                .weight(.medium))
            .foregroundColor(Color(UIColor.tertiary_4_mdark))
          Button(action: {
            self.store.update(.updateFlow(.signUpView))
          }) {
            HStack {
              Spacer()
              Text("Sign up?")
                .font(
                  Font.system(size: 20)
                    .weight(.bold))
                .foregroundColor(Color("LivebtSignUpForegroundColor"))
              Spacer()
            }
          }
          .buttonStyle(LiveSignUpButtonStyle())
          .padding(.top, 12)
          .padding([.trailing, .leading], 64)
          .padding(
            .bottom,
            geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets
              .bottom : 24
          )
        }
        if self.isActivityIndicatorVisible {
          LottieView()
            .edgesIgnoringSafeArea(.all)
        }
      }
      .navigationBarTitle("")
      .navigationBarHidden(true)
      .background(Color("BackgroundColor"))
      .edgesIgnoringSafeArea(.all)
      .onReceive(appStateReceiver.$keyboardWillShow) { _ in
        self.errorMessage = ""
      }
      .onAppear {
        self.inputData.update(.updateSignedInFromDeeplink(true))
        self.inputData.update(.signOut)
        self.apiClient.signOut()
      }
    }.modifier(HideKeyboard())
  }

  private func makeLogin() {
    UIApplication.shared.endEditing()
    isActivityIndicatorVisible.toggle()
    apiClient.signIn(login, password) {
      switch $0 {
        case let .success(publishableKey):
          DispatchQueue.main.async { self.isActivityIndicatorVisible.toggle() }
          self.inputData.update(.insertPublishableKey(publishableKey))
          self.inputData.update(.updateEmail(self.login))
          self.inputData.update(.updatePass(self.password))
          self.inputData.update(.updateSignedInFromDeeplink(false))
          if self.permissionsProvier.isFullAccessGranted {
            DispatchQueue.main
              .async { self.store.update(.updateFlow(.metadataView)) }
          } else {
            DispatchQueue.main
              .async { self.store.update(.updateFlow(.permissionsView)) }
          }
        case let .failure(error):
          DispatchQueue.main.async { self.isActivityIndicatorVisible.toggle() }
          if let error = error as? AWSMobileClientError {
            self.errorMessage = error.message
          } else if case let .appSyncAuthError(message) = error as? LiveError {
            self.errorMessage = message
          } else {
            self.errorMessage = error.localizedDescription
          }
      }
    }
  }
}
