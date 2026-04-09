import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var deviceInfoBridge: DeviceInfoChannelBridge?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    if let window, let flutterViewController = window.rootViewController as? FlutterViewController {
      deviceInfoBridge = DeviceInfoChannelBridge(messenger: flutterViewController.binaryMessenger)
    }
  }
}

final class NativeBackNavigationController: UINavigationController {
  private let rootFlutterViewController: FlutterViewController
  private var backButtonVisible = false
  private var navigationBarVisible = false
  private var backGestureActive = false
  private lazy var deviceInfoBridge = DeviceInfoChannelBridge(
    messenger: flutterBinaryMessenger
  )
  private lazy var dockController = NativeTabBarController(
    messenger: flutterBinaryMessenger
  )
  private lazy var backBridge = NativeBackButtonChannelBridge(
    messenger: flutterBinaryMessenger,
    onVisibilityChanged: { [weak self] visible in
      self?.setBackButtonVisible(visible)
    },
    onNavigationBarVisibilityChanged: { [weak self] visible in
      self?.setNavigationBarVisible(visible)
    },
    onTitleChanged: { [weak self] title in
      self?.setNavigationTitle(title)
    },
    onThemeChanged: { [weak self] isDark in
      self?.applyNavigationAppearance(isDark: isDark)
    },
    onGestureChanged: { [weak self] active in
      self?.setBackGestureActive(active)
    }
  )

  private var flutterBinaryMessenger: FlutterBinaryMessenger {
    rootFlutterViewController.binaryMessenger
  }

  init(flutterViewController: FlutterViewController) {
    self.rootFlutterViewController = flutterViewController
    super.init(rootViewController: flutterViewController)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    _ = backBridge
    _ = deviceInfoBridge
    navigationBar.prefersLargeTitles = false
    applyNavigationAppearance(isDark: true)
    topViewController?.navigationItem.leftBarButtonItem = makeBackBarButtonItem()
    setNavigationBarHidden(true, animated: false)
    configureDockController()
  }

  private func applyNavigationAppearance(isDark: Bool) {
    let titleColor: UIColor = isDark ? .white : .black
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.backgroundColor = .clear
    appearance.shadowColor = .clear
    appearance.titleTextAttributes = [
      .foregroundColor: titleColor,
    ]
    appearance.largeTitleTextAttributes = [
      .foregroundColor: titleColor,
    ]
    navigationBar.standardAppearance = appearance
    navigationBar.scrollEdgeAppearance = appearance
    navigationBar.compactAppearance = appearance
    navigationBar.tintColor = titleColor
    overrideUserInterfaceStyle = isDark ? .dark : .light
  }

  private func setBackButtonVisible(_ visible: Bool) {
    if visible == backButtonVisible {
      if visible {
        restoreBackButtonAppearance(animated: true)
      }
      return
    }

    backButtonVisible = visible
    backGestureActive = false

    if visible {
      topViewController?.navigationItem.leftBarButtonItem = makeBackBarButtonItem()
      setNavigationBarHidden(false, animated: false)
      navigationBar.layoutIfNeeded()
      guard let buttonView = currentBackButtonView() else {
        return
      }
      buttonView.alpha = 0
      buttonView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
      UIView.animate(
        withDuration: 0.18,
        delay: 0,
        options: [.beginFromCurrentState, .curveEaseOut]
      ) {
        buttonView.alpha = 1
        buttonView.transform = .identity
      }
      return
    }

    guard let buttonView = currentBackButtonView() else {
      topViewController?.navigationItem.leftBarButtonItem = nil
      setNavigationBarHidden(!(navigationBarVisible || backButtonVisible), animated: false)
      return
    }
    UIView.animate(
      withDuration: 0.16,
      delay: 0,
      options: [.beginFromCurrentState, .curveEaseInOut]
    ) {
      buttonView.alpha = 0
      buttonView.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
    } completion: { _ in
      self.topViewController?.navigationItem.leftBarButtonItem = nil
      self.setNavigationBarHidden(!(self.navigationBarVisible || self.backButtonVisible), animated: false)
      buttonView.alpha = 1
      buttonView.transform = .identity
    }
  }

