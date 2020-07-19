import Combine
import Network
import SwiftUI

final class ReachabilityMonitor: ObservableObject {
  private var monitor: NWPathMonitor = NWPathMonitor()
  @Published var isReachable: Bool = true

  init() {
    monitor.start(queue: DispatchQueue.global(qos: .default))
  }
}

extension ReachabilityMonitor {
  func startMonitoring() {
    logNetwork.log("Internet monitoring started")
    monitor.pathUpdateHandler = { path in
      logInternetConnection(path: path)
      DispatchQueue.main.async {
        switch path.status {
          case .satisfied:
            logReachability
              .log("Reachability: The path is available to establish connections and send data.")
            self.isReachable = true
          case .unsatisfied:
            logReachability.log("Reachability: The path is not available for use.")
            self.isReachable = false
          case .requiresConnection:
            logReachability
              .log("Reachability: The path is not currently available, but establishing a new connection may activate the path.")
            self.isReachable = false
          @unknown default:
            logReachability
              .fault("Reachability: Reachability is in an unknown state, crashing.")
        }
      }
    }
  }

  func cancel() {
    monitor.cancel()
  }
}

private func logInternetConnection(path: NWPath) {
  logNetwork.log("Available interfaces: \(path.availableInterfaces)")
  logNetwork.log("Gateways: \(path.gateways)")
  logNetwork.log("interface in Low Data Mode: \(path.isConstrained)")
  logNetwork.log("interface is expensive: \(path.isExpensive)")
  logNetwork.log("Local endpoint: \(String(describing: path.localEndpoint))")
  logNetwork.log("Remote endpoint: \(String(describing: path.remoteEndpoint))")
  logNetwork.log("Internet connection status: \(path.status)")
  logNetwork.log("Supports DNS: \(path.supportsDNS)")
  logNetwork.log("Supports IPv4: \(path.supportsIPv4)")
  logNetwork.log("Supports IPv6: \(path.supportsIPv6)")

  if path.usesInterfaceType(.wifi) {
    logNetwork.log("Uses interface type: WI-FI")
  }

  if path.usesInterfaceType(.cellular) {
    logNetwork.log("Uses interface type: cellular")
  }

  if path.usesInterfaceType(.loopback) {
    logNetwork.log("Uses interface type: loopback")
  }

  if path.usesInterfaceType(.wiredEthernet) {
    logNetwork.log("Uses interface type: wiredEthernet")
  }

  if path.usesInterfaceType(.other) {
    logNetwork.log("Uses interface type: other")
  }
}
