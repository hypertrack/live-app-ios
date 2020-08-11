import CoreLocation.CLLocation
import Foundation
import Prelude

/// Order place stuct
public struct Place {
  public let id: String
  public let latitude: Double
  public let longitude: Double
  public let addressTitle: String
  public let addressSubTitle: String
  
  public init(
    id: String = UUID().uuidString,
    addressTitle: String,
    addressSubTitle: String,
    latitude: CLLocationDegrees,
    longitude: CLLocationDegrees
  ) {
    self.id = id
    self.addressTitle = addressTitle
    self.addressSubTitle = addressSubTitle
    self.latitude = latitude
    self.longitude = longitude
  }
}

extension Place: Codable {}
extension Place: Hashable {}
extension Place {
  public static func getArray(
    _ defaults: LiveUserDefaults,
    forKey defaultName: String
  ) -> [Place] {
    do {
      guard let addressModelData = defaults.data(forKey: defaultName) else { return [
      ] }
      return try JSONDecoder().decode([Place].self, from: addressModelData)
    } catch {
      return []
    }
  }

  public static func setArray(
    _ defaults: LiveUserDefaults,
    _ value: [Place],
    forKey defaultName: String
  ) {
    do {
      let removeDuplicate = value.removingDuplicates(byKey: \.addressTitle)
      let data = try JSONEncoder().encode(removeDuplicate)
      defaults.set(data, forKey: defaultName)
    } catch {}
  }

  public static func retrievePlace(
    _ defaults: LiveUserDefaults,
    forKey defaultName: String
  ) -> Place? {
    do {
      guard let addressModelData = defaults.data(forKey: defaultName) else { return nil }
      return try JSONDecoder().decode(Place.self, from: addressModelData)
    } catch {
      return nil
    }
  }

  public static func savePlace(
    _ place: Place?,
    _ defaults: LiveUserDefaults,
    forKey defaultName: String
  ) {
    if place == nil {
      defaults.removeObject(forKey: defaultName)
      return
    }
    guard let place = place else {
      return
    }
    do {
      let data = try JSONEncoder().encode(place)
      defaults.set(data, forKey: defaultName)
    } catch { }
  }
}
