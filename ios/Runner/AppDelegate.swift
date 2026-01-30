import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register CloudKit plugin manually
    // Use the default registrar for plugins not handled by Flutter's pod generation
    NSLog("[CloudKit] 🔵 Registering CloudKit plugin...")
    CloudKitPlugin.register(with: self.registrar())
    NSLog("[CloudKit] ✅ CloudKit plugin registered successfully")

    NSLog("[CloudKit] 🔵 Registering generated plugins...")
    GeneratedPluginRegistrant.register(with: self)
    NSLog("[CloudKit] ✅ All plugins registered")

    NSLog("[CloudKit] 🔵 Completing app launch...")
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    NSLog("[CloudKit] ✅ App launch completed, result: \(result)")

    return result
  }
}
