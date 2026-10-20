import UIKit
import ExpoModulesCore

// Kept independently of any React Native view hierarchy. All methods run on main.
final class OverlayCoordinator {
  static let shared = OverlayCoordinator()

  private final class Request {
    let options: NativeDialogOptions
    let promise: Promise
    var settled = false
    init(_ options: NativeDialogOptions, _ promise: Promise) {
      self.options = options
      self.promise = promise
    }
    func resolve(_ value: [String: Any]) {
      guard !settled else { return }
      settled = true
      promise.resolve(value)
    }
  }

  private var active: Request?
  private var pending: [Request] = []
  private var overlayWindow: UIWindow?
  private weak var previousKeyWindow: UIWindow?

  private init() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(applicationDidEnterBackground),
      name: UIApplication.didEnterBackgroundNotification, object: nil
    )
  }

  func enqueue(_ options: NativeDialogOptions, promise: Promise) {
    let request = Request(options, promise)
    if active != nil {
      switch options.queuePolicy {
      case .reject:
        promise.reject("ERR_DIALOG_ACTIVE", "A dialog is already being displayed.")
        return
      case .replace:
        clearActive(reason: "programmatic")
        pending.insert(request, at: 0)
      case .enqueue:
        pending.append(request)
      }
    } else {
      pending.append(request)
    }
    presentNext()
  }

  func dismissAll(reason: String = "programmatic") {
    let allPending = pending
    pending.removeAll()
    clearActive(reason: reason)
    for request in allPending {
      request.resolve(["status": "dismissed", "reason": reason])
    }
  }

  @objc private func applicationDidEnterBackground() {
    dismissAll(reason: "lifecycle")
  }

  private func clearActive(reason: String) {
    let old = active
    active = nil
    removeWindow()
    old?.resolve(["status": "dismissed", "reason": reason])
  }

  private func removeWindow() {
    overlayWindow?.isHidden = true
    overlayWindow?.rootViewController = nil
    overlayWindow = nil
    if let previousKeyWindow = previousKeyWindow,
       !previousKeyWindow.isHidden,
       previousKeyWindow.windowScene?.activationState == .foregroundActive {
      previousKeyWindow.makeKey()
    }
    previousKeyWindow = nil
  }

  private func preferredScene() -> UIWindowScene? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
    return scenes.first(where: { $0.windows.contains(where: { $0.isKeyWindow }) })
      ?? scenes.first
  }

  private func presentNext() {
    guard active == nil, !pending.isEmpty else { return }
    guard let scene = preferredScene() else {
      let requests = pending
      pending.removeAll()
      requests.forEach { $0.resolve(["status": "dismissed", "reason": "lifecycle"]) }
      return
    }

    let request = pending.removeFirst()
    active = request
    previousKeyWindow = scene.windows.first(where: { $0.isKeyWindow })

    let controller = NativeDialogViewController(options: request.options)
    controller.onAction = { [weak self, weak request] id, values in
      guard let self = self, let request = request, self.active === request else { return }
      request.resolve(["status": "action", "actionId": id, "values": values])
      self.active = nil
      self.removeWindow()
      self.presentNext()
    }
    controller.onDismiss = { [weak self, weak request] reason in
      guard let self = self, let request = request, self.active === request else { return }
      request.resolve(["status": "dismissed", "reason": reason])
      self.active = nil
      self.removeWindow()
      self.presentNext()
    }

    let window = UIWindow(windowScene: scene)
    window.windowLevel = .alert + 1
    window.backgroundColor = .clear
    window.rootViewController = controller
    overlayWindow = window
    window.makeKeyAndVisible()
  }
}
