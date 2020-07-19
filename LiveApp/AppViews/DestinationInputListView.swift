import Combine
import HyperTrack
import Model
import Prelude
import Store
import SwiftUI
import ViewsComponents

private let shadowContentOffSet: CGFloat = 10.0

struct DestinationInputListView: View {
  @EnvironmentObject var store: Store<AppState, Action>
  @ObservedObject var searcher: LocationSearcher
  @ObservedObject var monitor: ReachabilityMonitor
  @ObservedObject private var keyboard: KeyboardResponder = KeyboardResponder()
  @Binding var alertIdentifier: AlertIdentifier?
  @Binding var sheetIdentifier: SheetIdentifier?
  @State private var isActivityIndicatorVisible = false
  @State private var inputViewState: DestinationInputListView.ViewState = .list
  @State private var isFirstResponder: Bool = true

  var hyperTrackData: HyperTrackData
  var apiClient: ApiClientProvider
  let hyperTrack: HyperTrack

  fileprivate enum ViewState {
    case list
    case map
  }

  var body: some View {
    return GeometryReader { geometry in
      ZStack {
        VStack(spacing: 0) {
          VStack(spacing: 0) {
            Rectangle()
              .fill(Color.clear)
              .frame(
                height: geometry.safeAreaInsets.top > 0 ? geometry
                  .safeAreaInsets.top : 20
              )
            HStack {
              Button(action: {
                print("Push .primaryMapView")
                self.store.update(.updateFlow(.primaryMapView))
              }) {
                Image("back_arrow")
                  .padding(.leading, 16)
              }
              Spacer()
              Text("I’m going to")
                .padding(.top, 0)
                .offset(x: -16)
                .font(
                  Font.system(size: 20)
                    .weight(.medium))
                .foregroundColor(Color("TitleColor"))
              Spacer()
            }
            .frame(
              height: 24
            )
            .padding(.top, 8)
            HStack {
              Image("arrivalA")
              ZStack {
                HStack {
                  if self.inputViewState == .map {
                    Text(!self.searcher.searchDisplayStringForMap.isEmpty ? self.searcher.searchDisplayStringForMap : "Search for destination")
                      .frame(
                        width: geometry.size.width - 126,
                        height: 20,
                        alignment: .leading
                      )
                      .font(
                        Font.system(size: 14)
                          .weight(.medium))
                      .clipped()
                      .offset(x: 16)
                      .padding(.trailing, 16)
                      .animation(nil)
                  } else {
                    LiveTextField(
                      text: self.$searcher.searchStringForList,
                      isFirstResponder: self.$isFirstResponder,
                      placeholder: "Search for destination"
                    )
                    .frame(width: geometry.size.width - 126)
                    .clipped()
                    .offset(x: 16)
                    .padding(.trailing, 16)
                    .animation(nil)
                  }
                  Image("search")
                    .padding(.trailing, 12)
                }
                if self.inputViewState == .map {
                  Button(action: {
                    self.inputViewState = .list
                  }) {
                    Rectangle()
                      .fill(Color("TextFieldBackgroundColor"))
                      .opacity(0.1)
                  }
                  .background(Color.clear)
                }
              }
              .frame(width: geometry.size.width - 60, height: 44)
              .background(Color("TextFieldBackgroundColor"))
              .cornerRadius(22)
              .modifier(RoundedEdge(
                width: 0.5,
                color: Color("TextFiledBorderColor"),
                cornerRadius: 22
              ))
            }
            .padding([.leading, .trailing, .top, .bottom], 16)
          }
          .background(Color("NavigationBarColor"))
          .clipped()
          .shadow(radius: 5)
          self.destinationInputView(geometry)
        }
        .modifier(HideKeyboard(callback: {
          DispatchQueue.main.async { self.isFirstResponder = false }
        }))
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .background(Color("BackgroundColor"))
        .edgesIgnoringSafeArea(.all)
        if self.isActivityIndicatorVisible {
          LottieView()
            .edgesIgnoringSafeArea(.all)
        }
      }
      .onReceive(self.searcher.$pickedPlaceFromList) {
        guard let item = $0 else { return }
        self.hyperTrackData.update(.saveLocationResult(item))
        self.createTrip(destination: item)
      }
      .disabled(self.isActivityIndicatorVisible)
      .modifier(ContentPresentationModifier(
        alertIdentifier: self.$alertIdentifier,
        exceptionIdentifier: self.$sheetIdentifier,
        onAppear: {
          DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
            self.isFirstResponder = false
          }
        }
      ))
    }
  }

  private func destinationInputView(_ geometry: GeometryProxy) -> some View {
    switch inputViewState {
      case .list:
        return getSearchList(geometry)
          .onAppear {
            self.searcher.searchStringForList = ""
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
              self.isFirstResponder = true
            }
          }.any
      case .map:
        return getSearchMap(geometry)
          .onAppear {
            self.isFirstResponder = false
            UIApplication.shared.endEditing()
          }
          .onDisappear {
            self.searcher.removeSearchData()
          }.any
    }
  }

  private func getSearchList(_ geometry: GeometryProxy) -> some View {
    VStack(spacing: 0.0) {
      if !self.monitor.isReachable {
        ReachabilityView(state: .fillwidth)
      }
      List {
        if self.searcher.searchStringForList.isEmpty {
          AddressHomeCell(
            model: self.hyperTrackData.homeAddress,
            onCellTap: {
              guard let place = $0 else {
                logDestination.error("Can't get place form Address cell")
                return
              }
              self.hyperTrackData.update(.saveLocationResult(place))
              self.createTrip(destination: place)
            }, onCreateHomeAddress: {
              self.store.update(.updateFlow(.editGeofenceView))
            }
          ) {
            self.store.update(.updateFlow(.editGeofenceView))
          }
          .frame(height: 64)
          .listRowInsets(EdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 0
          ))
        }
        ForEach(self.searcher.searchDataSource, id: \.self) { item in
          AddressCell(model: item) { selected in
            self.searcher.search(for: selected)
          }
          .frame(height: 64)
          .listRowInsets(EdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 0
          ))
        }
        if self.searcher.searchStringForList.isEmpty {
          ForEach(self.searcher.historyDataSource, id: \.id) { item in
            HistoryAddressCell(model: item) { selected in
              self.createTrip(destination: selected)
            }
            .frame(height: 64)
            .listRowInsets(EdgeInsets(
              top: 0,
              leading: 0,
              bottom: 0,
              trailing: 0
            ))
          }
        }
      }
      .offset(y: shadowContentOffSet)
      .animation(nil)
      Button(action: {
        self.inputViewState = .map
      }) {
        VStack(spacing: 0.0) {
          HStack {
            Spacer()
            Image("setOnMap")
            Text("Set on map")
              .font(
                Font.system(size: 14)
                  .weight(.medium))
              .foregroundColor(Color("TitleColor"))
            Spacer()
          }
          .frame(
            width: geometry.size.width,
            height: 48
          )
          .background(Color("NavigationBarColor"))
          .clipped()
          .shadow(radius: 5)
          Rectangle()
            .fill(Color("NavigationBarColor"))
            .frame(
              width: geometry.size.width,
              height: geometry.safeAreaInsets.bottom > 0 ? 34 : 0
            )
        }
        .offset(
          y: self.keyboard.isKeyboardShown ? geometry.safeAreaInsets.bottom > 0 ? 34 : 0 : 0
        )
      }
    }
    .padding(.bottom, keyboard.currentHeight)
    .animation(.interpolatingSpring(
      mass: 2.3,
      stiffness: 1000,
      damping: 500,
      initialVelocity: 0.5
    ))
  }

  private func getSearchMap(_ geometry: GeometryProxy) -> some View {
    ZStack {
      DestinationMapView(
        inputCoordinateForSearch: self.$searcher.searchCoordinate
      )
      VStack {
        if !self.monitor.isReachable {
          ReachabilityView(state: .fillwidth)
        }
        Spacer()
        Button(action: {
          guard let place = self.searcher.pickedPlaceFromMap else { return }
          self.hyperTrackData.update(.saveLocationResult(place))
          self.createTrip(destination: place)
        }) {
          HStack {
            Spacer()
            Text("Confirm")
              .font(
                Font.system(size: 20)
                  .weight(.bold))
              .foregroundColor(Color.white)
            Spacer()
          }
        }
        .buttonStyle(LiveGreenButtonStyle(true))
        .padding([.trailing, .leading], 64)
        .padding(
          .bottom,
          geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets
            .bottom : 24
        )
      }
    }
  }

  private func createTrip(destination: Place?) {
    isActivityIndicatorVisible = true
    guard let destination = destination else { return }
    apiClient.createTrip(
      hyperTrack.deviceID,
      destination,
      hyperTrackData,
      hyperTrack
    ) {
      DispatchQueue.main.async { self.isActivityIndicatorVisible = false }
      switch $0 {
        case let .failure(error):
          LiveEventPublisher.postError(error: error)
        case let .success(trip):
          DispatchQueue.main.async {
            self.hyperTrackData.update(.updateShareVisibilityStatus(true))
            self.hyperTrackData.update(.insertTripId(trip.id))
            self.store.update(.updateFlow(.trackingMapView))
          }
      }
    }
  }
}
