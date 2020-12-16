import AWSMobileClient
import Model
import Prelude
import Store
import SwiftUI
import ViewsComponents

struct EmailSentView: View {
  @EnvironmentObject var store: Store<AppState, Action>
  let hyperTrackData: HyperTrackData

  var body: some View {
    return GeometryReader { geometry in
      ZStack {
        VStack {
          HStack {
            Image("check")
            Text("Email Sent")
              .font(
                Font.system(size: 24)
                  .weight(.semibold))
              .foregroundColor(Color("TitleColor"))
          }
          Text("We sent an email to \(self.hyperTrackData.email). Please use the link in it to reset your password")
            .font(
              Font.system(size: 14)
                .weight(.medium))
            .lineLimit(3)
            .padding(.top, 16)
        }
        .padding([.leading, .trailing], 16)
        VStack {
          Spacer()
          Button(action: {
            self.store.update(.updateFlow(.loginView))
          }) {
            HStack {
              Spacer()
              Text("Sign in")
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
      }
      .navigationBarTitle("")
      .navigationBarHidden(true)
      .background(Color("BackgroundColor"))
      .edgesIgnoringSafeArea(.all)
    }
  }
}

private final class Input: ObservableObject {
  @Published var email: String = ""
}

struct ForgotPasswordView: View {
  @EnvironmentObject var store: Store<AppState, Action>
  @ObservedObject private var inputText: Input
  @State private var isActivityIndicatorVisible = false
  @State private var errorMessage: String = ""

  private let hyperTrackData: HyperTrackData
  private let apiClient: ApiClientProvider

  init(
    hyperTrackData: HyperTrackData,
    apiClient: ApiClientProvider
  ) {
    self.hyperTrackData = hyperTrackData
    self.apiClient = apiClient
    inputText = Input()
    inputText.email = hyperTrackData.email
  }

  var body: some View {
    return GeometryReader { geometry in
      ZStack {
        VStack {
          Text("Forgot your password?")
            .font(
              Font.system(size: 24)
                .weight(.semibold))
            .foregroundColor(Color("TitleColor"))
            .padding(.top, 44)
          VStack(alignment: .leading) {
            Text("Please provide your registered email address. We will send an email with a link to reset your password")
              .font(
                Font.system(size: 14)
                  .weight(.medium))
              .foregroundColor(Color("TitleColor"))
              .padding(.top, 31)
            Text("Your registered email address")
              .font(
                Font.system(size: 14)
                  .weight(.semibold))
              .foregroundColor(Color(UIColor.tertiary_4_mdark))
              .padding(.top, 20)
            TextField("", text: self.$inputText.email, onCommit:  {})
              .textContentType(.emailAddress)
              .keyboardType(.emailAddress)
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
          .padding(.top, 20)
          .padding([.leading, .trailing], 16)
          Button(action: {
            self.hyperTrackData.update(.updateRegistrationData(
              companyName: "",
              email: self.inputText.email,
              password: ""
            )
            )
            self.makeForgottenPassword()
          }) {
            HStack {
              Spacer()
              Text("Reset password")
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
          Text("Already have an account?")
            .font(
              Font.system(size: 14)
                .weight(.medium))
            .foregroundColor(Color(UIColor.tertiary_4_mdark))
          Button(action: {
            self.store.update(.updateFlow(.loginView))
          }) {
            HStack {
              Spacer()
              Text("Sign in")
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
    }
    .modifier(HideKeyboard())
  }

  private func makeForgottenPassword() {
    isActivityIndicatorVisible.toggle()
    apiClient.forgottenPassword(hyperTrackData.email) {
      switch $0 {
        case .success:
          DispatchQueue.main
            .async { self.store.update(.updateFlow(.emailSentView)) }
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
