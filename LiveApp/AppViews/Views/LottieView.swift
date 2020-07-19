import Foundation
import Lottie
import SwiftUI
import UIKit

struct LottieView: View {
  var isBlurEnabled: Bool

  init(isBlurEnabled: Bool = false) {
    self.isBlurEnabled = isBlurEnabled
  }

  var body: some View {
    VStack {
      HStack {
        Spacer()
      }
      Spacer()
      Lottie()
        .frame(width: 70, height: 70)
      Spacer()
    }
    .edgesIgnoringSafeArea(.all)
    .background(self.isBlurEnabled ? Blur().any : Color("AlertBackgroundColor").any)
  }
}

struct Lottie: UIViewRepresentable {
  private let animationView = AnimationView()
  private var filename: String = "loading"

  func makeUIView(context _: UIViewRepresentableContext<Lottie>) -> UIView {
    let view = UIView()

    let animation = Animation.named(filename)
    animationView.translatesAutoresizingMaskIntoConstraints = false
    animationView.animation = animation
    animationView.contentMode = .scaleAspectFit
    animationView.loopMode = .loop
    animationView.play()

    view.addSubview(animationView)

    NSLayoutConstraint.activate([
      animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
      animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
    ])

    return view
  }

  func updateUIView(
    _ uiView: UIView,
    context _: UIViewRepresentableContext<Lottie>
  ) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject {
    var control: Lottie

    init(_ control: Lottie) {
      self.control = control

      super.init()

      NotificationCenter.default.addObserver(
        self,
        selector: #selector(playLottie),
        name: UIApplication.didBecomeActiveNotification,
        object: nil
      )
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(stopLottie),
        name: UIApplication.didEnterBackgroundNotification,
        object: nil
      )
    }

    @objc private func playLottie() {
      control.animationView.play()
    }

    @objc private func stopLottie() {
      control.animationView.stop()
    }

    deinit {
      NotificationCenter.default.removeObserver(self)
    }
  }
}

struct Blur: UIViewRepresentable {
  var style: UIBlurEffect.Style = .systemMaterial
  func makeUIView(context _: Context) -> UIVisualEffectView {
    return UIVisualEffectView(effect: UIBlurEffect(style: style))
  }

  func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
    uiView.effect = UIBlurEffect(style: style)
  }
}
