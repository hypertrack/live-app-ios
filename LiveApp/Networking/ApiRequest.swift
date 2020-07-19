import Combine
import struct CoreLocation.CLLocationCoordinate2D
import Model
import SwiftUI

struct ApiRequest: RequestProviding {
  var urlRequest: URLRequest

  init(_ endpoint: APIEndpoint) {
    self.urlRequest = URLRequest(url: endpoint.url)
    self.urlRequest.httpMethod = endpoint.method.rawValue
    self.urlRequest.httpBody = endpoint.body
    for (header, value) in endpoint.headers {
      self.urlRequest.setValue(value, forHTTPHeaderField: header)
    }
  }
}
