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
        // iCloud Drive methods
        case "saveToiCloudDrive":
            saveToiCloudDrive(call: call, result: result)
        case "readFromiCloudDrive":
            readFromiCloudDrive(call: call, result: result)
        case "fileExistsInICloudDrive":
            fileExistsInICloudDrive(call: call, result: result)
        case "deleteFromICloudDrive":
            deleteFromICloudDrive(call: call, result: result)
        case "listICloudDriveFiles":
            listICloudDriveFiles(result: result)
        // CloudKit methods (legacy)
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

    // MARK: - iCloud Drive Methods

    private func saveToiCloudDrive(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let fileName = args["fileName"] as? String,
              let jsonString = args["jsonData"] as? String,
              let jsonData = jsonString.data(using: .utf8) else {
            result(FlutterError(code: "INVALID_ARGS",
                                message: "Missing fileName or jsonData",
                                details: nil))
            return
        }

        CloudKitService.shared.saveToiCloudDrive(fileName: fileName, jsonData: jsonData) { response in
            switch response {
            case .success(let path):
                result([
                    "success": true,
                    "path": path
                ])
            case .failure(let error):
                result(FlutterError(code: "ICLOUD_ERROR",
                                    message: error,
                                    details: nil))
            }
        }
    }

    private func readFromiCloudDrive(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let fileName = args["fileName"] as? String else {
            result(FlutterError(code: "INVALID_ARGS",
                                message: "Missing fileName argument",
                                details: nil))
            return
        }

        CloudKitService.shared.readFromiCloudDrive(fileName: fileName) { response in
            switch response {
            case .success(let data):
                if let jsonString = String(data: data, encoding: .utf8) {
                    result([
                        "success": true,
                        "data": jsonString
                    ])
                } else {
                    result(FlutterError(code: "ICLOUD_ERROR",
                                        message: "Failed to decode data",
                                        details: nil))
                }
            case .failure(let error):
                result(FlutterError(code: "ICLOUD_ERROR",
                                    message: error,
                                    details: nil))
            }
        }
    }

    private func fileExistsInICloudDrive(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let fileName = args["fileName"] as? String else {
            result(FlutterError(code: "INVALID_ARGS",
                                message: "Missing fileName argument",
                                details: nil))
            return
        }

        CloudKitService.shared.fileExistsInICloudDrive(fileName: fileName) { exists in
            result([
                "success": true,
                "exists": exists
            ])
        }
    }

    private func deleteFromICloudDrive(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let fileName = args["fileName"] as? String else {
            result(FlutterError(code: "INVALID_ARGS",
                                message: "Missing fileName argument",
                                details: nil))
            return
        }

        CloudKitService.shared.deleteFromICloudDrive(fileName: fileName) { response in
            switch response {
            case .success:
                result([
                    "success": true
                ])
            case .failure(let error):
                result(FlutterError(code: "ICLOUD_ERROR",
                                    message: error,
                                    details: nil))
            }
        }
    }

    private func listICloudDriveFiles(result: @escaping FlutterResult) {
        CloudKitService.shared.listICloudDriveFiles { response in
            switch response {
            case .success(let files):
                result([
                    "success": true,
                    "files": files
                ])
            case .failure(let error):
                result(FlutterError(code: "ICLOUD_ERROR",
                                    message: error,
                                    details: nil))
            }
        }
    }
}
