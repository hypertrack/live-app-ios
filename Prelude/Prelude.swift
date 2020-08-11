import Combine
import CoreLocation
import Foundation
import HyperTrack
import MapKit
import SwiftUI
import UIKit

public func mapViewRegionDidChangeFromUserInteraction(
  _ mapView: MKMapView
) -> Bool {
  let view = mapView.subviews[0]
  //  Look through gesture recognizers to determine
  // whether this region change is from user interaction
  if let gestureRecognizers = view.gestureRecognizers {
    for recognizer in gestureRecognizers {
      if recognizer.state == UIGestureRecognizer.State.began ||
        recognizer.state == UIGestureRecognizer.State.ended {
        return true
      }
    }
  }
  return false
}

/// For hide keyboard needed
public extension UIApplication {
  func endEditing() {
    sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil,
      from: nil,
      for: nil
    )
  }
}

public extension View {
  var any: AnyView { AnyView(self) }
}

/// Object for observing Applications life-cycle notification events
public final class ApplicationStateReceiver {
  @Published public var didEnterBackground: Notification = Notification(
    name: Notification.Name("NONE")
  )
  @Published public var willEnterForeground: Notification = Notification(
    name: Notification.Name("NONE")
  )
  @Published public var didFinishLaunching: Notification = Notification(
    name: Notification.Name("NONE")
  )
  @Published public var didBecomeActive: Notification = Notification(
    name: Notification.Name("NONE")
  )
  @Published public var willTerminate: Notification = Notification(
    name: Notification.Name("NONE")
  )
  @Published public var keyboardWillShow: Notification = Notification(
    name: Notification.Name("NONE")
  )
  @Published public var keyboardWillHide: Notification = Notification(
    name: Notification.Name("NONE")
  )

  private let didEnterBackgroundSubject = PassthroughSubject<
    Notification,
    Never
  >()
  private let willEnterForegroundSubject = PassthroughSubject<
    Notification,
    Never
  >()
  private let didFinishLaunchingSubject = PassthroughSubject<
    Notification,
    Never
  >()

  private let didBecomeActiveSubject = PassthroughSubject<Notification, Never>()
  private let willTerminateSubject = PassthroughSubject<Notification, Never>()
  private let keyboardWillShowSubject = PassthroughSubject<
    Notification,
    Never
  >()
  private let keyboardWillHideSubject = PassthroughSubject<
    Notification,
    Never
  >()
  private var cancellables: [AnyCancellable] = []

  public init() {
    bindInputs()
    bindOutputs()
  }

