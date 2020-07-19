import SwiftUI

public struct SlideOverCard<Content: View>: View {
  @GestureState private var dragState = DragState.inactive
  @State private var position = CardPosition.bottom
  public var content: (Bool) -> Content

  public init(
    @ViewBuilder content: @escaping (Bool) -> Content
  ) {
    self.content = content
  }

  public var body: some View {
    let drag = DragGesture()
      .updating(self.$dragState) { drag, state, _ in
        state = .dragging(translation: drag.translation)
      }
      .onEnded(self.onDragEnded)
    return ZStack {
      self.content(self.position.offset + self.dragState.translation
        .height < CardPosition.bottom.offset)
    }
    .frame(
      width: UIScreen.main.bounds.width,
      height: UIScreen.main.bounds.height
    )
    .background(Color.white)
    .cornerRadius(10.0)
    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.13), radius: 10.0)
    .offset(
      y: self.position.offset + self.dragState.translation.height < CardPosition
        .top.offset ? logDrag() : linearDrag()
    )
    .animation(self.dragState.isDragging ? nil : .interpolatingSpring(
      stiffness: 300.0,
      damping: 30.0,
      initialVelocity: 10.0
    ))
    .gesture(drag)
  }

  private func linearDrag() -> CGFloat {
    return position.offset + dragState.translation.height
  }

  private func logDrag() -> CGFloat {
    let relativeHeightTranslation = -dragState.translation
      .height - (position.offset - CardPosition.top.offset)
    return (CardPosition.top.offset) - pow(relativeHeightTranslation, 0.7)
  }

  private func onDragEnded(drag: DragGesture.Value) {
    let verticalDirection = drag.predictedEndLocation.y - drag.location.y
    let cardTopEdgeLocation = position.offset + drag.translation.height
    let positionAbove: CardPosition
    let positionBelow: CardPosition
    let closestPosition: CardPosition

    if cardTopEdgeLocation <= CardPosition.middle.offset {
      positionAbove = .top
      positionBelow = .middle
    } else {
      positionAbove = .middle
      positionBelow = .bottom
    }

    if (cardTopEdgeLocation - positionAbove.offset) <
      (positionBelow.offset - cardTopEdgeLocation) {
      closestPosition = positionAbove
    } else {
      closestPosition = positionBelow
    }

    if verticalDirection > 0 {
      position = positionBelow
    } else if verticalDirection < 0 {
      position = positionAbove
    } else {
      position = closestPosition
    }
  }
}

enum CardPosition: Double {
  case top = 0.9
  case middle = 0.5
  case bottom = 0.201

  var offset: CGFloat {
    let screenHeight = UIScreen.main.bounds.height
    return screenHeight - (screenHeight * CGFloat(rawValue))
  }
}

enum DragState {
  case inactive
  case dragging(translation: CGSize)

  var translation: CGSize {
    switch self {
      case .inactive:
        return .zero
      case let .dragging(translation):
        return translation
    }
  }

  var isDragging: Bool {
    switch self {
      case .inactive:
        return false
      case .dragging:
        return true
    }
  }
}
