import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 🔔 iOS 알림 센터 델리게이트 등록 (앱 실행 중에도 알림 배너 표시)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let controller = window?.rootViewController as? FlutterViewController ??
          (application.windows.first?.rootViewController as? FlutterViewController) else {
      return
    }

    let exportChannel = FlutterMethodChannel(
      name: "com.healthpharma.hagom_app/export",
      binaryMessenger: controller.binaryMessenger
    )

    exportChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "downloadCsv":
        guard let args = call.arguments as? [String: Any],
              let fileName = args["fileName"] as? String,
              let content = args["content"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Arguments missing", details: nil))
          return
        }

        do {
          let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
          let fileURL = docsURL.appendingPathComponent(fileName)
          try content.write(to: fileURL, atomically: true, encoding: .utf8)
          result([
            "success": true,
            "path": fileURL.path,
            "fileName": fileName
          ])
        } catch {
          result(FlutterError(code: "EXPORT_ERROR", message: error.localizedDescription, details: nil))
        }

      case "showTestNotification":
        if #available(iOS 10.0, *) {
          let center = UNUserNotificationCenter.current()
          center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
              let notiContent = UNMutableNotificationContent()
              notiContent.title = "하곰이의 복약 알림"
              notiContent.body = "오늘 복약할 시간이에요! 잊지 않고 챙겨봐요."
              notiContent.sound = .default

              let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
              let request = UNNotificationRequest(identifier: "hagom_test_noti", content: notiContent, trigger: trigger)

              center.add(request) { err in
                DispatchQueue.main.async {
                  result(err == nil)
                }
              }
            } else {
              DispatchQueue.main.async {
                result(false)
              }
            }
          }
        } else {
          result(false)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // 🔔 포그라운드(앱 켜져 있을 때) 알림 배너 띄우기 허용
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}
