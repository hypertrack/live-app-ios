import SwiftUI

struct LiveTextField: UIViewRepresentable {
  class Coordinator: NSObject, UITextFieldDelegate {
    @Binding var text: String
    let placeholder: String

    init(placeholder: String, text: Binding<String>) {
      _text = text
      self.placeholder = placeholder
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
      text = textField.text ?? ""
    }
  }

  @Binding var text: String
  @Binding var isFirstResponder: Bool
  let placeholder: String

  init(
    text: Binding<String>,
    isFirstResponder: Binding<Bool>,
    placeholder: String
  ) {
    _text = text
    _isFirstResponder = isFirstResponder
    self.placeholder = placeholder
  }

  func makeUIView(context: UIViewRepresentableContext<LiveTextField>)
    -> UITextField {
    let textField = UITextField(frame: .zero)
    textField.placeholder = placeholder
    textField.autocorrectionType = .no
    textField.spellCheckingType = .no
    textField.smartQuotesType = .no
    textField.smartDashesType = .no
    textField.smartInsertDeleteType = .no
    textField.delegate = context.coordinator
    textField.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    return textField
  }

  func makeCoordinator() -> LiveTextField.Coordinator {
    return Coordinator(placeholder: placeholder, text: $text)
  }

  func updateUIView(
    _ uiView: UITextField,
    context _: UIViewRepresentableContext<LiveTextField>
  ) {
    uiView.text = text
    if isFirstResponder, uiView.canBecomeFirstResponder {
      uiView.becomeFirstResponder()
    }
  }
}
