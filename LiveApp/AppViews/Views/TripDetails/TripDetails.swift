import HyperTrackViews
import Model
import Prelude
import SwiftUI
import ViewsComponents

struct TripDetails: View {
  private var selectedTrip: MovementStatus.Trip? {
    let trip = hyperTrackUpdater.userMovementStatus?.trips
      .filter { $0.id == self.inputData.tripId }
    return trip?.first
  }

  private var tripList: [MovementStatus.Trip] {
    if let trips = hyperTrackUpdater.userMovementStatus?.trips {
      return Array(trips).sorted {
        $0.startedAt < $1.startedAt
      }
    } else {
      return []
    }
  }

  @State private var selectedIndex: Int?
  @State private var isRemovedViewActive: Bool = false

  private let hyperTrackUpdater: HyperTrackUpdater
  private let inputData: HyperTrackData
  private var endButtonAction: () -> Void
  private var shareButtonAction: () -> Void

  init(
    hyperTrackUpdater: HyperTrackUpdater,
    inputData: HyperTrackData,
    endButtonAction: @escaping () -> Void,
    shareButtonAction: @escaping () -> Void
  ) {
    self.hyperTrackUpdater = hyperTrackUpdater
    self.inputData = inputData
    self.endButtonAction = endButtonAction
    self.shareButtonAction = shareButtonAction
    _selectedIndex = State(initialValue: getSelectedIndex())
  }

  var body: some View {
    GeometryReader { geometry in
      SlideOverCard { isSafeZoneContentVisible in
        VStack(spacing: 0) {
          VStack(spacing: 0) {
            Handle()
            if self.isRemovedViewActive {
              self.tripEndCard()
            } else {
              self.tripCard(geometry)
            }
            HStack {
              Text("You have \(self.hyperTrackUpdater.userMovementStatus?.trips.count ?? 0) ongoing \((self.hyperTrackUpdater.userMovementStatus?.trips.count ?? 0 > 1) ? "trips" : "trip")")
                .foregroundColor(Color(UIColor.tertiary_4_mdark))
                .font(
                  Font.system(size: 12)
                    .weight(.regular))
              Spacer()
            }
            .padding(.leading, 12)
            .padding(.top, 21)
            Rectangle()
              .fill(Color("DividerColor"))
              .frame(width: geometry.size.width, height: 0.5)
              .padding(.top, 4)
              .opacity(isSafeZoneContentVisible ? 1 : 0)
          }
          .frame(width: geometry.size.width)
          ForEach(0 ..< self.tripList.count, id: \.self) { i in
            TripCell(
              trip: self.tripList[i],
              isSelected: i == self.selectedIndex
            ) {
              self.selectedIndex = i
              self.inputData.update(.insertTripId($0.id))
              self.hyperTrackUpdater
                .createMovementStatusWithSelectedTripSubscription()
            }
            .frame(height: 64)
            .listRowInsets(EdgeInsets())
          }
          .opacity(isSafeZoneContentVisible ? 1 : 0)
          Spacer()
        }
        .frame(width: geometry.size.width)
        .background(Color("CardBackgroundColor"))
      }
    }
  }

  private func tripCard(_ geometry: GeometryProxy) -> some View {
    return VStack(spacing: 0.0) {
      HStack {
        VStack(alignment: .leading, spacing: 0) {
          Text(isDestinationEmpty(self.selectedTrip) ? "Trip strated from" :
            "Trip to")
            .font(
              Font.system(size: 14)
                .weight(.bold))
            .foregroundColor(Color("TitleColor"))
          HStack(spacing: 0.0) {
            Image(isDestinationEmpty(self.selectedTrip) ? "icTripDepartureA" :
              "arrivalA")
            Text(isDestinationEmpty(self.selectedTrip) ?
              getTripStartedTime(self.selectedTrip) :
              getStartAddress(self.selectedTrip))
              .lineLimit(1)
              .font(
                Font.system(size: 18)
                  .weight(.regular))
              .foregroundColor(Color("TitleColor"))
              .padding(.leading, 4)
          }
          .padding(.leading, 4)
        }
        .padding(.leading, 12)
        .padding(.top, 5)
        Spacer()
        Button(action: {
          self.isRemovedViewActive.toggle()
        }) {
          Text("End")
            .padding([.top, .bottom], 10)
            .padding([.leading, .trailing], 26)
        }
        .foregroundColor(Color.white)
        .background(Color(UIColor.context_3))
        .cornerRadius(4)
        .padding(.trailing, 12)
        .padding(.top, 8)
      }
      .frame(width: geometry.size.width)
      .animation(nil)
      ZStack {
        HStack(spacing: 0.0) {
          Image("Clock")
            .padding(.leading, 16)
          VStack(alignment: .leading, spacing: 0.0) {
            Text(isDestinationEmpty(self.selectedTrip) ?
              getTripCurrentDuration(self.selectedTrip) :
              getTripArrivedAtDate(self.selectedTrip))
              .font(
                Font.system(size: 18)
                  .weight(.regular))
              .foregroundColor(Color("TitleColor"))
            Text(isDestinationEmpty(self.selectedTrip) ? "Tracking" : tripArrivedStringStatus(self.selectedTrip))
              .font(
                Font.system(size: 12)
                  .weight(.regular))
              .foregroundColor(isEstimateIrrelevant(self.selectedTrip) ? Color(UIColor.context_3) : Color(UIColor.tertiary_4_mdark))
          }
          .padding(.leading, 4)
          VStack(alignment: .leading, spacing: 0.0) {
            Text(getTripAwayDuration(self.selectedTrip))
              .font(
                Font.system(size: 18)
                  .weight(.regular))
              .foregroundColor(Color("TitleColor"))
            Text(isEstimateIrrelevant(self.selectedTrip) ? "" : "Away")
              .font(
                Font.system(size: 12)
                  .weight(.regular))
              .foregroundColor(Color(UIColor.tertiary_4_mdark))
          }
          .opacity(isDestinationEmpty(self.selectedTrip) ? 0.0 :
            isTripArrived(self.selectedTrip) ? 0.0 : 1.0)
          .padding(.leading, 26)
          Spacer()
        }
        .padding(.top, 5)
        .frame(width: geometry.size.width)
        HStack {
          Spacer()
          Button(action: {
            self.shareButtonAction()
          }) {
            Text(isDestinationEmpty(self.selectedTrip) ? "Share ETA" : "Share trip")
              .font(
                Font.system(size: 16)
                  .weight(.bold))
              .foregroundColor(Color(UIColor.clearBlue))
          }
          .padding(.top, 18)
          .padding(.trailing, 12)
        }
      }
      .animation(nil)
      .frame(width: geometry.size.width)
    }
  }

