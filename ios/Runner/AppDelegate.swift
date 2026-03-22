import Flutter
import SwiftUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let registrar = self.registrar(forPlugin: "AccordLiquidDockPlugin") {
      let factory = AccordLiquidDockFactory(messenger: registrar.messenger())
      registrar.register(factory, withId: "accord_liquid_dock")
    }
    GeneratedPluginRegistrant.register(with: self)
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private final class AccordLiquidDockFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    AccordLiquidDockPlatformView(
      frame: frame,
      viewId: viewId,
      args: args,
      messenger: messenger
    )
  }
}

private final class AccordLiquidDockPlatformView: NSObject, FlutterPlatformView {
  private let rootView: AccordLiquidDockView

  init(
    frame: CGRect,
    viewId: Int64,
    args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    rootView = AccordLiquidDockView(frame: frame, viewId: viewId, args: args, messenger: messenger)
    super.init()
  }

  func view() -> UIView {
    rootView
  }
}

private struct AccordLiquidDockItem: Hashable {
  let id: String
  let active: Bool
  let primary: Bool
  let showBadge: Bool
  let allowLongPress: Bool
}

private final class AccordLiquidDockView: UIView {
  private let channel: FlutterMethodChannel
  private let compact: Bool
  private let tightToEdges: Bool
  private let items: [AccordLiquidDockItem]
  private let hostView = UIView()
  private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
  private let tintView = UIView()
  private let sheenView = UIView()
  private let borderView = UIView()
  private let stackView = UIStackView()

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    let arguments = args as? [String: Any] ?? [:]
    let channelName = arguments["channel"] as? String ?? "accord_liquid_dock/\(viewId)"
    channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    compact = arguments["compact"] as? Bool ?? true
    tightToEdges = arguments["tightToEdges"] as? Bool ?? true
    let rawItems = arguments["items"] as? [[String: Any]] ?? []
    items = rawItems.compactMap { item in
      guard let id = item["id"] as? String else {
        return nil
      }
      return AccordLiquidDockItem(
        id: id,
        active: item["active"] as? Bool ?? false,
        primary: item["primary"] as? Bool ?? false,
        showBadge: item["showBadge"] as? Bool ?? false,
        allowLongPress: item["allowLongPress"] as? Bool ?? false
      )
    }
    super.init(frame: frame)
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    isOpaque = false
    setupViewHierarchy()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViewHierarchy() {
#if compiler(>=6.2)
    if #available(iOS 26.0, *) {
      setupOriginalLiquidGlassView()
      return
    }
#endif

    let hostHeight: CGFloat = compact ? 76 : 84
    let horizontalInset: CGFloat = tightToEdges ? 4 : 14
    let buttonInset: CGFloat = tightToEdges ? 10 : 16

    addSubview(hostView)
    hostView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalInset),
      hostView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalInset),
      hostView.topAnchor.constraint(equalTo: topAnchor),
      hostView.bottomAnchor.constraint(equalTo: bottomAnchor),
      hostView.heightAnchor.constraint(equalToConstant: hostHeight),
    ])

    hostView.addSubview(blurView)
    blurView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      blurView.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
      blurView.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
      blurView.topAnchor.constraint(equalTo: hostView.topAnchor, constant: compact ? 10 : 8),
      blurView.bottomAnchor.constraint(equalTo: hostView.bottomAnchor, constant: compact ? -4 : -2),
    ])

    let blurRadius: CGFloat = compact ? 28 : 30
    blurView.clipsToBounds = true
    blurView.layer.cornerRadius = blurRadius
    blurView.layer.cornerCurve = .continuous
    blurView.layer.shadowColor = UIColor.black.cgColor
    blurView.layer.shadowOpacity = 0.22
    blurView.layer.shadowRadius = 22
    blurView.layer.shadowOffset = CGSize(width: 0, height: 10)

    tintView.translatesAutoresizingMaskIntoConstraints = false
    tintView.backgroundColor = UIColor(red: 0.12, green: 0.13, blue: 0.18, alpha: 0.24)
    blurView.contentView.addSubview(tintView)
    NSLayoutConstraint.activate([
      tintView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
      tintView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
      tintView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
      tintView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor),
    ])

    sheenView.translatesAutoresizingMaskIntoConstraints = false
    sheenView.isUserInteractionEnabled = false
    blurView.contentView.addSubview(sheenView)
    NSLayoutConstraint.activate([
      sheenView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
      sheenView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
      sheenView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
      sheenView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor),
    ])

    let sheenLayer = CAGradientLayer()
    sheenLayer.colors = [
      UIColor.white.withAlphaComponent(0.26).cgColor,
      UIColor.white.withAlphaComponent(0.08).cgColor,
      UIColor.clear.cgColor,
      UIColor.black.withAlphaComponent(0.12).cgColor,
    ]
    sheenLayer.locations = [0.0, 0.18, 0.52, 1.0]
    sheenLayer.startPoint = CGPoint(x: 0.18, y: 0.0)
    sheenLayer.endPoint = CGPoint(x: 0.82, y: 1.0)
    sheenView.layer.addSublayer(sheenLayer)

    borderView.translatesAutoresizingMaskIntoConstraints = false
    borderView.backgroundColor = .clear
    borderView.isUserInteractionEnabled = false
    borderView.layer.cornerRadius = blurRadius
    borderView.layer.cornerCurve = .continuous
    borderView.layer.borderWidth = 1.0
    borderView.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
    blurView.contentView.addSubview(borderView)
    NSLayoutConstraint.activate([
      borderView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
      borderView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
      borderView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
      borderView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor),
    ])

    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.distribution = .fillEqually
    stackView.spacing = compact ? 6 : 10
    blurView.contentView.addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: buttonInset),
      stackView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -buttonInset),
      stackView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: compact ? 8 : 10),
      stackView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: compact ? -8 : -10),
    ])

    for item in items {
      let button = AccordLiquidDockButton(item: item)
      button.tapHandler = { [weak self] id in
        self?.channel.invokeMethod("tap", arguments: ["id": id])
      }
      button.longPressHandler = { [weak self] id in
        self?.channel.invokeMethod("longPress", arguments: ["id": id])
      }
      stackView.addArrangedSubview(button)
    }

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      sheenLayer.frame = self.sheenView.bounds
      sheenLayer.cornerRadius = blurRadius
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    for layer in sheenView.layer.sublayers ?? [] {
      layer.frame = sheenView.bounds
      layer.cornerRadius = borderView.layer.cornerRadius
    }
  }

