import MapKit
import Model
import Prelude
import SwiftUI

struct AddressCell: View {
  var model: MKLocalSearchCompletion
  var action: (MKLocalSearchCompletion) -> Void

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0.0) {
        HStack(spacing: 0) {
          Image("location")
            .padding(.leading, 20)
            .padding([.top, .bottom], 18)
          VStack(alignment: .leading) {
            Text(self.model.title)
              .font(
                Font.system(size: 14)
                  .weight(.medium))
              .foregroundColor(Color("CellTitleColor"))
            Text(self.model.subtitle)
              .font(
                Font.system(size: 12)
                  .weight(.medium))
              .foregroundColor(Color(UIColor.tertiary_5_m))
          }
          .padding([.leading, .trailing], 16)
        }
        .frame(width: geometry.size.width, height: 64, alignment: .leading)
        .background(Color("BackgroundColor"))
        .onTapGesture {
          self.action(self.model)
        }
        Divider()
          .background(Color("DividerBackgroundColor"))
          .padding([.leading, .trailing], 16)
      }
    }
  }
}

struct HistoryAddressCell: View {
  var model: Place
  var action: (Place) -> Void

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0.0) {
        HStack(spacing: 0) {
          Image("History")
            .padding(.leading, 20)
            .padding([.top, .bottom], 18)
          VStack(alignment: .leading) {
            Text(self.model.addressTitle)
              .font(
                Font.system(size: 14)
                  .weight(.medium))
              .foregroundColor(Color("CellTitleColor"))
            Text(self.model.addressSubTitle)
              .font(
                Font.system(size: 12)
                  .weight(.medium))
              .foregroundColor(Color(UIColor.tertiary_5_m))
          }
          .padding([.leading, .trailing], 16)
        }
        .frame(width: geometry.size.width, height: 64, alignment: .leading)
        .background(Color("BackgroundColor"))
        .onTapGesture {
          self.action(self.model)
        }
        Divider()
          .background(Color("DividerBackgroundColor"))
          .padding([.leading, .trailing], 16)
      }
    }
  }
}

struct AddressHomeCell: View {
  var model: Place?
  var onCellTap: (Place?) -> Void
  var onCreateHomeAddress: () -> Void
  var onEdit: () -> Void

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0.0) {
        HStack(spacing: 0) {
          Image("home_icon")
            .padding(.leading, 20)
            .padding([.top, .bottom], 18)
          if self.isPlaceModelExist(self.model) {
            HStack {
              VStack(alignment: .leading) {
                Text(self.model?.addressTitle ?? "")
                  .font(
                    Font.system(size: 14)
                      .weight(.medium))
                  .foregroundColor(Color("CellTitleColor"))
                Text(self.model?.addressSubTitle ?? "")
                  .font(
                    Font.system(size: 12)
                      .weight(.medium))
                  .foregroundColor(Color(UIColor.tertiary_5_m))
              }
              .onTapGesture {
                self.onCellTap(self.model)
              }
              Spacer()
              Image("edit")
                .onTapGesture {
                  self.onEdit()
                }
            }
            .padding([.leading, .trailing], 16)
          } else {
            Text("Set home address")
              .font(
                Font.system(size: 14)
                  .weight(.medium))
              .foregroundColor(Color("CellTitleColor"))
              .padding(.leading, 20)
          }
        }
        .frame(width: geometry.size.width, height: 64, alignment: .leading)
        .background(Color("BackgroundColor"))
        .onTapGesture {
          self.onCreateHomeAddress()
        }
        Divider()
          .background(Color("DividerBackgroundColor"))
          .padding([.leading, .trailing], 16)
      }
    }
  }

  private func isPlaceModelExist(_ model: Place?) -> Bool {
    guard let uModel = model else {
      return false
    }
    if uModel.latitude == 0, uModel.longitude == 0 {
      return false
    }
    return true
  }
}
