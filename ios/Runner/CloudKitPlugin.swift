import Flutter
import UIKit

/// CloudKit plugin for Flutter
///
/// Provides method channel interface for CloudKit operations
public class CloudKitPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.yourcompany.futureproof/cloudkit",
            binaryMessenger: registrar.messenger()
        )
        let instance = CloudKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            checkAvailability(result: result)
        case "fetchVaultIndex":
            fetchVaultIndex(result: result)
        case "uploadVaultMetadata":
            uploadVaultMetadata(call: call, result: result)
        case "deleteVaultMetadata":
            deleteVaultMetadata(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Methods

    private func checkAvailability(result: @escaping FlutterResult) {
        CloudKitService.shared.checkCloudKitAvailability { available in
            result(available)
        }
    }

    private func fetchVaultIndex(result: @escaping FlutterResult) {
        CloudKitService.shared.fetchVaultIndex { metadata, error in
            if let error = error {
                result(FlutterError(code: "CLOUDKIT_ERROR",
                                    message: error.localizedDescription,
                                    details: nil))
            } else {
                result(metadata)
            }
        }
    }

    private func uploadVaultMetadata(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let vaultId = args["vaultId"] as? String,
              let metadata = args["metadata"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS",
                                message: "Missing required arguments",
                                details: nil))
            return
        }

        CloudKitService.shared.uploadVaultMetadata(vaultId: vaultId, metadata: metadata) { error in
            if let error = error {
                result(FlutterError(code: "CLOUDKIT_ERROR",
                                    message: error.localizedDescription,
                                    details: nil))
            } else {
                result(true)
            }
        }
    }

    private func deleteVaultMetadata(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let vaultId = args["vaultId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS",
                                message: "Missing vaultId argument",
                                details: nil))
            return
        }

        CloudKitService.shared.deleteVaultMetadata(vaultId: vaultId) { error in
            if let error = error {
                result(FlutterError(code: "CLOUDKIT_ERROR",
                                    message: error.localizedDescription,
                                    details: nil))
            } else {
                result(true)
            }
        }
    }
}
