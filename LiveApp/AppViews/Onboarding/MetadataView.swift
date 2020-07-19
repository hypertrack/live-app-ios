import HyperTrack
import Model
import Prelude
import Store
import SwiftUI
import ViewsComponents

private final class Input: ObservableObject {
  @Published var name: String = ""
  @Published var phoneNumber: String = ""

  init(name: String, phone: String) {
    self.name = name
    self.phoneNumber = phone
  }
}

struct MetadataView: View {
  @ObservedObject private var inputText: Input

  let hyperTrackData: HyperTrackData
  let hyperTrack: HyperTrack
  var action: () -> Void

  init(
    hyperTrackData: HyperTrackData,
    hyperTrack: HyperTrack,
    action: @escaping () -> Void
  ) {
    self.hyperTrackData = hyperTrackData
    inputText = Input(name: hyperTrackData.name, phone: hyperTrackData.phone)
    self.hyperTrack = hyperTrack
    self.action = action
  }

  var body: some View {
    return GeometryReader { geometry in
      ZStack {
        self.userInfoView(geometry)
      }
      .navigationBarTitle("")
      .navigationBarHidden(true)
      .background(Color("BackgroundColor"))
      .edgesIgnoringSafeArea(.all)
      .modifier(HideKeyboard())
    }
  }

  private func userInfoView(_: GeometryProxy) -> some View {
    return VStack {
      Text("User Name / Phone # (+9111...)")
        .font(
          Font.system(size: 24)
            .weight(.semibold))
        .foregroundColor(Color("TitleColor"))
        .padding(.top, 44)
      Text("Will appear on your trips and in dashboard")
        .font(
          Font.system(size: 14)
            .weight(.medium))
        .foregroundColor(Color(UIColor.tertiary_5_m))
      VStack(alignment: .leading) {
        Text("Name")
          .font(
            Font.system(size: 14)
              .weight(.semibold))
          .foregroundColor(Color(UIColor.tertiary_4_mdark))
        TextField("", text: self.$inputText.name)
          .frame(height: 21)
          .textFieldStyle(LiveTextFieldStyle(
            color: Color(UIColor.tertiary_5_m)
          ))
        Text("Phone number")
          .font(
            Font.system(size: 14)
              .weight(.semibold))
          .foregroundColor(Color(UIColor.tertiary_4_mdark))
          .padding(.top, 33)
        TextField("", text: self.$inputText.phoneNumber)
          .frame(height: 21)
          .textContentType(.telephoneNumber)
          .keyboardType(.phonePad)
          .textFieldStyle(LiveTextFieldStyle(
            color: Color(UIColor.tertiary_5_m)
          ))
        HStack(spacing: 0) {
          Spacer()
          Button(action: {
            self.action()
          }) {
            Text("skip for now")
              .font(
                Font.system(size: 14)
                  .weight(.semibold))
              .foregroundColor(Color(UIColor.tertiary_4_mdark))
          }
          .padding([.bottom, .top], 14)
        }
      }
      .padding([.leading, .trailing], 16)
      .padding(.top, 26)
      HStack {
        Spacer()
        self.nextButton
        Spacer()
      }
      .padding(.top, 30)
      .padding([.trailing, .leading], 64)
      Spacer()
    }.any
  }

  var nextButton: some View {
    Button(action: {
      self.nextAction()
    }) {
      HStack {
        Spacer()
        Text("Next")
          .font(
            Font.system(size: 20)
              .weight(.bold))
        Spacer()
      }
    }
    .buttonStyle(LiveGreenButtonStyle(false))
    .frame(height: 48)
    .disabled(self.isNextButtonEnabled())
  }

  private func nextAction() {
    hyperTrackData.update(.updateName(inputText.name))
    hyperTrackData.update(.updatePhone(inputText.phoneNumber))

    hyperTrack.setDeviceName(inputText.name)
    if let metadata = HyperTrack.Metadata(
      dictionary: [
        Constant.MetadataKeys.phoneKey: self.inputText.phoneNumber,
        Constant.MetadataKeys.nameKey: self.inputText.name
      ]
    ) {
      hyperTrack.setDeviceMetadata(metadata)
    }

    action()
  }

  private func isNextButtonEnabled() -> Bool {
    return
      !(!inputText.name.isEmpty &&
        !inputText.phoneNumber.isEmpty)
  }
}
