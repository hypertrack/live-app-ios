import CoreLocation.CLLocation
import UIKit

enum Constant {
  static let namespace = "io.hypertrack.SendETA-iPhone.Utility"

  enum AWS {
    static let configuration: [String: Any] = [
      "IdentityManager": [
        "Default": [:]
      ],
      "CognitoUserPool": [
        "Default": [
          "PoolId": "us-west-2_HMxGvgUyF",
          "AppClientId": "7n7mfrkmvb8am9d1n3e79mcdsd",
          "Region": "us-west-2"
        ]
      ]
    ]
  }

  enum Notification {
    enum LiveError {
      static let key = "live.error"
      static let name = Constant.namespace + key
    }

    enum LiveDeepLink {
      static let key = "live.deeplink"
      static let name = Constant.namespace + key
    }
  }

  enum Network {
    static let timeoutInterval: Double = 60
    static let baseURL = "https://live-app-backend.htprod.hypertrack.com"
    static let htBaseUrl = "https://live-api.htprod.hypertrack.com"
    static let trips: String = "/client/trips"
    static let tripComplete: String = "/complete"
    static let geofence: String = "/client/geofences"
    static let getDeepLink: String = "/client/deep_link/live"
    static let authenticate: String = "/authenticate"
    static let devices: String = "/client/devices"
    static let apiKey: String = "/api-key"
    static let start: String = "/start"
    static let stop: String = "/stop"
    static let masterAccount: String = "/client/account_name/"
  }

  enum LocationTrackingSettings {
    static let geofenceRadius: CLLocationDistance = 100.0
    static let coordinatePrecisionPlaces = 6
  }
  
  enum GeofenceSettings {
    static let geofenceRadius = 100.0
  }

  enum ServerKeys {
    enum PublishableKey {
      static let key = "key"
    }

    enum Geofence {
      static let geofences = "geofences"
      static let geometry = "geometry"
      static let type = "type"
      static let coordinates = "coordinates"
      static let radius = "radius"
      static let deviceId = "device_id"
      static let metadataKey = "name"
      static let metadata = "metadata"
    }
    
    enum Trip {
      static let deviceId = "device_id"
      static let destination = "destination"
      static let geometry = "geometry"
      static let type = "type"
      static let coordinates = "coordinates"
    }

    enum SignUp {
      static let companyNameKey = "custom:company"

      static let appGoalKey = "custom:use_case"
      static let appDeviceCountKey = "custom:scale"
      static let appProductStateKey = "custom:state"

      static let workforceKey = "workforce"
      static let logisticsKey = "logistics"
      static let gigWorkKey = "gig_work"
      static let onDemandDeliveryKey = "on_demand_delivery"
      static let ridesharingKey = "ridesharing"
      static let otherKey = "other"

      static let commercialUseKey = "commercial_use"
      static let covidResponseKey = "covid_response"
      static let personalUseKey = "personal_use"
      static let publicGoodKey = "public_good"

      static let myWorkforceKey = "my_workforce"
      static let myCustomersKey = "my_customers"
      static let consumersKey = "consumers"
    }
  }

  enum MetadataKeys {
    static let phoneKey = "user_phone"
    static let nameKey = "user_name"
  }

  enum HyperLink {
    static let termsOfServiceURL = URL(
      string: "https://www.hypertrack.com/terms"
    )!
    static let saaSAgreementURL = URL(
      string: "https://www.hypertrack.com/agreement"
    )!
  }
}
