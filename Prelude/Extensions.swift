import Combine
import Contacts
import Foundation
import MapKit
import SwiftUI

extension Collection {
  public func distance(to index: Index) -> Int { distance(
    from: startIndex,
    to: index
  ) }
}

extension Date {
  public static func - (lhs: Date, rhs: Date) -> TimeInterval {
    return lhs.timeIntervalSinceReferenceDate - rhs
      .timeIntervalSinceReferenceDate
  }
}

extension JSONDecoder: ConfigurableSelf {
  public static let api = JSONDecoder().configure {
    $0.keyDecodingStrategy = .convertFromSnakeCase
  }
}

// public extension MKPlacemark {
//  var formattedAddress: String? {
//    guard let postalAddress = postalAddress else { return nil }
//    return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress).replacingOccurrences(of: "\n", with: " ")
//  }
// }

public extension CLPlacemark {
  var formattedAddress: String? {
    guard let postalAddress = postalAddress else { return nil }
    return CNPostalAddressFormatter.string(
      from: postalAddress,
      style: .mailingAddress
    ).replacingOccurrences(of: "\n", with: " ")
  }
}

public protocol ConfigurableSelf {}

public extension ConfigurableSelf where Self: AnyObject {
  @discardableResult func configure(_ block: (Self) -> Void) -> Self {
    block(self)
    return self
  }
}

public extension Dictionary {
  subscript(i: Int) -> (key: Key, value: Value) {
    return Array(self)[i]
  }
}

public extension DateFormatter {
  static let iso8601DateFormatter: DateFormatter = {
    let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
    let iso8601DateFormatter = DateFormatter()
    iso8601DateFormatter.locale = enUSPOSIXLocale
    iso8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    iso8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return iso8601DateFormatter
  }()

  static let iso8601MillisecondsDateFormatter: DateFormatter = {
    let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
    let iso8601DateFormatter = DateFormatter()
    iso8601DateFormatter.locale = enUSPOSIXLocale
    iso8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    iso8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return iso8601DateFormatter
  }()

  static let iso8601MicrosecondsDateFormatter: DateFormatter = {
    let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
    let iso8601DateFormatter = DateFormatter()
    iso8601DateFormatter.locale = enUSPOSIXLocale
    iso8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
    iso8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return iso8601DateFormatter
  }()

  static func date(fromISO8601String string: String) -> Date? {
    if let dateWithMicroseconds = iso8601MicrosecondsDateFormatter.date(
      from: string
    ) {
      return dateWithMicroseconds
    }

    if let dateWithMilliseconds = iso8601MillisecondsDateFormatter.date(
      from: string
    ) {
      return dateWithMilliseconds
    }

    if let date = iso8601DateFormatter.date(from: string) {
      return date
    }

    return nil
  }

  static func stringDate(_ date: Date) -> String {
    let dateFormat = DateFormatter()
    dateFormat.locale = Locale(identifier: "en_US_POSIX")
    dateFormat.dateFormat = "h:mm a"
    return dateFormat.string(from: date)
  }
}

public extension String {
  var iso8601: Date? {
    return DateFormatter.date(fromISO8601String: self)
  }
}

public extension UIApplication {
  static var appVersion: String {
    if let version = Bundle.main.object(
      forInfoDictionaryKey: "CFBundleShortVersionString"
    ) as? String {
      return version
    } else {
      return ""
    }
  }
}

public extension Double {
  /// Rounds the double to decimal places value
  func rounded(_ places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return (self * divisor).rounded() / divisor
  }
}