#if compiler(>=6.2)
  @available(iOS 26.0, *)
  private func setupOriginalLiquidGlassView() {
    let root = AccordLiquidGlassDockRoot(
      items: items,
      compact: compact,
      tightToEdges: tightToEdges,
      onTap: { [weak self] id in
        self?.channel.invokeMethod("tap", arguments: ["id": id])
      },
      onLongPress: { [weak self] id in
        self?.channel.invokeMethod("longPress", arguments: ["id": id])
      }
    )

    let hostingController = UIHostingController(rootView: root)
    let hostingView = hostingController.view!
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    hostingView.backgroundColor = .clear

    addSubview(hostingView)
    NSLayoutConstraint.activate([
      hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
      hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
      hostingView.topAnchor.constraint(equalTo: topAnchor),
      hostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
#endif
}

private final class AccordLiquidDockButton: UIControl {
  var tapHandler: ((String) -> Void)?
  var longPressHandler: ((String) -> Void)?

  private let item: AccordLiquidDockItem
  private let iconView = UIImageView()
  private let activePillView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
  private let badgeView = UIView()

  init(item: AccordLiquidDockItem) {
    self.item = item
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setup() {
    let cornerRadius: CGFloat = item.primary ? 22 : 24

    activePillView.translatesAutoresizingMaskIntoConstraints = false
    activePillView.isUserInteractionEnabled = false
    activePillView.clipsToBounds = true
    activePillView.layer.cornerRadius = cornerRadius
    activePillView.layer.cornerCurve = .continuous
    activePillView.alpha = item.active || item.primary ? 1 : 0
    activePillView.contentView.backgroundColor = item.primary
      ? UIColor(red: 0.80, green: 0.88, blue: 1.0, alpha: 0.18)
      : UIColor.white.withAlphaComponent(0.10)
    addSubview(activePillView)

    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.contentMode = .scaleAspectFit
    iconView.tintColor = item.primary
      ? UIColor.white.withAlphaComponent(0.98)
      : (item.active ? UIColor.white.withAlphaComponent(0.96) : UIColor.white.withAlphaComponent(0.72))
    iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
      pointSize: item.primary ? 20 : 19,
      weight: item.primary ? .semibold : .medium
    )
    iconView.image = UIImage(systemName: symbolName(for: item))
    addSubview(iconView)

    badgeView.translatesAutoresizingMaskIntoConstraints = false
    badgeView.backgroundColor = UIColor(red: 1.0, green: 0.25, blue: 0.28, alpha: 1.0)
    badgeView.layer.cornerRadius = 4.5
    badgeView.isHidden = !item.showBadge
    addSubview(badgeView)

    let width: CGFloat = item.primary ? 72 : 60
    let height: CGFloat = item.primary ? 50 : 50
    NSLayoutConstraint.activate([
      widthAnchor.constraint(equalToConstant: width),
      heightAnchor.constraint(equalToConstant: height),
      activePillView.centerXAnchor.constraint(equalTo: centerXAnchor),
      activePillView.centerYAnchor.constraint(equalTo: centerYAnchor),
      activePillView.widthAnchor.constraint(equalToConstant: item.primary ? 72 : (item.active ? 64 : 48)),
      activePillView.heightAnchor.constraint(equalToConstant: item.primary ? 50 : 44),
      iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
      iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: item.primary ? 24 : 22),
      iconView.heightAnchor.constraint(equalToConstant: item.primary ? 24 : 22),
      badgeView.widthAnchor.constraint(equalToConstant: 9),
      badgeView.heightAnchor.constraint(equalToConstant: 9),
      badgeView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      badgeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
    ])

    addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    if item.allowLongPress {
      let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
      recognizer.minimumPressDuration = 0.65
      addGestureRecognizer(recognizer)
    }
  }

  @objc private func handleTap() {
    tapHandler?(item.id)
  }

  @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
    if recognizer.state == .began {
      longPressHandler?(item.id)
    }
  }

  private func symbolName(for item: AccordLiquidDockItem) -> String {
    switch item.id {
      case "home":
        return item.active ? "house.fill" : "house"
      case "notifications":
        return item.active ? "bell.fill" : "bell"
      case "profile":
        return item.active ? "person.crop.circle.fill" : "person.crop.circle"
      case "recent":
        return item.active ? "clock.fill" : "clock"
      case "suppliers":
        return item.active ? "person.2.fill" : "person.2"
      case "activity":
        return item.active ? "waveform.path.ecg.rectangle.fill" : "waveform.path.ecg.rectangle"
      case "create":
        return "plus"
      default:
        return item.active ? "circle.fill" : "circle"
    }
  }
}

