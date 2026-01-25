import Flutter
import UIKit

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
        case "isAvailable":
            checkAvailability(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func checkAvailability(result: @escaping FlutterResult) {
        CloudKitService.shared.container.accountStatus { status, _ in
            result(status == .available)
        }
    }

    private func saveToiCloudDrive(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let fileName = args["fileName"] as? String,
              let jsonString = args["jsonData"] as? String,
              let jsonData = jsonString.data(using: .utf8) else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing fileName or jsonData", details: nil))
            return
        }
        CloudKitService.shared.saveToiCloudDrive(fileName: fileName, jsonData: jsonData) { response in
            switch response {
            case .success(let path):
                result(["success": true, "path": path])
            case .failure(let error):
                result(FlutterError(code: "ICLOUD_ERROR", message: error, details: nil))
            }
        }
    }

    private func readFromiCloudDrive(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let fileName = args["fileName"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing fileName argument", details: nil))
            return
        }
        CloudKitService.shared.readFromiCloudDrive(fileName: fileName) { response in
            switch response {
            case .success(let data):
                if let jsonString = String(data: data, encoding: .utf8) {
                    result(["success": true, "data": jsonString])
                } else {
                    result(FlutterError(code: "ICLOUD_ERROR", message: "Failed to decode data", details: nil))
                }
            case .failure(let error):
                result(FlutterError(code: "ICLOUD_ERROR", message: error, details: nil))
            }
        }
    }

    private func fileExistsInICloudDrive(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let fileName = args["fileName"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing fileName argument", details: nil))
            return
        }
        CloudKitService.shared.fileExistsInICloudDrive(fileName: fileName) { exists in
            result(["success": true, "exists": exists])
        }
    }

    private func deleteFromICloudDrive(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let fileName = args["fileName"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing fileName argument", details: nil))
            return
        }
        CloudKitService.shared.deleteFromICloudDrive(fileName: fileName) { response in
            switch response {
            case .success:
                result(["success": true])
            case .failure(let error):
                result(FlutterError(code: "ICLOUD_ERROR", message: error, details: nil))
            }
        }
    }

    private func listICloudDriveFiles(result: @escaping FlutterResult) {
        CloudKitService.shared.listICloudDriveFiles { response in
            switch response {
            case .success(let files):
                result(["success": true, "files": files])
            case .failure(let error):
                result(FlutterError(code: "ICLOUD_ERROR", message: error, details: nil))
            }
        }
    }
}
