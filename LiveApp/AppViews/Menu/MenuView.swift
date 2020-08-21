import Model
import Store
import SwiftUI
import HyperTrack

enum StartTrackingRequestState {
  case requestInFlight
  case requestComplete
}

struct MenuView: View {
  @EnvironmentObject var store: Store<AppState, Action>
  @State private var startTrackingRequestState: StartTrackingRequestState = .requestComplete
  @State private var hypertrackTrackingState: Bool = false
  private var inputData: HyperTrackData
  private var hyperTrack: HyperTrack
  private let apiClient: ApiClientProvider

  init(
    inputData: HyperTrackData,
    hyperTrack: HyperTrack,
    apiClient: ApiClientProvider
  ) {
    self.inputData = inputData
    self.hyperTrack = hyperTrack
    self.apiClient = apiClient
  }

  var body: some View {
    return GeometryReader { geometry in
      VStack(spacing: 0.0) {
        Text(self.inputData.masterAccountEmail)
          .font(
            Font.system(size: 16)
              .weight(.semibold))
          .foregroundColor(Color("TitleColor"))
        Divider()
          .frame(height: 1)
          .background(Color("menuDividerColor"))
          .padding(.top, 12)
        Button(action: {
          self.store.update(.updateFlow(.deeplinkView))
        }) {
          HStack(spacing: 0.0) {
            Image("sideBarInviteTeamMemberIcon")
            Text("Invite")
              .font(Font.system(size: 16))
              .foregroundColor(Color("TitleColor"))
              .padding(.leading, 12)
            Spacer()
          }
          .padding([.top, .leading], 20)
        }
        Button(action: {
          self.store.update(.updateFlow(.homeAddressView))
        }) {
          HStack(spacing: 0.0) {
            Image("icHomeAddress")
            Text("Home address")
              .font(Font.system(size: 16))
              .foregroundColor(Color("TitleColor"))
              .padding(.leading, 12)
            Spacer()
          }
          .padding([.top, .leading], 20)
        }
        HStack(spacing: 0.0) {
          Image("icTrack")
          Toggle(isOn: Binding(
            get: { self.hypertrackTrackingState },
              set: { self.startTracking($0) }
            )) {
            Text("Tracking")
              .font(Font.system(size: 16))
              .foregroundColor(Color("TitleColor"))
              .padding(.leading, 12)
          }
          Spacer()
        }
        .disabled(self.startTrackingRequestState == .requestInFlight ? true : false)
        .padding([.top, .leading], 20)
        Spacer()
        Divider()
          .frame(height: 1)
          .background(Color("menuDividerColor"))
          .padding(.bottom, 12)
          .opacity(self.inputData.isSignedInFromDeeplink ? 0.0 : 1.0)
        Button(action: {
          self.apiClient.stopTracking(self.inputData, self.hyperTrack, self.hyperTrack.deviceID) { _ in }
          self.apiClient.signOut()
          self.inputData.update(.signOut)
          self.inputData.update(.updatePass(""))
          self.inputData.update(.updateEmail(""))
          self.store.update(.updateFlow(.loginView))
        }) {
          Text("Sign out")
            .font(
              Font.system(size: 16)
                .weight(.medium))
            .foregroundColor(Color(UIColor.context_3))
            .frame(maxWidth: .infinity)
        }.opacity(self.inputData.isSignedInFromDeeplink ? 0.0 : 1.0)
      }
      .padding(
        .top,
        geometry.safeAreaInsets.top > 20 ? geometry.safeAreaInsets
          .top : 35
      )
      .padding(
        .bottom,
        geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets
          .bottom : 34
      )
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color("menuBeckgroundColor"))
      .clipped()
      .shadow(radius: 2, x: 5)
    }.onAppear {
      self.hypertrackTrackingState = self.hyperTrack.isRunning
    }
  }
  
  private func startTracking(_ newState: Bool) {
    self.hypertrackTrackingState = newState
    self.startTrackingRequestState = .requestInFlight
    if self.hyperTrack.isRunning {
      self.apiClient.stopTracking(self.inputData, self.hyperTrack, self.hyperTrack.deviceID) { reuslt in
        DispatchQueue.main.async {
          self.startTrackingRequestState = .requestComplete
        }
      }
    } else {
      self.apiClient.startTracking(self.inputData, self.hyperTrack, self.hyperTrack.deviceID) { reuslt in
        DispatchQueue.main.async {
          self.startTrackingRequestState = .requestComplete
        }
      }
    }
  }
}
