import Combine
import MapKit
import Model
import Prelude
import SwiftUI

final class LocationSearcher: NSObject, ObservableObject {
  private var geocoder: CLGeocoder
  private var searchCompleter: MKLocalSearchCompleter
  private var localSearch: MKLocalSearch? { willSet { localSearch?.cancel() } }
  private var boundingRegion: MKCoordinateRegion = MKCoordinateRegion(MKMapRect.world)
  private let hypertrackData: HyperTrackData
  var historyDataSource: [Place] {
    return hypertrackData.historyList
  }

  var didChangePickedPlaceFromList = PassthroughSubject<Place?, Never>()
  var didChangePickedPlaceFromMap = PassthroughSubject<Place?, Never>()

  @Published var searchStringForList: String = "" {
    willSet {
      makeSearch(searchString: newValue)
    }
  }

  @Published var searchDisplayStringForMap: String = ""

  @Published var searchCoordinate: CLLocationCoordinate2D? {
    willSet { makeSearchGeocodeByLocation(newValue) }
  }

  @Published var searchDataSource: [MKLocalSearchCompletion]
  @Published var pickedPlaceFromList: Place? {
    willSet { didChangePickedPlaceFromList.send(newValue) }
  }

  @Published var pickedPlaceFromMap: Place? {
    willSet { didChangePickedPlaceFromMap.send(newValue) }
  }

  init(data: HyperTrackData) {
    geocoder = CLGeocoder()
    searchCompleter = MKLocalSearchCompleter()
    hypertrackData = data
    searchDataSource = []

    super.init()

    searchCompleter.delegate = self
  }

  func makeSearch(searchString: String) {
    searchCompleter.queryFragment = searchString
    searchCompleter.resultTypes = .query
  }

  func removeSearchData() {
    searchStringForList = ""
    searchDisplayStringForMap = ""
    searchDataSource = []
    pickedPlaceFromList = nil
    pickedPlaceFromMap = nil
  }

  private func makeSearchGeocodeByLocation(_ location: CLLocationCoordinate2D?) {
    guard let location = location else { return }
    geocoder.cancelGeocode()
    geocoder.reverseGeocodeLocation(CLLocation(
      latitude: location.latitude,
      longitude: location.longitude
    ), completionHandler: { (placemarks, error) -> Void in
      guard error == nil else {
        logGeneral.error("Received error on address serch result: \(String(describing: error)) | \(String(describing: error?.localizedDescription))")
        return
      }
      guard let first = placemarks?.first else { return }
      let order = Place(
        addressTitle: first.name ?? "",
        addressSubTitle: first.formattedAddress ?? "",
        latitude: location.latitude,
        longitude: location.longitude
      )
      DispatchQueue.main.async {
        self.pickedPlaceFromMap = order
        self.searchDisplayStringForMap = "\(order.addressSubTitle)"
      }
    })
  }

  func search(for suggestedCompletion: MKLocalSearchCompletion) {
    let searchRequest = MKLocalSearch.Request(completion: suggestedCompletion)
    search(using: searchRequest)
  }

  private func search(using searchRequest: MKLocalSearch.Request) {
    searchRequest.region = boundingRegion
    searchRequest.resultTypes = .pointOfInterest

    localSearch = MKLocalSearch(request: searchRequest)
    localSearch?.start { [unowned self] response, error in
      guard error == nil else { return }
      guard let item = response?.mapItems.first else { return }
      DispatchQueue.main.async {
        self.pickedPlaceFromList = Place(
          addressTitle: item.name ?? "",
          addressSubTitle: item.placemark.formattedAddress ?? "",
          latitude: item.placemark.coordinate.latitude,
          longitude: item.placemark.coordinate.longitude
        )
      }

      if let updatedRegion = response?.boundingRegion {
        self.boundingRegion = updatedRegion
      }
    }
  }
}

extension LocationSearcher: MKLocalSearchCompleterDelegate {
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    logGeneral.log("Addres search resilts: \(completer.results)")
    searchDataSource = completer.results
  }

  func completer(_: MKLocalSearchCompleter, didFailWithError error: Error) {
    logGeneral.error("Received error on address serch result: \(error) | \(error.localizedDescription)")
  }
}