  private func setNavigationBarVisible(_ visible: Bool) {
    navigationBarVisible = visible
    if !visible {
      topViewController?.navigationItem.title = nil
      navigationBar.topItem?.title = nil
    }
    setNavigationBarHidden(!(navigationBarVisible || backButtonVisible), animated: false)
  }

  private func setBackGestureActive(_ active: Bool) {
    backGestureActive = active
    guard backButtonVisible, let buttonView = currentBackButtonView() else {
      return
    }
    UIView.animate(
      withDuration: active ? 0.12 : 0.16,
      delay: 0,
      options: [.beginFromCurrentState, .curveEaseOut]
    ) {
      buttonView.alpha = active ? 0.72 : 1
      buttonView.transform = active
        ? CGAffineTransform(scaleX: 0.94, y: 0.94)
        : .identity
    }
  }

  private func restoreBackButtonAppearance(animated: Bool) {
    guard let buttonView = currentBackButtonView() else {
      return
    }
    let animations = {
      buttonView.alpha = 1
      buttonView.transform = .identity
    }
    if animated {
      UIView.animate(
        withDuration: 0.16,
        delay: 0,
        options: [.beginFromCurrentState, .curveEaseOut],
        animations: animations
      )
    } else {
      animations()
    }
  }

  private func currentBackButtonView() -> UIView? {
    topViewController?.navigationItem.leftBarButtonItem?.value(forKey: "view") as? UIView
  }

  private func setNavigationTitle(_ title: String?) {
    topViewController?.navigationItem.title = title
    navigationBar.topItem?.title = title
  }

  private func makeBackBarButtonItem() -> UIBarButtonItem {
    let configuration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
    let image = UIImage(systemName: "chevron.backward", withConfiguration: configuration)
    return UIBarButtonItem(
      image: image,
      style: .plain,
      target: self,
      action: #selector(handleBackButtonTap)
    )
  }

  @objc
  private func handleBackButtonTap() {
    backBridge.sendBackPressed()
  }

  private func configureDockController() {
    addChild(dockController)
    dockController.view.translatesAutoresizingMaskIntoConstraints = false
    dockController.view.backgroundColor = .clear
    view.addSubview(dockController.view)
    NSLayoutConstraint.activate([
      dockController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      dockController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      dockController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      dockController.view.heightAnchor.constraint(equalToConstant: 126),
    ])
    dockController.didMove(toParent: self)
  }
}

private final class NativeBackButtonChannelBridge: NSObject {
  private let channel: FlutterMethodChannel
  private let onVisibilityChanged: (Bool) -> Void
  private let onNavigationBarVisibilityChanged: (Bool) -> Void
  private let onTitleChanged: (String?) -> Void
  private let onThemeChanged: (Bool) -> Void
  private let onGestureChanged: (Bool) -> Void

  init(
    messenger: FlutterBinaryMessenger,
    onVisibilityChanged: @escaping (Bool) -> Void,
    onNavigationBarVisibilityChanged: @escaping (Bool) -> Void,
    onTitleChanged: @escaping (String?) -> Void,
    onThemeChanged: @escaping (Bool) -> Void,
    onGestureChanged: @escaping (Bool) -> Void
  ) {
    self.channel = FlutterMethodChannel(
      name: "accord/native_back_button",
      binaryMessenger: messenger
    )
    self.onVisibilityChanged = onVisibilityChanged
    self.onNavigationBarVisibilityChanged = onNavigationBarVisibilityChanged
    self.onTitleChanged = onTitleChanged
    self.onThemeChanged = onThemeChanged
    self.onGestureChanged = onGestureChanged
    super.init()
    channel.setMethodCallHandler(handleMethodCall)
    channel.invokeMethod("nativeBackButtonReady", arguments: nil)
  }

