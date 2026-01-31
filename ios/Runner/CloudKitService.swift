import CloudKit
import Foundation

// MARK: - Configuration

/// CloudKit configuration
///
/// IMPORTANT: Update these values for production:
/// 1. CloudKitConfig.containerIdentifier must match your iCloud container ID in Apple Developer Portal
/// 2. The format is typically: "iCloud." + bundle ID (e.g., "iCloud.com.yourcompany.futureproof")
/// 3. This value must match the iCloud Containers entitlement in Runner.entitlements
struct CloudKitConfig {
    /// The iCloud container identifier
    /// MUST match: iCloud Containers entitlement in Xcode
    /// Format: "iCloud." + bundle ID (reversed dots)
    static let containerIdentifier = "iCloud.com.jonely.futureproof"

    /// Method channel name for Flutter communication
    /// MUST match: MethodChannel name in icloud_drive_service.dart
    static let methodChannelName = "com.yourcompany.futureproof/cloudkit"
}

/// CloudKit service for vault synchronization
///
/// Manages CloudKit operations for syncing vault metadata and files
/// between devices via iCloud.
///
/// Now includes iCloud Drive file storage for direct file access.
class CloudKitService {
    static let shared = CloudKitService()

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    // iCloud Drive Documents directory
    private var iCloudDocumentsURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: CloudKitConfig.containerIdentifier)?.appendingPathComponent("Documents")
    }

    private init() {
        // Initialize CloudKit container with configured identifier
        // For iOS 15+, use identifier string directly instead of CKContainer.ID()
        self.container = CKContainer(identifier: CloudKitConfig.containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase

        // Ensure iCloud Drive directory exists
        setupICloudDriveDirectory()
    }

    // MARK: - iCloud Drive Setup

    private func setupICloudDriveDirectory() {
        NSLog("[CloudKit] 🔵 Setting up iCloud Drive directory...")
        NSLog("[CloudKit] Container identifier: \(CloudKitConfig.containerIdentifier)")

        guard let documentsURL = iCloudDocumentsURL else {
            NSLog("[CloudKit] ❌ ERROR: iCloud ubiquity container URL is nil!")
            NSLog("[CloudKit] Troubleshooting steps:")
            NSLog("[CloudKit] 1. Check iCloud is enabled in device Settings")
            NSLog("[CloudKit] 2. Verify container ID '\(CloudKitConfig.containerIdentifier)' matches Runner.entitlements")
            NSLog("[CloudKit] 3. Ensure 'iCloud' capability is enabled in Xcode Signing & Capabilities")
            NSLog("[CloudKit] 4. Check that iCloud container is created in Apple Developer Portal")
            NSLog("[CloudKit] 5. Verify app has 'iCloud Documents' enabled in capabilities")
            return
        }

        NSLog("[CloudKit] ✅ Ubiquity container URL: \(documentsURL.path)")

        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            do {
                try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
                NSLog("[CloudKit] ✅ Created iCloud Documents directory successfully")

                // CRITICAL: Create a placeholder file so the folder shows up in Finder
                let placeholderURL = documentsURL.appendingPathComponent(".placeholder")
                FileManager.default.createFile(atPath: placeholderURL.path, contents: Data())
                NSLog("[CloudKit] ✅ Created placeholder file for Finder visibility")
            } catch {
                // Log error but don't fail - directory will be created on first write
                NSLog("[CloudKit] ⚠️ Failed to create iCloud Documents directory: \(error.localizedDescription)")
                NSLog("[CloudKit] This may be because iCloud is not signed in on the device")
            }
        } else {
            NSLog("[CloudKit] ✅ iCloud Documents directory already exists")
        }
    }

    // MARK: - File Name Validation

    /// Validate file name to prevent path traversal attacks
    /// Note: This must match the Dart validation in icloud_drive_service.dart
    /// Dart regex: ^[a-zA-Z0-9_-]+$ (alphanumeric, underscore, hyphen only)
    private func validateFileName(_ fileName: String) -> Bool {
        // Only allow alphanumeric, underscore, and hyphen (NO dot - .json is appended separately)
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "_-"))
        return fileName.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
            && !fileName.isEmpty
            && fileName.count <= 255
    }

    // MARK: - iCloud Drive File Operations

    /// Result type for iCloud Drive operations
    enum ICloudDriveResult<T> {
        case success(T)
        case failure(String)
    }

    /// Save JSON data to iCloud Drive
    func saveToiCloudDrive(fileName: String, jsonData: Data, completion: @escaping (ICloudDriveResult<String>) -> Void) {
        NSLog("[CloudKit] 🔵 saveToiCloudDrive called for file: \(fileName)")
        NSLog("[CloudKit] 📦 JSON data size: \(jsonData.count) bytes")

        // Validate file name
        guard validateFileName(fileName) else {
            NSLog("[CloudKit] ❌ ERROR: Invalid file name: \(fileName)")
            NSLog("[CloudKit] File names must be alphanumeric with underscores/hyphens only")
            completion(.failure("Invalid file name"))
            return
        }

        NSLog("[CloudKit] ✅ File name validated")

        guard let documentsURL = iCloudDocumentsURL else {
            NSLog("[CloudKit] ❌ ERROR: iCloud container not available - documentsURL is nil")
            NSLog("[CloudKit] 🔍 Container ID being used: \(CloudKitConfig.containerIdentifier)")
            NSLog("[CloudKit] 📋 Troubleshooting:")
            NSLog("[CloudKit] 1. Sign into iCloud on device Settings > [your name] > iCloud")
            NSLog("[CloudKit] 2. Enable 'iCloud Drive' in iCloud settings")
            NSLog("[CloudKit] 3. Verify Runner.entitlements has matching container ID")
            NSLog("[CloudKit] 4. Ensure 'iCloud' capability added in Xcode project")
            NSLog("[CloudKit] 5. Check that container exists in Apple Developer Portal")
            completion(.failure("iCloud container not available"))
            return
        }

        NSLog("[CloudKit] ✅ iCloud container available")
        NSLog("[CloudKit] 📁 Documents URL: \(documentsURL.path)")

        // Ensure directory exists
        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            NSLog("[CloudKit] 📁 Creating Documents directory...")
            do {
                try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
                NSLog("[CloudKit] ✅ Created iCloud Documents directory")

                // Add placeholder file for Finder visibility
                let placeholderURL = documentsURL.appendingPathComponent(".placeholder")
                if !FileManager.default.fileExists(atPath: placeholderURL.path) {
                    FileManager.default.createFile(atPath: placeholderURL.path, contents: Data())
                    NSLog("[CloudKit] ✅ Created placeholder file")
                }
            } catch {
                NSLog("[CloudKit] ❌ ERROR: Failed to create iCloud Documents directory: \(error.localizedDescription)")
                NSLog("[CloudKit] Error details: \(error)")
                completion(.failure("Failed to create iCloud Documents directory: \(error.localizedDescription)"))
                return
            }
        } else {
            NSLog("[CloudKit] ✅ Documents directory exists")
        }

        let fileURL = documentsURL.appendingPathComponent("\(fileName).json")
        NSLog("[CloudKit] 📄 Target file path: \(fileURL.path)")

        do {
            try jsonData.write(to: fileURL, options: .atomic)
            NSLog("[CloudKit] ✅ SUCCESS: File written to \(fileURL.path)")

            // Verify file exists and get its size
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let fileSize = attributes[.size] as? UInt64 ?? 0
                NSLog("[CloudKit] ✅ Verified file exists, size: \(fileSize) bytes")
            } else {
                NSLog("[CloudKit] ⚠️ WARNING: File write succeeded but file not found on verification")
            }

            completion(.success(fileURL.path))
        } catch {
            NSLog("[CloudKit] ❌ ERROR: Failed to write file: \(error.localizedDescription)")
            NSLog("[CloudKit] Error: \(error)")
            NSLog("[CloudKit] 💡 This might be a permissions issue or iCloud account not signed in")
            completion(.failure("Failed to write file: \(error.localizedDescription)"))
        }
    }

    /// Read JSON data from iCloud Drive
    func readFromiCloudDrive(fileName: String, completion: @escaping (ICloudDriveResult<Data>) -> Void) {
        NSLog("[CloudKit] readFromiCloudDrive called for file: \(fileName)")

        // Validate file name
        guard validateFileName(fileName) else {
            NSLog("[CloudKit] ERROR: Invalid file name: \(fileName)")
            completion(.failure("Invalid file name"))
            return
        }

        guard let documentsURL = iCloudDocumentsURL else {
            NSLog("[CloudKit] ERROR: iCloud container not available - documentsURL is nil")
            completion(.failure("iCloud container not available"))
            return
        }

        let fileURL = documentsURL.appendingPathComponent("\(fileName).json")
        NSLog("[CloudKit] Reading from: \(fileURL.path)")

        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            NSLog("[CloudKit] ERROR: File not found: \(fileURL.path)")
            completion(.failure("File not found"))
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            NSLog("[CloudKit] SUCCESS: Read \(data.count) bytes from \(fileName)")
            completion(.success(data))
        } catch {
            NSLog("[CloudKit] ERROR: Failed to read file: \(error.localizedDescription)")
            completion(.failure("Failed to read file"))
        }
    }

    /// Check if a file exists in iCloud Drive
    func fileExistsInICloudDrive(fileName: String, completion: @escaping (Bool) -> Void) {
        // Validate file name
        guard validateFileName(fileName) else {
            completion(false)
            return
        }

        guard let documentsURL = iCloudDocumentsURL else {
            completion(false)
            return
        }

        let fileURL = documentsURL.appendingPathComponent("\(fileName).json")
        completion(FileManager.default.fileExists(atPath: fileURL.path))
    }

    /// Delete a file from iCloud Drive
    func deleteFromICloudDrive(fileName: String, completion: @escaping (ICloudDriveResult<Void>) -> Void) {
        // Validate file name
        guard validateFileName(fileName) else {
            completion(.failure("Invalid file name"))
            return
        }

        guard let documentsURL = iCloudDocumentsURL else {
            completion(.failure("iCloud container not available"))
            return
        }

        let fileURL = documentsURL.appendingPathComponent("\(fileName).json")

        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            completion(.success(())) // File doesn't exist, consider it deleted
            return
        }

        do {
            try FileManager.default.removeItem(at: fileURL)
            completion(.success(()))
        } catch {
            completion(.failure("Failed to delete file"))
        }
    }

    /// List all files in iCloud Drive Documents directory
    func listICloudDriveFiles(completion: @escaping (ICloudDriveResult<[String]>) -> Void) {
        guard let documentsURL = iCloudDocumentsURL else {
            completion(.failure("iCloud container not available"))
            return
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let fileNames = files.map { $0.deletingPathExtension().lastPathComponent }
            completion(.success(fileNames))
        } catch {
            completion(.failure("Failed to list files"))
        }
    }

    // MARK: - Vault Metadata Sync

    /// Sync vault index from CloudKit
    func fetchVaultIndex(completion: @escaping ([String: Any]?, Error?) -> Void) {
        let predicate = NSPredicate(format: "1 == 1")
        let query = CKQuery(recordType: "VaultIndex", predicate: predicate)

        // Use CKQueryOperation for iOS 15+ compatibility
        let operation = CKQueryOperation()
        operation.query = query
        var vaultsData: [[String: Any]] = []
        var activeVaultID: String = ""

        operation.recordFetchedBlock = { record in
            if let vaultsDataField = record["vaults"] as? [String] {
                // Parse vault IDs and metadata
                for vaultJson in vaultsDataField {
                    if let data = vaultJson.data(using: .utf8),
                       let vaultDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        vaultsData.append(vaultDict)
                    }
                }
            }
            if let id = record["activeVaultID"] as? String {
                activeVaultID = id
            }
        }

        operation.queryCompletionBlock = { cursor, error in
            if let error = error {
                completion(nil, error)
            } else {
                let indexData: [String: Any] = [
                    "vaults": vaultsData,
                    "activeVaultID": activeVaultID
                ]
                completion(indexData, nil)
            }
        }

        privateDatabase.add(operation)
    }

    /// Upload vault metadata to CloudKit
    func uploadVaultMetadata(vaultId: String, metadata: [String: Any], completion: @escaping (Error?) -> Void) {
        // Check if record exists
        let predicate: NSPredicate = NSPredicate(format: "vaultID == %@", vaultId)
        let query = CKQuery(recordType: "VaultMetadata", predicate: predicate)

        // Use CKQueryOperation for iOS 15+ compatibility
        let operation = CKQueryOperation()
        operation.query = query
        var existingRecordID: CKRecord.ID?

        operation.recordFetchedBlock = { record in
            existingRecordID = record.recordID
        }

        operation.queryCompletionBlock = { [weak self] cursor, error in
            guard let self = self else { return }

            if let error = error {
                completion(error)
                return
            }

            let record: CKRecord
            if let existingID = existingRecordID {
                // Update existing record
                record = CKRecord(recordType: "VaultMetadata", recordID: existingID)
            } else {
                // Create new record
                record = CKRecord(recordType: "VaultMetadata")
            }

            // Set record fields
            record["vaultID"] = vaultId
            record["name"] = metadata["name"] as? String ?? ""
            record["type"] = metadata["type"] as? String ?? "personal"

            if let createdAtString = metadata["createdAt"] as? String,
               let createdAt = ISO8601DateFormatter().date(from: createdAtString) {
                record["createdAt"] = createdAt
            }

            if let lastModifiedString = metadata["lastModified"] as? String,
               let lastModified = ISO8601DateFormatter().date(from: lastModifiedString) {
                record["lastModified"] = lastModified
            }

            record["transactionCount"] = metadata["transactionCount"] as? Int ?? 0

            // Save settings as JSON data
            if let settings = metadata["settings"] as? [String: Any],
               let settingsData = try? JSONSerialization.data(withJSONObject: settings) {
                record["settings"] = settingsData
            }

            // Save record
            self.privateDatabase.save(record) { savedRecord, error in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }

        privateDatabase.add(operation)
    }

    /// Delete vault metadata from CloudKit
    func deleteVaultMetadata(vaultId: String, completion: @escaping (Error?) -> Void) {
        let predicate: NSPredicate = NSPredicate(format: "vaultID == %@", vaultId)
        let query = CKQuery(recordType: "VaultMetadata", predicate: predicate)

        // Use CKQueryOperation for iOS 15+ compatibility
        let operation = CKQueryOperation()
        operation.query = query
        var recordToDelete: CKRecord.ID?

        operation.recordFetchedBlock = { record in
            recordToDelete = record.recordID
        }

        operation.queryCompletionBlock = { [weak self] cursor, error in
            guard let self = self else { return }

            if let error = error {
                completion(error)
                return
            }

            if let recordID = recordToDelete {
                // Use CKModifyRecordsOperation for iOS 15+ compatibility
                let deleteOperation = CKModifyRecordsOperation()
                deleteOperation.recordsToDelete = [CKRecord(recordType: "VaultMetadata", recordID: recordID)]
                deleteOperation.modifyRecordsCompletionBlock = { _, deletedIDs, error in
                    if let error = error {
                        completion(error)
                    } else {
                        completion(nil)
                    }
                }
                self.privateDatabase.add(deleteOperation)
            } else {
                // No record found, consider it deleted
                completion(nil)
            }
        }

        privateDatabase.add(operation)
    }

    // MARK: - Availability Check

    /// Check if CloudKit is available
    func checkCloudKitAvailability(completion: @escaping (Bool) -> Void) {
        container.accountStatus { status, error in
            switch status {
            case .available:
                completion(true)
            case .noAccount, .restricted, .temporarilyUnavailable:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }

    // MARK: - Diagnostics

    /// Get detailed diagnostic information
    func getDiagnostics(completion: @escaping ([String: Any]) -> Void) {
        var result: [String: Any] = [:]

        // Container info
        result["containerIdentifier"] = CloudKitConfig.containerIdentifier

        // Check ubiquity container URL
        if let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: CloudKitConfig.containerIdentifier) {
            result["ubiquityContainerURL"] = ubiquityURL.path
            result["ubiquityContainerAvailable"] = true
            NSLog("[CloudKit] Ubiquity container URL: \(ubiquityURL.path)")
        } else {
            result["ubiquityContainerAvailable"] = false
            result["ubiquityContainerURLError"] = "URL is nil - check container ID matches entitlements"
            NSLog("[CloudKit] ERROR: Ubiquity container URL is nil")
        }

        // Check Documents directory
        if let documentsURL = iCloudDocumentsURL {
            result["documentsURL"] = documentsURL.path
            let docsExist = FileManager.default.fileExists(atPath: documentsURL.path)
            result["documentsExists"] = docsExist
            NSLog("[CloudKit] Documents URL: \(documentsURL.path), exists: \(docsExist)")
        } else {
            result["documentsURL"] = "nil"
            result["documentsExists"] = false
            NSLog("[CloudKit] ERROR: Documents URL is nil")
        }

        // Check account status
        container.accountStatus { status, error in
            result["accountStatus"] = self.statusDescription(status)
            if let error = error {
                result["accountError"] = error.localizedDescription
                NSLog("[CloudKit] Account error: \(error.localizedDescription)")
            } else {
                NSLog("[CloudKit] Account status: \(self.statusDescription(status))")
            }

            // List files if Documents directory exists
            if let docsURL = self.iCloudDocumentsURL {
                do {
                    let files = try FileManager.default.contentsOfDirectory(atPath: docsURL.path)
                    result["files"] = files
                    result["fileCount"] = files.count
                    NSLog("[CloudKit] Files in Documents: \(files)")
                } catch {
                    result["filesError"] = error.localizedDescription
                    NSLog("[CloudKit] Error listing files: \(error.localizedDescription)")
                }
            }

            completion(result)
        }
    }

    private func statusDescription(_ status: CKAccountStatus) -> String {
        switch status {
        case .available: return "available"
        case .noAccount: return "noAccount"
        case .restricted: return "restricted"
        case .temporarilyUnavailable: return "temporarilyUnavailable"
        @unknown default: return "unknown"
        }
    }
}
