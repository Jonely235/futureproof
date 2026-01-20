import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register CloudKit plugin (iOS only)
    CloudKitPlugin.register(with: self.registrar(forPlugin: "CloudKitPlugin")!)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
