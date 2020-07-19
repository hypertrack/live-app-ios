import SwiftUI

public struct SideMenuConfig {
  public var menuBGColor: Color
  public var menuBGOpacity: Double
  public var menuWidth: CGFloat
  public var animationDuration: Double

  public init(
    menuBGColor: Color = .black,
    menuBGOpacity: Double = 0.3,
    menuWidth: CGFloat = 300,
    animationDuration: Double = 0.3
  ) {
    self.menuBGColor = menuBGColor
    self.menuBGOpacity = menuBGOpacity
    self.menuWidth = menuWidth
    self.animationDuration = animationDuration
  }
}

public struct SideMenu: View {
  public init<Menu: View>(
    leftMenu: Menu, isLeftPanelShow: Binding<Bool>,
    config: SideMenuConfig = SideMenuConfig()
  ) {
    self.leftMenu = AnyView(leftMenu)
    _isLeftPanelShow = isLeftPanelShow
    self.config = config
  }

  private var leftMenu: AnyView?
  private var config: SideMenuConfig
  private var menuAnimation: Animation {
    .easeOut(duration: config.animationDuration)
  }

  @State private var leftMenuBGOpacity: Double = 0
  @State private var leftMenuOffsetX: CGFloat = 0
  @State private var sideMenuGestureMode: SideMenuGestureMode = SideMenuGestureMode.active
  @Binding private var isLeftPanelShow: Bool

  public var body: some View {
    return GeometryReader { geometry in
      ZStack(alignment: .top) {
        if self.isLeftPanelShow && self.leftMenu != nil {
          MenuBackgroundView(
            sideMenuLeftPanel: self.$isLeftPanelShow,
            bgColor: self.config.menuBGColor
          )
          .frame(
            width: geometry.size.width,
            height: geometry.size.height
          )
          .opacity(self.leftMenuBGOpacity)
          .zIndex(1)
          self.leftMenu!
            .edgesIgnoringSafeArea(Edge.Set.all)
            .frame(
              width: self.config.menuWidth,
              height: geometry.size.height
            )
            .offset(x: self.leftMenuOffsetX, y: 0)
            .transition(.move(edge: Edge.leading))
            .zIndex(2)
        }
      }
      .gesture(self.panelDragGesture(geometry.size.width))
      .animation(self.menuAnimation)
      .onAppear {
        self.leftMenuOffsetX = -self.menuXOffset(geometry.size.width)
        self.leftMenuBGOpacity = self.config.menuBGOpacity
      }
      .environment(\.horizontalSizeClass, .compact)
    }
  }

  private func panelDragGesture(_ screenWidth: CGFloat) -> _EndedGesture<
    _ChangedGesture<DragGesture>
  >? {
    if sideMenuGestureMode == SideMenuGestureMode.inactive {
      return nil
    }
    return DragGesture()
      .onChanged { value in
        self.onChangedDragGesture(value: value, screenWidth: screenWidth)
      }
      .onEnded { value in
        self.onEndedDragGesture(value: value, screenWidth: screenWidth)
      }
  }

  private func menuXOffset(_ screenWidth: CGFloat) -> CGFloat {
    return (screenWidth - config.menuWidth) / 2
  }

  func onChangedDragGesture(value: DragGesture.Value, screenWidth: CGFloat) {
    let startLocX = value.startLocation.x
    let translation = value.translation
    let translationWidth = translation.width > 0 ? translation.width : -translation.width
    let leftMenuGesturePositionX = screenWidth * 0.1

    guard translationWidth <= config.menuWidth else { return }

    if isLeftPanelShow, value.dragDirection == .left, leftMenu != nil {
      let newXOffset = -menuXOffset(screenWidth) - translationWidth
      leftMenuOffsetX = newXOffset

      let translationPercentage = (config.menuWidth - translationWidth) / config.menuWidth
      guard translationPercentage > 0 else { return }
      leftMenuBGOpacity = config.menuBGOpacity * Double(translationPercentage)
    } else if startLocX < leftMenuGesturePositionX, value.dragDirection == .right, leftMenu != nil {
      if !isLeftPanelShow {
        isLeftPanelShow.toggle()
      }

      let defaultOffset = -(menuXOffset(screenWidth) + config.menuWidth)
      let newXOffset = defaultOffset + translationWidth
      leftMenuOffsetX = newXOffset
      let translationPercentage = translationWidth / config.menuWidth

      guard translationPercentage > 0 else { return }

      leftMenuBGOpacity = config.menuBGOpacity * Double(translationPercentage)
    }
  }

  func onEndedDragGesture(value _: DragGesture.Value, screenWidth: CGFloat) {
    let midXPoint = (0.5 * config.menuWidth)
    if isLeftPanelShow, leftMenu != nil {
      let leftMenuMidX = -menuXOffset(screenWidth) - midXPoint
      if leftMenuOffsetX < leftMenuMidX {
        isLeftPanelShow.toggle()
      }
      leftMenuOffsetX = -menuXOffset(screenWidth)
      leftMenuBGOpacity = config.menuBGOpacity
    }
  }
}

struct MenuBackgroundView: View {
  @Binding var sideMenuLeftPanel: Bool
  let bgColor: Color

  var body: some View {
    Rectangle()
      .fill(bgColor)
      .transition(.opacity)
      .onTapGesture {
        withAnimation {
          if self.sideMenuLeftPanel {
            self.sideMenuLeftPanel.toggle()
          }
        }
      }
      .edgesIgnoringSafeArea(Edge.Set.all)
  }
}

public enum SideMenuGestureMode {
  case active
  case inactive
}

enum DragDirection {
  case left
  case right
  case up
  case down
}

extension DragGesture.Value {
  var dragDirection: DragDirection {
    if startLocation.x > location.x {
      return DragDirection.left
    } else if startLocation.x < location.x {
      return DragDirection.right
    } else if startLocation.y < location.y {
      return DragDirection.up
    } else {
      return DragDirection.down
    }
  }
}
