import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var dockController: AccordLiquidDockWindowController?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    guard let window,
          let flutterViewController = window.rootViewController as? FlutterViewController else {
      return
    }
    dockController = AccordLiquidDockWindowController(
      window: window,
      messenger: flutterViewController.binaryMessenger
    )
  }
}

private struct AccordLiquidDockItem: Hashable {
  let id: String
  let active: Bool
  let primary: Bool
  let showBadge: Bool
  let allowLongPress: Bool
}

private final class AccordLiquidDockWindowController {
  private let overlayView: AccordLiquidDockOverlayView

  init(window: UIWindow, messenger: FlutterBinaryMessenger) {
    overlayView = AccordLiquidDockOverlayView(messenger: messenger)
    window.addSubview(overlayView)
    window.bringSubviewToFront(overlayView)
    NSLayoutConstraint.activate([
      overlayView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
      overlayView.trailingAnchor.constraint(equalTo: window.trailingAnchor),
      overlayView.bottomAnchor.constraint(equalTo: window.bottomAnchor),
      overlayView.heightAnchor.constraint(equalToConstant: 120),
    ])
  }
}

private final class AccordLiquidDockOverlayView: UIView, UITabBarDelegate {
  private let channel: FlutterMethodChannel
  private let tabBar = UITabBar()
  private var items: [AccordLiquidDockItem] = []

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "accord_liquid_dock_runtime", binaryMessenger: messenger)
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    isUserInteractionEnabled = false
    isHidden = true
    setup()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setup() {
    addSubview(tabBar)
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    tabBar.isUserInteractionEnabled = true
    tabBar.delegate = self
    tabBar.tintColor = UIColor.white.withAlphaComponent(0.98)
    tabBar.unselectedItemTintColor = UIColor.white.withAlphaComponent(0.72)
    if #available(iOS 26.0, *) {
      tabBar.itemPositioning = .automatic
    } else {
      tabBar.itemPositioning = .centered
      tabBar.itemWidth = 64
      tabBar.itemSpacing = 8
    }

    if #available(iOS 26.0, *) {
      let appearance = UITabBarAppearance()
      appearance.configureWithDefaultBackground()
      appearance.shadowColor = .clear
      tabBar.standardAppearance = appearance
      tabBar.scrollEdgeAppearance = appearance
    } else if #available(iOS 15.0, *) {
      let appearance = UITabBarAppearance()
      appearance.configureWithDefaultBackground()
      appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
      appearance.backgroundColor = UIColor.white.withAlphaComponent(0.04)
      appearance.shadowColor = .clear
      tabBar.standardAppearance = appearance
      tabBar.scrollEdgeAppearance = appearance
    } else {
      tabBar.barStyle = .black
      tabBar.isTranslucent = true
    }

    NSLayoutConstraint.activate([
      tabBar.centerXAnchor.constraint(equalTo: centerXAnchor),
      tabBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
      tabBar.heightAnchor.constraint(equalToConstant: 64),
      tabBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
      tabBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
    ])

    layer.zPosition = 999
    tabBar.layer.zPosition = 1000

    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleTabBarLongPress(_:)))
    longPress.minimumPressDuration = 0.65
    tabBar.addGestureRecognizer(longPress)
  }

  private func handle(call: FlutterMethodCall, result: FlutterResult) {
    guard call.method == "updateDock" else {
      result(FlutterMethodNotImplemented)
      return
    }

    let args = call.arguments as? [String: Any] ?? [:]
    let visible = args["visible"] as? Bool ?? false
    isHidden = !visible
    isUserInteractionEnabled = visible
    if !visible {
      items = []
      tabBar.items = []
      result(nil)
      return
    }

    let rawItems = args["items"] as? [[String: Any]] ?? []
    items = rawItems.compactMap { item in
      guard let id = item["id"] as? String else { return nil }
      return AccordLiquidDockItem(
        id: id,
        active: item["active"] as? Bool ?? false,
        primary: item["primary"] as? Bool ?? false,
        showBadge: item["showBadge"] as? Bool ?? false,
        allowLongPress: item["allowLongPress"] as? Bool ?? false
      )
    }

    let tabItems = items.enumerated().map { index, item in
      let tabBarItem = UITabBarItem(
        title: nil,
        image: UIImage(systemName: iconName(for: item, selected: false)),
        selectedImage: UIImage(systemName: iconName(for: item, selected: true))
      )
      tabBarItem.tag = index
      tabBarItem.badgeValue = item.showBadge ? " " : nil
      tabBarItem.badgeColor = UIColor(red: 1.0, green: 0.25, blue: 0.28, alpha: 1.0)
      tabBarItem.imageInsets = UIEdgeInsets(top: 10, left: 0, bottom: -10, right: 0)
      tabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 1000)
      return tabBarItem
    }

    tabBar.setItems(tabItems, animated: false)
    if let activeIndex = items.firstIndex(where: { $0.active }),
       let activeItem = tabBar.items?[activeIndex] {
      tabBar.selectedItem = activeItem
    } else {
      tabBar.selectedItem = nil
    }

    result(nil)
  }

  private func iconName(for item: AccordLiquidDockItem, selected: Bool) -> String {
    switch item.id {
      case "home":
        return selected ? "house.fill" : "house"
      case "notifications":
        return selected ? "bell.fill" : "bell"
      case "profile":
        return selected ? "person.crop.circle.fill" : "person.crop.circle"
      case "recent":
        return selected ? "clock.fill" : "clock"
      case "suppliers":
        return selected ? "person.2.fill" : "person.2"
      case "activity":
        return selected ? "waveform.path.ecg.rectangle.fill" : "waveform.path.ecg.rectangle"
      case "create":
        return item.primary ? "plus.circle.fill" : "plus"
      default:
        return selected ? "circle.fill" : "circle"
    }
  }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    guard items.indices.contains(item.tag) else { return }
    channel.invokeMethod("tap", arguments: ["id": items[item.tag].id])
  }

  @objc private func handleTabBarLongPress(_ recognizer: UILongPressGestureRecognizer) {
    guard recognizer.state == .began else { return }
    let location = recognizer.location(in: tabBar)
    let buttons = tabBar.subviews
      .compactMap { $0 as? UIControl }
      .sorted { $0.frame.minX < $1.frame.minX }

    for (index, button) in buttons.enumerated() where button.frame.contains(location) {
      guard items.indices.contains(index) else { continue }
      let item = items[index]
      if item.allowLongPress {
        channel.invokeMethod("longPress", arguments: ["id": item.id])
      }
      return
    }
  }
}