  private func tripEndCard() -> some View {
    return VStack(spacing: 0.0) {
      HStack {
        Button(action: {
          self.isRemovedViewActive.toggle()
        }) {
          Spacer()
          Text("Resume")
            .font(
              Font.system(size: 15)
                .weight(.bold))
            .foregroundColor(Color(UIColor.clearBlue))
          Spacer()
        }
        .frame(height: 40)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(
          Color(UIColor.clearBlue),
          lineWidth: 1
        ))
        Spacer()
          .frame(width: 8)
        Button(action: {
          self.endButtonAction()
        }) {
          Spacer()
          Text("End trip")
            .font(
              Font.system(size: 15)
                .weight(.bold))
            .foregroundColor(Color(UIColor.white))
          Spacer()
        }
        .frame(height: 40)
        .background(Color(UIColor.context_3))
        .cornerRadius(4)
      }
      .padding(.top, 8)
      .padding([.leading, .trailing], 8)
      Spacer()
    }
    .frame(height: 91)
    .background(Color.clear)
  }

  private func getSelectedIndex() -> Int? {
    if let tripIndex = tripList.firstIndex(
      where: { $0.id == self.inputData.tripId }
    ) {
      return tripList.distance(to: tripIndex)
    } else {
      return nil
    }
  }
}

func isDestinationEmpty(_ trip: MovementStatus.Trip?) -> Bool {
  return trip?.destination == nil
}

func getStartAddress(_ trip: MovementStatus.Trip?) -> String {
  let htAddress = trip?.destination?.address
  let htCoordinate = trip?.destination?.coordinate

  if let address = htAddress, !address.isEmpty {
    return address
  } else if let coordinate = htCoordinate {
    return "\(coordinate.latitude), \(coordinate.longitude)"
  } else {
    return "No address"
  }
}

func getTripStartedTime(_ trip: MovementStatus.Trip?) -> String {
  if let trip = trip {
    return DateFormatter.stringDate(trip.startedAt)
  } else {
    return "No trip found"
  }
}

func getTripCurrentDuration(_ trip: MovementStatus.Trip?) -> String {
  let currentDate = Date().timeIntervalSince1970
  let startedAtDate = trip?.startedAt.timeIntervalSince1970 ?? 0
  let diff = currentDate - startedAtDate
  return Time(Int(diff)).toHourMinSecSrting
}

func getTripAwayDuration(_ trip: MovementStatus.Trip?) -> String {
  if let trip = trip {
    var tripRemainingDuration: UInt32?
    if let estimate = trip.destination?.estimate {
      switch estimate {
        case let .relevant(route):
          tripRemainingDuration = route.remainingDuration
        default:
          tripRemainingDuration = nil
      }
    }

    if let remainingDuration = tripRemainingDuration, remainingDuration == 0 {
      return "Arrived"
    } else if let remainingDuration = tripRemainingDuration {
      return Time(Int(remainingDuration)).toHourMinOrSecSrting
    } else {
      return ""
    }
  } else {
    return "No trip found"
  }
}

func getTripArrivedAtDate(_ trip: MovementStatus.Trip?) -> String {
  if let trip = trip {
    var tripRemainingDuration: UInt32?
    if let estimate = trip.destination?.estimate {
      switch estimate {
        case let .relevant(route):
          tripRemainingDuration = route.remainingDuration
        default:
          tripRemainingDuration = nil
      }
    }
    if let arrivedAtDate = trip.destination?.arrivedAt {
      return DateFormatter.stringDate(arrivedAtDate)
    } else if let remainingDuration = tripRemainingDuration {
      return DateFormatter.stringDate(Date().addingTimeInterval(TimeInterval(remainingDuration)))
    } else {
      return "ETA unavailable"
    }
  } else {
    return "No trip found"
  }
}

func isTripArrived(_ trip: MovementStatus.Trip?) -> Bool {
  if let trip = trip {
    if let _ = trip.destination?.arrivedAt {
      return true
    } else {
      return false
    }
  } else {
    return false
  }
}

func tripArrivedStringStatus(_ trip: MovementStatus.Trip?) -> String {
  if let trip = trip {
    if let _ = trip.destination?.arrivedAt {
      return "Arrived at"
    } else if let estimate = trip.destination?.estimate {
      switch estimate {
        case .relevant: return "Arrival"
        case let .irrelevant(reason): return reason
        default: return "Arrival"
      }
    } else {
      return "Arrival"
    }
  } else {
    return "Arrival"
  }
}

func isEstimateIrrelevant(_ trip: MovementStatus.Trip?) -> Bool {
  if let trip = trip {
    if let estimate = trip.destination?.estimate {
      switch estimate {
        case .relevant: return false
        case .irrelevant: return true
        case .generating: return false
      }
    } else {
      return false
    }
  } else {
    return false
  }
}
