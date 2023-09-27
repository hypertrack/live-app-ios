import AWSMobileClient
import Model
import Prelude
import Store
import SwiftUI
import ViewsComponents
import HyperTrack

struct SharingDeepLinkView: View {
  @EnvironmentObject var store: Store<AppState, Action>
  @State private var isActivityIndicatorVisible = false
  @Binding var alertIdentifier: AlertIdentifier?
  @Binding var sheetIdentifier: SheetIdentifier?
  private let apiClient: ApiClientProvider
  private let hyperTrackData: HyperTrackData
  
  init(
    alertIdentifier: Binding<AlertIdentifier?>,
    sheetIdentifier: Binding<SheetIdentifier?>,
    apiClient: ApiClientProvider,
    hyperTrackData: HyperTrackData
  ) {
    _alertIdentifier = alertIdentifier
    _sheetIdentifier = sheetIdentifier
    self.hyperTrackData = hyperTrackData
    self.apiClient = apiClient
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        VStack {
          VStack(spacing: 0) {
            Rectangle()
              .fill(Color.clear)
              .frame(
                height: geometry.safeAreaInsets.top > 20.0 ? geometry
                  .safeAreaInsets.top : 20
              )
            ZStack {
              HStack {
                Button(action: {
                  self.store.update(.updateFlow(.primaryMapView))
                }) {
                  Image("close")
                    .padding(.leading, 16)
                }
                Spacer()
              }
              .frame(height: 44)
              HStack {
                Spacer()
                Text("Invite")
                  .font(
                    Font.system(size: 20)
                      .weight(.medium))
                  .foregroundColor(Color("TitleColor"))
                Spacer()
              }
              .frame(height: 44)
            }
          }
          .background(Color("NavigationBarColor"))
          .clipped()
          .shadow(radius: 5)
          VStack(alignment: .leading) {
            HStack {
              Spacer()
              Image("team_center_icon")
              Spacer()
            }
            Text("Add a device to your account by sending a deep link. ")
              .font(
                Font.system(size: 14)
                  .weight(.medium))
              .foregroundColor(Color("TitleColor"))
            Text("By adding devices to your account, you will get devices’ notifications under this account")
              .font(
                Font.system(size: 14)
                  .weight(.medium))
              .foregroundColor(Color(UIColor.tertiary_4_mdark))
              .padding(.top, 16)
          }
          .padding([.leading, .trailing, .top], 16)
          Spacer()
          Button(action: {
            self.getDeepLink()
          }) {
            HStack {
              Spacer()
              Text("Send")
                .font(
                  Font.system(size: 20)
                    .weight(.bold))
              Spacer()
            }
          }
          .buttonStyle(LiveGreenButtonStyle(false))
          .padding(.top, 12)
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
        .modifier(ContentPresentationModifier(
          alertIdentifier: self.$alertIdentifier,
          exceptionIdentifier: self.$sheetIdentifier
        ))
        if self.isActivityIndicatorVisible {
          LottieView()
            .edgesIgnoringSafeArea(.all)
        }
      }
    }
  }

  private func getDeepLink() {
    self.isActivityIndicatorVisible = true
    self.apiClient.getDeepLink(
      self.hyperTrackData,
      self.hyperTrackData.email
    ) {
      DispatchQueue.main.async {
        self.isActivityIndicatorVisible = false
      }
      switch $0 {
        case let .failure(error):
          LiveEventPublisher.postError(error: error)
        case let .success(link):
          DispatchQueue.main.async {
            self.shareAction(link) { _ in }
        }
      }
    }
  }
  
  private func shareAction(_ link: String, completion: @escaping (Bool) -> Void) {
    sheetIdentifier = SheetIdentifier(
      id: .share,
      sheetData: link,
      callBack: completion
    )
  }
}