  private func bindInputs() {
    let didEnterBackgroundPublisher = NotificationCenter.Publisher(
      center: .default, name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
    let willEnterForegroundPublisher = NotificationCenter.Publisher(
      center: .default, name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    let didFinishLaunchingNotification = NotificationCenter.Publisher(
      center: .default, name: UIApplication.didFinishLaunchingNotification,
      object: nil
    )
    let didBecomeActiveNotification = NotificationCenter.Publisher(
      center: .default, name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    let willTerminateNotification = NotificationCenter.Publisher(
      center: .default, name: UIApplication.willTerminateNotification,
      object: nil
    )
    let keyboardWillShowNotification = NotificationCenter.Publisher(
      center: .default, name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    let keyboardWillHideNotification = NotificationCenter.Publisher(
      center: .default, name: UIResponder.keyboardWillHideNotification,
      object: nil
    )

    let didEnterBackgroundInputStream = didEnterBackgroundPublisher
      .share()
      .subscribe(didEnterBackgroundSubject)
    let willEnterForegroundInputStream = willEnterForegroundPublisher
      .share()
      .subscribe(willEnterForegroundSubject)
    let didFinishLaunchingInputStream = didFinishLaunchingNotification
      .share()
      .subscribe(didFinishLaunchingSubject)
    let didBecomeActiveInputStream = didBecomeActiveNotification
      .share()
      .subscribe(didBecomeActiveSubject)
    let willTerminateInputStream = willTerminateNotification
      .share()
      .subscribe(willTerminateSubject)
    let keyboardWillShowInputStream = keyboardWillShowNotification
      .share()
      .subscribe(keyboardWillShowSubject)
    let keyboardWillHideInputStream = keyboardWillHideNotification
      .share()
      .subscribe(keyboardWillHideSubject)

    cancellables += [
      didEnterBackgroundInputStream,
      willEnterForegroundInputStream,
      didFinishLaunchingInputStream,
      didBecomeActiveInputStream,
      willTerminateInputStream,
      keyboardWillHideInputStream,
      keyboardWillShowInputStream
    ]
  }

  private func bindOutputs() {
    let didEnterBackgroundOutputStream = didEnterBackgroundSubject
      .assign(to: \.didEnterBackground, on: self)
    let willEnterForegroundOutputStream = willEnterForegroundSubject
      .assign(to: \.willEnterForeground, on: self)
    let didFinishLaunchingOutputStream = didFinishLaunchingSubject
      .assign(to: \.didFinishLaunching, on: self)
    let didBecomeActiveOutputStream = didBecomeActiveSubject
      .assign(to: \.didBecomeActive, on: self)
    let willTerminateOutputStream = willTerminateSubject
      .assign(to: \.willTerminate, on: self)
    let keyboardWillShowOutputStream = keyboardWillShowSubject
      .assign(to: \.keyboardWillShow, on: self)
    let keyboardWillHideOutputStream = keyboardWillHideSubject
      .assign(to: \.keyboardWillHide, on: self)

    cancellables += [
      didEnterBackgroundOutputStream,
      willEnterForegroundOutputStream,
      didFinishLaunchingOutputStream,
      didBecomeActiveOutputStream,
      willTerminateOutputStream,
      keyboardWillShowOutputStream,
      keyboardWillHideOutputStream
    ]
  }
}

/// Keyboard responder that handles keyboard behaviour
public final class KeyboardResponder: ObservableObject {
  private var center: NotificationCenter
  @Published public private(set) var currentHeight: CGFloat = 0
  @Published public private(set) var curve: UInt = 0
  @Published public private(set) var animationDuration: Double = 0.0
  @Published public private(set) var isKeyboardShown: Bool = false

  public init(center: NotificationCenter = .default) {
    self.center = center
    self.center.addObserver(
      self,
      selector: #selector(keyBoardWillShow(notification:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    self.center.addObserver(
      self,
      selector: #selector(keyBoardWillHide(notification:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
  }

  deinit {
    self.center.removeObserver(self)
  }

  @objc func keyBoardWillShow(notification: Notification) {
    if let keyboardSize = (notification.userInfo?[
      UIResponder.keyboardFrameEndUserInfoKey
    ] as? NSValue)?.cgRectValue {
      currentHeight = keyboardSize.height
    }
    if let curve = (notification.userInfo?[
      UIResponder.keyboardAnimationCurveUserInfoKey
    ] as? UInt) {
      self.curve = curve
    }
    if let number = (notification.userInfo?[
      UIResponder.keyboardAnimationDurationUserInfoKey
    ] as? UInt) {
      animationDuration = Double(number)
    } else {
      animationDuration = 0.25
    }
    isKeyboardShown = true
  }

  @objc func keyBoardWillHide(notification _: Notification) {
    currentHeight = 0
    isKeyboardShown = false
  }
}

/// Provide functionality hide keyboard for SwiftUI
public struct HideKeyboard: ViewModifier {
  public var callback: () -> Void

  public init(callback: @escaping (() -> Void) = {}) {
    self.callback = callback
  }

  public func body(content: Content) -> some View {
    content
      .onTapGesture {
        self.callback()
        self.endEditing()
      }
  }

  private func endEditing() {
    UIApplication.shared.endEditing()
  }
}

public extension Array {
  func removingDuplicates<T: Hashable>(byKey key: KeyPath<Element, T>) -> [
    Element
  ] {
    var result = [Element]()
    var seen = Set<T>()
    for value in self {
      if seen.insert(value[keyPath: key]).inserted {
        result.append(value)
      }
    }
    return result
  }
}

public final class LiveUserDefaults {
  private var defaults: UserDefaults?

  public init() { defaults = UserDefaults() }
}

extension LiveUserDefaults {
  public func object(forKey defaultName: String) -> Any? {
    return defaults?.object(forKey: defaultName)
  }

  public func string(forKey defaultName: String) -> String? {
    return defaults?.string(forKey: defaultName)
  }

  public func array(forKey defaultName: String) -> [Any]? {
    return defaults?.array(forKey: defaultName)
  }

  public func dictionary(forKey defaultName: String) -> [String: Any]? {
    return defaults?.dictionary(forKey: defaultName)
  }

  public func data(forKey defaultName: String) -> Data? {
    return defaults?.data(forKey: defaultName)
  }

  public func stringArray(forKey defaultName: String) -> [String]? {
    return defaults?.stringArray(forKey: defaultName)
  }

  public func integer(forKey defaultName: String) -> Int {
    return defaults?.integer(forKey: defaultName) ?? 0
  }

  public func float(forKey defaultName: String) -> Float {
    return defaults?.float(forKey: defaultName) ?? 0
  }

  public func double(forKey defaultName: String) -> Double {
    return defaults?.double(forKey: defaultName) ?? 0
  }

  public func bool(forKey defaultName: String) -> Bool {
    return defaults?.bool(forKey: defaultName) ?? false
  }

  public func url(forKey defaultName: String) -> URL? {
    return defaults?.url(forKey: defaultName)
  }

  public func set(_ value: Any?, forKey defaultName: String) {
    defaults?.set(value, forKey: defaultName)
  }

  public func removeObject(forKey defaultName: String) {
    defaults?.removeObject(forKey: defaultName)
  }
}

public func convertToDictionary(text: String) -> [String: String]? {
  if let data = text.data(using: .utf8) {
    do {
      return try JSONSerialization.jsonObject(with: data, options: []) as? [
        String: String
      ]
    } catch { }
  }
  return nil
}