#if compiler(>=6.2)
@available(iOS 26.0, *)
private struct AccordLiquidGlassDockRoot: View {
  let items: [AccordLiquidDockItem]
  let compact: Bool
  let tightToEdges: Bool
  let onTap: (String) -> Void
  let onLongPress: (String) -> Void

  var body: some View {
    HStack(spacing: compact ? 8 : 10) {
      ForEach(items, id: \.self) { item in
        AccordLiquidGlassDockButton(
          item: item,
          onTap: { onTap(item.id) },
          onLongPress: { onLongPress(item.id) }
        )
      }
    }
    .padding(.horizontal, tightToEdges ? 14 : 20)
    .padding(.top, compact ? 10 : 8)
    .padding(.bottom, compact ? 6 : 4)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background {
      Capsule(style: .continuous)
        .fill(.clear)
        .glassEffect()
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }
    .padding(.horizontal, tightToEdges ? 4 : 14)
  }
}

@available(iOS 26.0, *)
private struct AccordLiquidGlassDockButton: View {
  let item: AccordLiquidDockItem
  let onTap: () -> Void
  let onLongPress: () -> Void

  var body: some View {
    let frameWidth: CGFloat = item.primary ? 72 : 60
    let pillWidth: CGFloat = item.primary ? 72 : (item.active ? 64 : 46)
    let tint: Color = item.primary
      ? .white.opacity(0.98)
      : (item.active ? .white.opacity(0.96) : .white.opacity(0.72))

    Image(systemName: symbolName)
      .font(.system(size: item.primary ? 20 : 19, weight: item.primary ? .semibold : .medium))
      .foregroundStyle(tint)
      .frame(width: frameWidth, height: 50)
      .background {
        if item.active || item.primary {
          Capsule(style: .continuous)
            .fill(.clear)
            .frame(width: pillWidth, height: item.primary ? 50 : 44)
            .glassEffect()
        }
      }
      .overlay(alignment: .topTrailing) {
        if item.showBadge {
          Circle()
            .fill(Color(red: 1.0, green: 0.25, blue: 0.28))
            .frame(width: 9, height: 9)
            .offset(x: -10, y: 8)
        }
      }
      .contentShape(Rectangle())
      .onTapGesture(perform: onTap)
      .onLongPressGesture(minimumDuration: 0.65) {
        if item.allowLongPress {
          onLongPress()
        }
      }
  }

  private var symbolName: String {
    switch item.id {
      case "home":
        return item.active ? "house.fill" : "house"
      case "notifications":
        return item.active ? "bell.fill" : "bell"
      case "profile":
        return item.active ? "person.crop.circle.fill" : "person.crop.circle"
      case "recent":
        return item.active ? "clock.fill" : "clock"
      case "suppliers":
        return item.active ? "person.2.fill" : "person.2"
      case "activity":
        return item.active ? "waveform.path.ecg.rectangle.fill" : "waveform.path.ecg.rectangle"
      case "create":
        return "plus"
      default:
        return item.active ? "circle.fill" : "circle"
    }
  }
}
#endif