  func sendBackPressed() {
    channel.invokeMethod("nativeBackPressed", arguments: nil)
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setBackButtonVisible":
      let visible = (call.arguments as? Bool) ?? false
      DispatchQueue.main.async {
        self.onVisibilityChanged(visible)
      }
      result(nil)
    case "setNavigationBarVisible":
      let visible = (call.arguments as? Bool) ?? false
      DispatchQueue.main.async {
        self.onNavigationBarVisibilityChanged(visible)
      }
      result(nil)
    case "setBackButtonTitle":
      let title = call.arguments as? String
      DispatchQueue.main.async {
        self.onTitleChanged(title)
      }
      result(nil)
    case "setBackButtonIsDark":
      let isDark = (call.arguments as? Bool) ?? true
      DispatchQueue.main.async {
        self.onThemeChanged(isDark)
      }
      result(nil)
    case "setBackButtonGestureActive":
      let active = (call.arguments as? Bool) ?? false
      DispatchQueue.main.async {
        self.onGestureChanged(active)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

final class NativeTabBarController: UITabBarController, UITabBarControllerDelegate {
  private lazy var dockBridge = NativeDockChannelBridge(
    messenger: messenger,
    onStateChanged: { [weak self] state in
      self?.applyDockState(state)
    }
  )
  private let messenger: FlutterBinaryMessenger
  private var currentState = NativeDockState(arguments: [:])
  private var placeholderControllers: [NativeTabPlaceholderViewController] = []
  private var isApplyingState = false
  private var supportsLiquidDock: Bool {
    if #available(iOS 26.0, *) {
      return true
    }
    return false
  }

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    delegate = self
    view.backgroundColor = .clear
    view.isHidden = true
    setSystemTabBarHidden(true)
    _ = dockBridge
    if #available(iOS 18.0, *) {
      mode = .tabBar
    }
  }

  private func applyDockState(_ state: NativeDockState) {
    isApplyingState = true
    defer { isApplyingState = false }

    guard supportsLiquidDock else {
      view.isHidden = true
      setSystemTabBarHidden(true)
      return
    }

    if currentState == state {
      return
    }

    currentState = state
    let tabItems = state.items

    guard state.visible, !tabItems.isEmpty else {
      view.isHidden = true
      setSystemTabBarHidden(true)
      return
    }

    syncPlaceholders(with: tabItems)
    view.isHidden = false

    if let selectedIndex = tabItems.firstIndex(where: \.active) {
      if self.selectedIndex != selectedIndex {
        self.selectedIndex = selectedIndex
      }
    } else if selectedIndex >= tabItems.count {
      self.selectedIndex = 0
    }

    setSystemTabBarHidden(false)
  }

  private func syncPlaceholders(with items: [NativeDockItem]) {
    let existingIds = placeholderControllers.map(\.itemId)
    let newIds = items.map(\.id)
    if existingIds != newIds {
      placeholderControllers = items.map(NativeTabPlaceholderViewController.init)
      viewControllers = placeholderControllers
    }

    for (index, item) in items.enumerated() {
      let controller = placeholderControllers[index]
      controller.update(with: item)
    }
  }

  private func setSystemTabBarHidden(_ hidden: Bool) {
    if #available(iOS 18.0, *) {
      setTabBarHidden(hidden, animated: false)
    } else {
      tabBar.isHidden = hidden
    }
  }

  func tabBarController(
    _ tabBarController: UITabBarController,
    didSelect viewController: UIViewController
  ) {
    guard let placeholder = viewController as? NativeTabPlaceholderViewController else {
      return
    }
    guard !isApplyingState else {
      return
    }
    dockBridge.sendTap(id: placeholder.itemId)
  }
}

private final class NativeTabPlaceholderViewController: UIViewController {
  private(set) var itemId: String
  private let stableTabBarItem = UITabBarItem()

