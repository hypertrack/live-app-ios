import Foundation

public struct Time {
  public let totalSeconds: Int
  public var years: Int {
    return totalSeconds / 31_536_000
  }

  public var days: Int {
    return (totalSeconds % 31_536_000) / 86400
  }

  public var hours: Int {
    return (totalSeconds % 86400) / 3600
  }

  public var minutes: Int {
    return (totalSeconds % 3600) / 60
  }

  public var seconds: Int {
    return totalSeconds % 60
  }

  public var hoursMinutesAndSeconds: (hours: Int, minutes: Int, seconds: Int) {
    return (hours, minutes, seconds)
  }

  public enum TimeUnit: String {
    case min
    case h
    case sec
  }

  public init(_ totalSeconds: Int) {
    self.totalSeconds = totalSeconds
  }
}

extension Time {
  public var toHourMinOrSecSrting: String {
    let hoursText = timeTextWithoutZero(from: hours, timeUnit: .h)
    let minutesText = timeTextWithoutZero(from: minutes, timeUnit: .min)
    let secText = timeTextWithoutZero(from: seconds, timeUnit: .sec)

    if hours > 0 {
      return "\(hoursText):\(minutesText)"
    } else if minutes > 0 {
      return "\(minutesText)"
    } else {
      return "\(secText)"
    }
  }

  public var toHourMinSecSrting: String {
    let hoursText = timeText(from: hours)
    let minutesText = timeText(from: minutes)
    let secText = timeText(from: seconds)
    return "\(hoursText):\(minutesText):\(secText)"
  }

  public var toSrting: String {
    let hoursText = timeText(from: hours, timeUnit: .h)
    let minutesText = timeText(from: minutes, timeUnit: .min)
    return "\(hoursText)\(minutesText)"
  }

  private func timeText(from number: Int, timeUnit: TimeUnit) -> String {
    if number > 0 {
      return "\(number)\(timeUnit.rawValue)"
    }
    return ""
  }

  private func timeText(from number: Int) -> String {
    if number > 10 {
      return "\(number)"
    } else if number > 0 {
      return "0\(number)"
    }
    return "00"
  }

  private func timeTextWithoutZero(
    from number: Int,
    timeUnit: TimeUnit
  ) -> String {
    return "\(number) \(timeUnit.rawValue)"
  }
}
