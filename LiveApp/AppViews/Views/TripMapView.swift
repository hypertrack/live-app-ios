import HyperTrackViews
import MapKit
import Prelude
import SwiftUI

struct TripMapView: UIViewRepresentable {
  @Binding var movementStatus: MovementStatus?
  @Binding var isAutoZoomEnabled: Bool

  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    mapView.showsUserLocation = false
    mapView.showsCompass = false
    mapView.isRotateEnabled = false
    return mapView
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func updateUIView(_ uiView: MKMapView, context _: Context) {
    guard let movementStatus = self.movementStatus,
      let trip = movementStatus.trips.first else { return }
    put(.locationWithTrip(movementStatus.location, trip), onMapView: uiView)
    isZoomNeeded(uiView)
  }

  class Coordinator: NSObject, MKMapViewDelegate {
    var control: TripMapView

    init(_ control: TripMapView) {
      self.control = control
    }

    func mapView(
      _ mapView: MKMapView,
      viewFor annotation: MKAnnotation
    ) -> MKAnnotationView? {
      return annotationViewForAnnotation(annotation, onMapView: mapView)
    }

    func mapView(
      _: MKMapView,
      rendererFor overlay: MKOverlay
    ) -> MKOverlayRenderer {
      return rendererForOverlay(overlay)!
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

  private func isZoomNeeded(_ mapView: MKMapView) {
    if isAutoZoomEnabled {
      zoom(
        withMapInsets: .all(100),
        interfaceInsets: .custom(
          top: 10,
          leading: 25,
          bottom: 250,
          trailing: 25
        ),
        onMapView: mapView
      )
    }
  }
}
