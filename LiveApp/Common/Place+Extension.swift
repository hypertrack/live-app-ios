import Model

extension Place {
  func convertToPayload() -> Payload {
    var payload: Payload = [:]
    let geometry: Payload = [
      Constant.ServerKeys.Trip.type: "Point",
      Constant.ServerKeys.Trip.coordinates: [
        longitude,
        latitude
      ]
    ]
    payload[Constant.ServerKeys.Trip.destination] = [
      Constant.ServerKeys.Trip.geometry: geometry
    ]
    return payload
  }
  
  func convertToGeofencePayload() -> Payload {
    
    let metadata: Payload = [
      Constant.ServerKeys.Geofence.metadataKey: "Home",
    ]
    
    let geometry: Payload = [Constant.ServerKeys.Geofence.geometry :
      [
        Constant.ServerKeys.Geofence.type: "Point",
        Constant.ServerKeys.Geofence.coordinates: [
          longitude,
          latitude
        ]
      ],
      Constant.ServerKeys.Geofence.radius: Constant.GeofenceSettings.geofenceRadius,
      Constant.ServerKeys.Geofence.metadata: metadata
    ]
    
    return [
      Constant.ServerKeys.Geofence.geofences: [geometry]
    ]
  }
}
