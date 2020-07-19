import Combine
import SwiftUI

struct LiveReadableWithHyperLinkTextView: UIViewRepresentable {
  @Binding var text: String

  init(text: Binding<String>) {
    _text = text
  }

  func makeUIView(context _: Context) -> UITextView {
    let textView = UITextView()
    textView.isScrollEnabled = true
    textView.isEditable = false
    textView.isUserInteractionEnabled = true
    textView.backgroundColor = .clear
    textView.autocorrectionType = .no
    return textView
  }

  func updateUIView(_ uiView: UITextView, context _: Context) {
    let attributedString =
      NSMutableAttributedString(
        string: "By clicking on the Accept & Continue button I agree to Terms of Service and HyperTrack SaaS Agreement",
        attributes: [
          .font: UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium),
          .foregroundColor: UIColor.tertiary_4_mdark
        ]
      )
    attributedString.addAttribute(
      .foregroundColor,
      value: UIColor(
        red: 10.0 / 255.0,
        green: 132.0 / 255.0,
        blue: 1.0,
        alpha: 1.0
      ),
      range: NSRange(location: 55, length: 16)
    )
    attributedString.addAttribute(
      .foregroundColor,
      value: UIColor(
        red: 10.0 / 255.0,
        green: 132.0 / 255.0,
        blue: 1.0,
        alpha: 1.0
      ),
      range: NSRange(location: 76, length: 25)
    )
    attributedString.setAttributes(
      [.link: Constant.HyperLink.termsOfServiceURL],
      range: NSMakeRange(55, 16)
    )
    attributedString.setAttributes(
      [.link: Constant.HyperLink.saaSAgreementURL],
      range: NSMakeRange(76, 25)
    )
    attributedString.addAttribute(
      NSAttributedString.Key.font,
      value: UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium),
      range: NSMakeRange(55, 16)
    )
    attributedString.addAttribute(
      NSAttributedString.Key.font,
      value: UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium),
      range: NSMakeRange(76, 25)
    )

    uiView.attributedText = attributedString
  }
}
