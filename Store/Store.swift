import Foundation

public final class Store<Value, Action>: ObservableObject {
  private let reducer: (inout Value, Action) -> Void
  @Published
  public private(set) var value: Value

  public init(
    initialValue: Value,
    reducer: @escaping (inout Value, Action) -> Void
  ) {
    self.reducer = reducer
    value = initialValue
  }

  public func update(_ action: Action) {
    reducer(&value, action)
  }
}
