import HyperTrack
import Model
import Prelude
import Store
import SwiftUI
import ViewsComponents

private let shadowContentOffSet: CGFloat = 10.0

struct GeofenceInputListView: View {
  @EnvironmentObject var store: Store<AppState, Action>
  @ObservedObject var searcher: LocationSearcher
  @ObservedObject private var keyboard: KeyboardResponder = KeyboardResponder()
  @Binding var alertIdentifier: AlertIdentifier?
  @Binding var sheetIdentifier: SheetIdentifier?
  @State private var isActivityIndicatorVisible = false
  @State private var inputViewState: GeofenceInputListView.ViewState = .map
  @State private var isFirstResponder: Bool = false

  var inputData: HyperTrackData
  var apiClient: ApiClientProvider

  fileprivate enum ViewState {
    case list
    case map
  }

  var body: some View {
    GeometryReader { geometry in
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
              Spacer()
              Text("Set home address")
                .padding(.top, 0)
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
            Text("We will use this to make your sharing experience better.")
              .font(
                Font.system(size: 14)
                  .weight(.medium))
              .foregroundColor(Color("TitleColor"))
              .padding(.top, 16)
            HStack {
              Image("home_icon")
              ZStack {
                HStack {
                  if self.inputViewState == .map {
                    Text(!self.searcher.searchDisplayStringForMap.isEmpty ? self.searcher.searchDisplayStringForMap : "Search for home address")
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
                      placeholder: "Search for home address"
                    )
                    .frame(width: geometry.size.width - 126, height: 44)
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
            }
            .padding([.leading, .trailing, .top], 16)
            HStack(spacing: 0) {
              Spacer()
              Button(action: {
                self.store.update(.updateFlow(.primaryMapView))
              }) {
                Text("add later")
                  .font(
                    Font.system(size: 14)
                      .weight(.semibold))
                  .foregroundColor(Color(UIColor.tertiary_4_mdark))
              }
              .padding(.trailing, 14)
              .padding([.bottom, .top], 8)
            }
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
        self.saveHomeAddress(item)
      }
      .disabled(self.isActivityIndicatorVisible)
      .modifier(ContentPresentationModifier(
        alertIdentifier: self.$alertIdentifier,
        exceptionIdentifier: self.$sheetIdentifier,
        onAppear: {
          DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
            self.isFirstResponder = false
          }
        },
        geofenceAlertDisappear: {
          DispatchQueue.main.async {
            self.store.update(.updateFlow(.primaryMapView))
          }
        }
      ))
    }
  }

  private func destinationInputView(_ geometry: GeometryProxy) -> some View {
    switch inputViewState {
      case .map:
        return getSearchMap(geometry)
          .onAppear {
            self.isFirstResponder = false
            UIApplication.shared.endEditing()
          }.any
      case .list:
        return getSearchList(geometry)
          .onAppear {
            self.searcher.searchStringForList = ""
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
              self.isFirstResponder = true
            }
          }
          .onDisappear {
            self.searcher.removeSearchData()
          }.any
    }
  }

  private func getSearchList(_ geometry: GeometryProxy) -> some View {
    VStack {
      List {
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
      }
      .offset(y: shadowContentOffSet)
      .animation(nil)
      VStack(spacing: 0.0) {
        HStack {
          Button(action: {
            self.inputViewState = .map
          }) {
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
          }
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
        Spacer()
        Button(action: {
          guard let place = self.searcher.pickedPlaceFromMap else { return }
          self.saveHomeAddress(place)
        }) {
          HStack {
            Spacer()
            Text("Select")
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

  private func saveHomeAddress(_ homePlace: Place?) {
    guard let addrress = homePlace else { return }
    inputData.update(.updateHomeAddress(addrress))

    var json: HyperTrack.JSON.Object = [:]
    
    if inputData.name.count > 0 {
      json[Constant.MetadataKeys.nameKey] = .string(inputData.name)
    }
    
    if inputData.phone.count > 0 {
      json[Constant.MetadataKeys.phoneKey] = .string(inputData.phone)
    }
    
    if json.count > 0 {
      HyperTrack.metadata = json
    }
    
    if inputData.geofenceId.isEmpty {
      
      DispatchQueue.main.async { self.isActivityIndicatorVisible = true }
      self.apiClient.createGeofence(self.inputData) { result in
        DispatchQueue.main.async { self.isActivityIndicatorVisible = false }
        switch result {
        case let .success(geofence):
          self.inputData.update(.updateGeofenceId(geofence.geofenceId))
          self.alertIdentifier = AlertIdentifier(id: .addedGeofence)
        case let .failure(error):
          LiveEventPublisher.postError(error: error)
        }
      }
      
    } else {
      DispatchQueue.main.async { self.isActivityIndicatorVisible = true }
      
      apiClient.removeGeofence(inputData) { result in
        switch result {
        case .success:
          self.inputData.update(.updateGeofenceId(""))
          self.apiClient.createGeofence(self.inputData) { result in
            DispatchQueue.main.async { self.isActivityIndicatorVisible = false }
            switch result {
            case let .success(geofence):
              self.inputData.update(.updateGeofenceId(geofence.geofenceId))
              self.alertIdentifier = AlertIdentifier(id: .addedGeofence)
            case let .failure(error):
              LiveEventPublisher.postError(error: error)
            }
          }
        case let .failure(error):
          DispatchQueue.main.async { self.isActivityIndicatorVisible = false }
          LiveEventPublisher.postError(error: error)
        }
      }
    }
  }
}
