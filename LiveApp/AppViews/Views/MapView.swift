import Foundation
import MapKit
import Prelude
import SwiftUI
import ViewsComponents

struct MapView: UIViewRepresentable {
  @Binding var isAutoZoomEnabled: Bool

  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    mapView.showsUserLocation = true
    mapView.showsCompass = false
    mapView.isRotateEnabled = false
    mapView.tintColor = UIColor.primary_1
    return mapView
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func updateUIView(_ uiView: MKMapView, context _: Context) {
    isZoomNeeded(uiView, uiView.userLocation)
  }

  class Coordinator: NSObject, MKMapViewDelegate {
    var control: MapView

    init(_ control: MapView) {
      self.control = control
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
      control.isZoomNeeded(mapView, userLocation)
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated _: Bool) {
      if control.isAutoZoomEnabled {
        DispatchQueue.main.async {
          self.control
            .isAutoZoomEnabled =
            !mapViewRegionDidChangeFromUserInteraction(mapView)
        }
      }
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated _: Bool) {
      if control.isAutoZoomEnabled {
        DispatchQueue.main.async {
          self.control
            .isAutoZoomEnabled =
            !mapViewRegionDidChangeFromUserInteraction(mapView)
        }
      }
    }
  }

  private func isZoomNeeded(
    _ mapView: MKMapView,
    _ userLocation: MKUserLocation
  ) {
    if userLocation.coordinate.latitude != -180,
      userLocation.coordinate.longitude != -180 {
      if isAutoZoomEnabled {
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(
          center: userLocation.coordinate,
          span: span
        )
        mapView.setRegion(region, animated: true)
      }
    }
  }
}
