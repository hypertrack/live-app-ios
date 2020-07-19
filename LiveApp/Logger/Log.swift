import struct Foundation.Data
import class Foundation.NSJSONSerialization.JSONSerialization
import class Foundation.NSURLResponse.HTTPURLResponse
import struct Foundation.URLRequest

import class os.log.OSLog
import struct os.log.OSLogType
import func os.os_log

func logFor(subsystem: String) -> (_ category: String) -> Log {
  return { Logger(subsystem: subsystem, category: $0) }
}

protocol Log {
  func log(_ logString: String, file: String, function: String, line: Int)
  func info(_ logString: String, file: String, function: String, line: Int)
  func trace(file: String, function: String, line: Int)
  func debug(_ logString: String, file: String, function: String, line: Int)
  func error(_ logString: String, file: String, function: String, line: Int)
  func fault(_ logString: String, file: String, function: String, line: Int)
}

extension Log {
  func log(
    _ logString: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    return log(logString, file: file, function: function, line: line)
  }

  func info(
    _ logString: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    return info(logString, file: file, function: function, line: line)
  }

  func trace(
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    return trace(file: file, function: function, line: line)
  }

  func debug(
    _ logString: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    return debug(logString, file: file, function: function, line: line)
  }

  func error(
    _ logString: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    return debug(logString, file: file, function: function, line: line)
  }

  func fault(
    _ logString: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    return debug(logString, file: file, function: function, line: line)
  }
}

@available(iOS 10.0, *)
struct Logger: Log {
  let osLog: OSLog

  init(subsystem: String, category: String) {
    osLog = OSLog(subsystem: subsystem, category: category)
  }

  func log(_ logString: String, file: String, function: String, line: Int) {
    osLog.log(logString, file: file, function: function, line: line)
  }

  func info(_ logString: String, file: String, function: String, line: Int) {
    osLog.info(logString, file: file, function: function, line: line)
  }

  func trace(file: String, function: String, line: Int) {
    osLog.trace(file: file, function: function, line: line)
  }

  func debug(_ logString: String, file: String, function: String, line: Int) {
    osLog.debug(logString, file: file, function: function, line: line)
  }

  func error(_ logString: String, file: String, function: String, line: Int) {
    osLog.error(logString, file: file, function: function, line: line)
  }

  func fault(_ logString: String, file: String, function: String, line: Int) {
    osLog.fault(logString, file: file, function: function, line: line)
  }
}

extension Optional {
  var description: String {
    switch self {
      case let .some(value):
        var result = ""
        print(value, terminator: "", to: &result)
        return result
      case .none:
        return "nil"
    }
  }
}

func log(_ any: Any) -> String {
  var prettyPrint: String = ""
  dump(any, to: &prettyPrint)
  return prettyPrint
}

let prettyPrintedOptionalNone = "nil"

func headerReduer(
  sum: String,
  header: (key: AnyHashable, value: Any)
) -> String {
  return sum + "\n\(header.key): \(header.value)"
}

func prettyPrintHTTPURLResponseHeaders(
  _ headers: [AnyHashable: Any]
) -> String {
  return headers.reduce("", headerReduer)
}

func prettyPrintURLRequestHeaders(_ headers: [String: String]) -> String {
  return headers.reduce("", headerReduer)
}

func prettyPrintURLRequest(_ request: URLRequest?) -> String {
  switch request {
    case .none:
      return prettyPrintedOptionalNone
    case let .some(urlRequest):
      let httpHeaders: String
      if let headers = urlRequest.allHTTPHeaderFields {
        httpHeaders = prettyPrintURLRequestHeaders(headers)
      } else {
        httpHeaders = "Empty headers"
      }
      var body = "Empty body"
      if let requestBody = urlRequest.httpBody {
        if let parsedBody = prettyPrintJSONData(requestBody) {
          body = parsedBody
        } else if let parsedBody = String(data: requestBody, encoding: .utf8) {
          body = parsedBody
        }
      }
      let string = """

      \(urlRequest.httpMethod ?? "UNKNOWN HTTP METHOD") \(urlRequest.url?
                                        .absoluteString ?? "https://unknown.url")
      \("Headers: \n\(httpHeaders)")
      \(body)

      """
      return string
  }
}

func prettyPrintHTTPURLResponse(_ response: HTTPURLResponse?) -> String {
  switch response {
    case .none:
      return prettyPrintedOptionalNone
    case let .some(httpURLResponse):
      let headers = prettyPrintHTTPURLResponseHeaders(httpURLResponse
        .allHeaderFields)

      let string = """

      \("Status code: \(httpURLResponse.statusCode)")
      \("Headers: \n\(headers)")

      """
      return string
  }
}

func prettyPrintJSONData(_ jsonData: Data) -> String? {
  guard let object = try? JSONSerialization
    .jsonObject(with: jsonData, options: []),
    let data = try? JSONSerialization
    .data(withJSONObject: object, options: [.prettyPrinted]),
    let prettyPrintedString = String(data: data, encoding: .utf8)
    else { return nil }
  return prettyPrintedString
}

@available(iOS 10.0, *)
extension OSLog {
  @inlinable
  func log(_ value: String, file: String, function: String, line: Int) {
    _log(
      value: value,
      file: file,
      function: function,
      line: line,
      type: .default
    )
  }

  @inlinable
  func info(_ value: String, file: String, function: String, line: Int) {
    #if targetEnvironment(simulator)
      // @workaround for simulator bug in Xcode 10.2 and earlier:
      // https://forums.developer.apple.com/thread/82736#348090
      let type = OSLogType.default
    #else
      let type = OSLogType.info
    #endif
    _log(value: value, file: file, function: function, line: line, type: type)
  }

  @inlinable
  func trace(file: String, function: String, line: Int) {
    #if targetEnvironment(simulator)
      // @workaround for simulator bug in Xcode 10.2 and earlier:
      // https://forums.developer.apple.com/thread/82736#348090
      let type = OSLogType.default
    #else
      let type = OSLogType.debug
    #endif
    _log(
      value: "<OSLog.trace>",
      file: file,
      function: function,
      line: line,
      type: type
    )
  }

  @inlinable
  func debug(_ value: String, file: String, function: String, line: Int) {
    #if targetEnvironment(simulator)
      // @workaround for simulator bug in Xcode 10.2 and earlier:
      // https://forums.developer.apple.com/thread/82736#348090
      let type = OSLogType.default
    #else
      let type = OSLogType.debug
    #endif
    _log(value: value, file: file, function: function, line: line, type: type)
  }

  @inlinable
  func error(_ value: String, file: String, function: String, line: Int) {
    _log(value: value, file: file, function: function, line: line, type: .error)
  }

  @inlinable
  func fault(_ value: String, file: String, function: String, line: Int) {
    _log(value: value, file: file, function: function, line: line, type: .fault)
  }

  @usableFromInline
  // swiftlint:disable:next identifier_name
  func _log(
    value: String,
    file: String,
    function: String,
    line: Int,
    type: OSLogType
  ) {
    let filename = file.split(separator: "/").last
      .flatMap { String($0) } ?? file
    os_log(
      "%{public}@ %{public}@ Line %ld: %{public}@",
      log: self,
      type: type,
      filename,
      function,
      line,
      value
    )
  }
}
