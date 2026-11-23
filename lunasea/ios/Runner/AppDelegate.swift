import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  lazy var flutterEngine = FlutterEngine(name: "lunasea_engine")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)

    let channel = FlutterMethodChannel(
      name: "homelabarr/app_icon",
      binaryMessenger: flutterEngine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "setIcon" {
        let iconName = call.arguments as? String
        if UIApplication.shared.supportsAlternateIcons {
          UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
              result(FlutterError(code: "ICON_ERROR", message: error.localizedDescription, details: nil))
            } else {
              result(true)
            }
          }
        } else {
          result(false)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    config.delegateClass = SceneDelegate.self
    return config
  }
}

@objc(SceneDelegate)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
      let flutterVC = FlutterViewController(engine: appDelegate.flutterEngine, nibName: nil, bundle: nil)
      window.rootViewController = flutterVC
    }
    self.window = window
    window.makeKeyAndVisible()
  }
}