  init(item: NativeDockItem) {
    itemId = item.id
    super.init(nibName: nil, bundle: nil)
    tabBarItem = stableTabBarItem
    update(with: item)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }

  func update(with item: NativeDockItem) {
    itemId = item.id
    let imageConfig = UIImage.SymbolConfiguration(
      pointSize: item.primary ? 19 : 17,
      weight: item.primary ? .bold : .semibold
    )
    stableTabBarItem.title = nil
    stableTabBarItem.image = UIImage(systemName: item.symbol, withConfiguration: imageConfig)
    stableTabBarItem.selectedImage = UIImage(
      systemName: item.selectedSymbol ?? item.symbol,
      withConfiguration: imageConfig
    )
    stableTabBarItem.badgeValue = item.showBadge ? " " : nil
    if item.primary {
      stableTabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 100)
      stableTabBarItem.imageInsets = UIEdgeInsets(top: -1, left: 0, bottom: 1, right: 0)
    } else {
      stableTabBarItem.titlePositionAdjustment = .zero
      stableTabBarItem.imageInsets = .zero
    }
  }
}

private final class NativeDockChannelBridge: NSObject {
  private let channel: FlutterMethodChannel
  private let onStateChanged: (NativeDockState) -> Void

  init(
    messenger: FlutterBinaryMessenger,
    onStateChanged: @escaping (NativeDockState) -> Void
  ) {
    self.channel = FlutterMethodChannel(
      name: "accord/native_dock",
      binaryMessenger: messenger
    )
    self.onStateChanged = onStateChanged
    super.init()
    channel.setMethodCallHandler(handleMethodCall)
    let isSupported: Bool
    if #available(iOS 26.0, *) {
      isSupported = true
    } else {
      isSupported = false
    }
    channel.invokeMethod("nativeDockReady", arguments: isSupported)
  }

  func sendTap(id: String) {
    channel.invokeMethod("nativeDockTap", arguments: id)
  }

  func sendLongPress(id: String) {
    channel.invokeMethod("nativeDockLongPress", arguments: id)
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setDockState":
      let state = NativeDockState(arguments: call.arguments as? [String: Any] ?? [:])
      DispatchQueue.main.async {
        self.onStateChanged(state)
      }
      result(nil)
    case "isSystemDockSupported":
      if #available(iOS 26.0, *) {
        result(true)
      } else {
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

private struct NativeDockState: Equatable {
  let visible: Bool
  let compact: Bool
  let tightToEdges: Bool
  let items: [NativeDockItem]

  init(arguments: [String: Any]) {
    visible = arguments["visible"] as? Bool ?? false
    compact = arguments["compact"] as? Bool ?? true
    tightToEdges = arguments["tightToEdges"] as? Bool ?? true
    let rawItems = arguments["items"] as? [[String: Any]] ?? []
    items = rawItems.map(NativeDockItem.init)
  }
}

private struct NativeDockItem: Equatable {
  let id: String
  let symbol: String
  let selectedSymbol: String?
  let active: Bool
  let primary: Bool
  let showBadge: Bool
  let supportsLongPress: Bool

  init(arguments: [String: Any]) {
    id = arguments["id"] as? String ?? UUID().uuidString
    symbol = arguments["symbol"] as? String ?? "circle"
    selectedSymbol = arguments["selectedSymbol"] as? String
    active = arguments["active"] as? Bool ?? false
    primary = arguments["primary"] as? Bool ?? false
    showBadge = arguments["showBadge"] as? Bool ?? false
    supportsLongPress = arguments["supportsLongPress"] as? Bool ?? false
  }
}

private final class DeviceInfoChannelBridge: NSObject {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(
      name: "accord/device_info",
      binaryMessenger: messenger
    )
    super.init()
    channel.setMethodCallHandler(handleMethodCall)
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isIOSSimulator":
      #if targetEnvironment(simulator)
      result(true)
      #else
      result(false)
      #endif
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
