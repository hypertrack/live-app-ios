import Combine
import Foundation
import Model
import Prelude
import SwiftUI

protocol RequestProviding {
  var urlRequest: URLRequest { get }
}

protocol APISessionProviding {
  func execute(_ requestProvider: RequestProviding)
    -> AnyPublisher<Void, Error>

  func execute<T: Decodable>(_ requestProvider: RequestProviding)
    -> AnyPublisher<
      T,
      Error
    >
}

struct ApiSession: APISessionProviding {
  func validate(
    _ data: Data,
    _ response: URLResponse,
    decoder: JSONDecoder
  ) throws -> Data {
    logNetwork
      .log("Executed request with data:\n\(prettyPrintJSONData(data) ?? String(decoding: data, as: UTF8.self))")
    guard let httpResponse = response as? HTTPURLResponse else {
      logNetwork.error("Received empty response")
      throw LiveError.emptyResult
    }
    guard (200 ..< 300).contains(httpResponse.statusCode) else {
      logNetwork
      .error("Failed to execute a request with response: \(prettyPrintHTTPURLResponse(httpResponse))")

      if let error = try? decoder.decode(
        APIErrorResponse.self,
        from: data
      ) {
        logNetwork.error("Decoded error: \(error.message)")
      }
      throw LiveError(httpErrorCode: httpResponse.statusCode)
    }
    logNetwork
      .log("Executed request with response: \(prettyPrintHTTPURLResponse(httpResponse))")
    return data
  }

  func execute<T>(_ requestProvider: RequestProviding)
    -> AnyPublisher<T, Error> where T: Decodable {
    logNetwork
      .log("Executing request: \(prettyPrintURLRequest(requestProvider.urlRequest))")
    return URLSession.shared.dataTaskPublisher(for: requestProvider.urlRequest)
      .mapError { LiveError(httpErrorCode: $0.errorCode) }
      .tryMap { try self.validate(
        $0.data,
        $0.response,
        decoder: JSONDecoder.api
      ) }
      .decode(type: T.self, decoder: JSONDecoder())
      .eraseToAnyPublisher()
  }

  func execute(_ requestProvider: RequestProviding)
    -> AnyPublisher<Void, Error> {
    logNetwork
      .log("Executing request with empty response: \(prettyPrintURLRequest(requestProvider.urlRequest))")
    return URLSession.shared.dataTaskPublisher(for: requestProvider.urlRequest)
      .map { _ in Void() }
      .mapError { LiveError(httpErrorCode: $0.errorCode) }
      .eraseToAnyPublisher()
  }
}
