import Combine
import Prelude
import Store
import SwiftUI

public struct MultilineTextView: UIViewRepresentable {
  @Binding public var text: String
  public var keyAction: (() -> Void)?

  public init(text: Binding<String>, keyAction: (() -> Void)? = nil) {
    _text = text
    self.keyAction = keyAction
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  public func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
    textView.delegate = context.coordinator
    textView.isScrollEnabled = true
    textView.isEditable = true
    textView.isUserInteractionEnabled = true
    textView.backgroundColor = .clear
    textView.autocorrectionType = .no
    textView.returnKeyType = UIReturnKeyType.next
    return textView
  }

  public func updateUIView(_ uiView: UITextView, context _: Context) {
    uiView.text = text
  }

  public final class Coordinator: NSObject, UITextViewDelegate {
    public var parent: MultilineTextView

    public init(_ uiTextView: MultilineTextView) {
      parent = uiTextView
    }

    public func textView(
      _ textView: UITextView,
      shouldChangeTextIn _: NSRange,
      replacementText text: String
    ) -> Bool {
      if text == "\n" {
        parent.keyAction?()
        return false
      }
      return true
    }

    public func textViewDidChange(_ textView: UITextView) {
      parent.text = textView.text
    }
  }
}
