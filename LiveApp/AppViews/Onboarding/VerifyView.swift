import AWSMobileClient
import Model
import Prelude
import Store
import SwiftUI
import ViewsComponents

struct VerifyView: View {
  @EnvironmentObject var store: Store<AppState, Action>
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
  }

  var body: some View {
    return GeometryReader { geometry in
      ZStack {
        VStack {
          HStack {
            Image("check")
            Text("Verify your email")
              .font(
                Font.system(size: 24)
                  .weight(.semibold))
              .foregroundColor(Color("TitleColor"))
          }
          Text("We have sent you an email with verification link. Please click on the link in the email to continue")
            .font(
              Font.system(size: 14)
                .weight(.medium))
            .lineLimit(3)
            .padding(.top, 16)
          Button(action: {
            self.makeSignIn()
          }) {
            HStack {
              Spacer()
              Text("I have verified")
                .font(
                  Font.system(size: 20)
                    .weight(.bold))
                .foregroundColor(Color.white)
              Spacer()
            }
          }
          .buttonStyle(LiveGreenButtonStyle(false))
          .padding(.top, 24)
          .padding([.trailing, .leading], 64)
          Button(action: {
            self.makeResendCode()
          }) {
            Text("Resend verification link")
              .font(
                Font.system(size: 16)
                  .weight(.medium))
              .foregroundColor(Color(UIColor.context_1))
          }
          .padding([.top, .leading, .trailing], 20)
          if !self.errorMessage.isEmpty {
            Text(self.errorMessage)
              .font(
                Font.system(size: 14)
                  .weight(.medium))
              .foregroundColor(Color(UIColor.context_3))
              .padding(.top, 10)
          }
        }
        .padding([.leading, .trailing], 16)
        VStack {
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
    }
  }

  private func makeResendCode() {
    isActivityIndicatorVisible.toggle()
    apiClient.resendConfirmationCode(hyperTrackData) { _ in
      DispatchQueue.main.async { self.isActivityIndicatorVisible.toggle() }
    }
  }

  private func makeSignIn() {
    isActivityIndicatorVisible.toggle()
    apiClient.signIn(
      hyperTrackData.email,
      hyperTrackData.password
    ) {
      switch $0 {
        case let .success(publishableKey):
          DispatchQueue.main.async {
            self.hyperTrackData.update(.removeRegData)
            self.hyperTrackData.update(.insertPublishableKey(publishableKey))
            self.hyperTrackData.update(.updateSignedInFromDeeplink(false))
            self.store.update(.updateFlow(.permissionsView))
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
