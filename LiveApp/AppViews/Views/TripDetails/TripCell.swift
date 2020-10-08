import HyperTrackViews
import SwiftUI

struct TripCell: View {
  let trip: MovementStatus.Trip
  let isSelected: Bool
  var action: (MovementStatus.Trip) -> Void

  var body: some View {
    GeometryReader { geometry in
      VStack(alignment: .leading, spacing: 0) {
        Text(isDestinationEmpty(self.trip) ? "Trip started from" : "Trip to")
          .font(
            Font.system(size: 14)
              .weight(.bold))
          .foregroundColor(Color("TitleColor"))
          .padding(.top, 8)
          .padding([.leading, .trailing], 12)
        HStack(spacing: 0.0) {
          Image(isDestinationEmpty(self.trip) ? "icTripDepartureA" : "arrivalA")
          Text(isDestinationEmpty(self.trip) ? getTripStartedTime(self.trip) :
            getStartAddress(self.trip))
            .lineLimit(1)
            .font(
              Font.system(size: 18)
                .weight(.regular))
            .foregroundColor(Color("TitleColor"))
            .padding(.leading, 4)
        }
        .padding(.top, 4)
        .padding([.leading, .trailing], 16)
        Rectangle()
          .fill(Color("DividerColor"))
          .frame(width: geometry.size.width, height: 0.5)
          .padding(.top, 10)
      }
      .frame(width: geometry.size.width)
      .background(self
        .isSelected ? Color("CellSelectedBackgroundColor") :
        Color("CardBackgroundColor"))
      .animation(nil)
      .simultaneousGesture(
        TapGesture().onEnded { _ in
          self.action(self.trip)
        }
      )
    }
  }
}
