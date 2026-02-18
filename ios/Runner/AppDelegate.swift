import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var appBadgeChannel: FlutterMethodChannel?
  private static let appBadgeChannelName = "pet/app_badge"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "PetAppBadgeChannel"
    ) {
      setupAppBadgeChannel(binaryMessenger: registrar.messenger())
    }
  }

  private func setupAppBadgeChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: Self.appBadgeChannelName,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "setBadgeCount":
        guard
          let args = call.arguments as? [String: Any],
          let rawCount = args["count"] as? NSNumber
        else {
          result(
            FlutterError(
              code: "bad_args",
              message: "Expected {count: int}",
              details: nil
            )
          )
          return
        }
        DispatchQueue.main.async {
          let appliedCount = max(0, rawCount.intValue)
          UIApplication.shared.applicationIconBadgeNumber = appliedCount
          result(appliedCount)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    appBadgeChannel = channel
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }
}
