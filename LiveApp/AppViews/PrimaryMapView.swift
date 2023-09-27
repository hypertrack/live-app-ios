import HyperTrack
import HyperTrackViews
import Model
import Store
import SwiftUI
import ViewsComponents

struct PrimaryMapView: View {
  @EnvironmentObject var store: Store<AppState, Action>
  @ObservedObject var hyperTrackUpdater: HyperTrackUpdater
  @ObservedObject var monitor: ReachabilityMonitor
  @Binding var alertIdentifier: AlertIdentifier?
  @Binding var sheetIdentifier: SheetIdentifier?
  @State private var isAutoZoomEnabled = true
  @State private var isTracking = false
  @State private var showMenu = false

  private var inputData: HyperTrackData
  private let apiClient: ApiClientProvider
  private let eventReceiver: LiveEventReceiver

  init(
    monitor: ReachabilityMonitor,
    alertIdentifier: Binding<AlertIdentifier?>,
    sheetIdentifier: Binding<SheetIdentifier?>,
    inputData: HyperTrackData,
    apiClient: ApiClientProvider,
    eventReceiver: LiveEventReceiver
  ) {
    self.monitor = monitor
    _alertIdentifier = alertIdentifier
    _sheetIdentifier = sheetIdentifier
    self.inputData = inputData
    self.eventReceiver = eventReceiver
    self.apiClient = apiClient
    hyperTrackUpdater = HyperTrackUpdater(
      inputData: self.inputData
    )
  }

  var body: some View {
    return GeometryReader { geometry in
      ZStack(alignment: .leading) {
        ZStack(alignment: .top) {
          MapView(isAutoZoomEnabled: self.$isAutoZoomEnabled)
          VStack(spacing: 0) {
            HStack(alignment: .top) {
              Button(action: {
                self.showMenu.toggle()
              }) {
                Image("menu_icon")
                  .resizable()
                  .frame(width: 50, height: 50)
              }
              .padding([.leading], 8)
              .shadow(radius: 1, y: 3)
              Spacer()
              StatusHTView(isTracking: self.$isTracking)
            }
            .frame(height: 40.0)
            self.getZoomButton()
            Spacer()
            if !self.monitor.isReachable {
              ReachabilityView(state: .center)
                .padding(.bottom, 8)
            }
            self.getDestinationView()
          }
          .padding(
            .top,
            geometry.safeAreaInsets.top > 20 ? geometry.safeAreaInsets
              .top : 35
          )
          .padding(
            .bottom,
            geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets
              .bottom : 24
          )
        }
        .animation(.easeInOut(duration: 0.2))
        .edgesIgnoringSafeArea(.all)
        SideMenu(
          leftMenu: MenuView(
            inputData: self.inputData,
            apiClient: self.apiClient
          ),
          isLeftPanelShow: self.$showMenu,
          config: SideMenuConfig(
            menuBGColor: Color("BackgroundColor"),
            menuBGOpacity: 0.5,
            menuWidth: geometry.size.width - geometry.size.width / 4
          )
        )
      }
      .navigationBarTitle("")
      .navigationBarHidden(true)
      .background(Color("BackgroundColor"))
      .modifier(ContentPresentationModifier(
        alertIdentifier: self.$alertIdentifier,
        exceptionIdentifier: self.$sheetIdentifier
      ))
      .onAppear {
        self.inputData.update(.updateShareVisibilityStatus(false))
        self.isTracking = HyperTrack.isTracking
        self.hyperTrackUpdater.createUserMovementStatusSubscription()
      }
      .onDisappear {
        self.hyperTrackUpdater.cancelAllSubscriptions()
      }
      .onReceive(self.eventReceiver.$isTracking) {
        self.isTracking = $0
      }
      .onReceive(self.monitor.$isReachable) {
        if $0, !self.hyperTrackUpdater.connectionEstablished {
          self.hyperTrackUpdater.createAllSubscriptions()
        } else {
          self.hyperTrackUpdater.cancelAllSubscriptions()
        }
      }
      .onReceive(self.hyperTrackUpdater.$userMovementStatus) {
        self.movementStatusHandler($0)
      }
      .onReceive(appStateReceiver.$didBecomeActive) {
        if $0.name == UIApplication.didBecomeActiveNotification {
          self.hyperTrackUpdater.createUserMovementStatusSubscription()
        }
      }
      .onReceive(appStateReceiver.$didEnterBackground) {
        if $0.name == UIApplication.didEnterBackgroundNotification {
          self.hyperTrackUpdater.cancelAllSubscriptions()
        }
      }
    }
  }

  private func getDestinationView() -> some View {
    VStack(spacing: 0.0) {
      HStack {
        Spacer()
        Text("Where are you going?")
          .font(
            Font.system(size: 20)
              .weight(.medium))
          .foregroundColor(Color("TitleColor"))
          .padding(.top, 16)
          .padding([.leading, .trailing], 0)
        Spacer()
      }
      Button(action: {
        self.store.update(.updateFlow(.destinationInputListView))
      }) {
        HStack {
          Text("I’m going to…")
            .font(
              Font.system(size: 14)
                .weight(.regular))
            .foregroundColor(Color("TitleColor"))
            .padding(.leading, 16)
          Spacer()
          Image("search")
            .padding(.trailing, 12)
        }
        .frame(height: 44)
        .background(Color("TextFieldBackgroundColor"))
        .foregroundColor(Color("FakeDestinationButtonForegroundColor"))
        .modifier(RoundedEdge(
          width: 0.5,
          color: Color("TextFiledBorderColor"),
          cornerRadius: 22
        ))
      }
      .disabled(!self.monitor.isReachable)
      .padding([.leading, .trailing, .top], 16)
      .padding(.bottom, 12)
    }
    .background(Color("NavigationBarColor"))
    .cornerRadius(24)
    .padding([.leading, .trailing], 8)
    .shadow(radius: 1, y: 3)
    .any
  }

  private func getZoomButton() -> some View {
    HStack {
      Spacer()
      Button(action: {
        self.isAutoZoomEnabled.toggle()
      }) {
        Image("zoom_icon")
          .resizable()
          .frame(width: 50, height: 50)
      }
      .opacity(self.isAutoZoomEnabled ? 0.0 : 1.0)
      .shadow(radius: 1, y: 3)
    }
    .padding(.top, 10)
    .padding([.leading, .trailing], 8)
  }

  private func movementStatusHandler(_ movementStatus: MovementStatus?) {
    guard let movementStatus = movementStatus else { return }
    if !movementStatus.trips.isEmpty {
      DispatchQueue.main.async {
        self.inputData.update(.insertTripId(movementStatus.trips.sorted {
          $0.startedAt < $1.startedAt
          }
          .first?.id ?? ""))
        self.hyperTrackUpdater.cancelAllSubscriptions()
        DispatchQueue.main.async {
          if self.store.value.viewIndex != .trackingMapView {
            self.store.update(.updateFlow(.trackingMapView))
          }
        }
      }
    }
  }
}
