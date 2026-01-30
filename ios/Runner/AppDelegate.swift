import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Flutter engine FIRST - this is critical!
    NSLog("[CloudKit] 🔵 Initializing Flutter engine...")
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    NSLog("[CloudKit] ✅ Flutter engine initialized")

    // Register CloudKit plugin AFTER Flutter is initialized
    NSLog("[CloudKit] 🔵 Registering CloudKit plugin...")
    CloudKitPlugin.register(with: self.registrar(forPlugin: "CloudKitPlugin") ?? self.registrar())
    NSLog("[CloudKit] ✅ CloudKit plugin registered successfully")

    NSLog("[CloudKit] 🔵 Registering generated plugins...")
    GeneratedPluginRegistrant.register(with: self)
    NSLog("[CloudKit] ✅ All plugins registered")

    NSLog("[CloudKit] ✅ App launch completed, result: \(result)")
    return result
  }
}
