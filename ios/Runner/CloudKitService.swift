import CloudKit
import Foundation

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
        FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }

    private init() {
        // Initialize CloudKit container
        // Note: Replace "iCloud.com.example.futureproof" with your actual container ID
        self.container = CKContainer(identifier: "iCloud.com.example.futureproof")
        self.privateDatabase = container.privateCloudDatabase

        // Ensure iCloud Drive directory exists
        setupICloudDriveDirectory()
    }

    // MARK: - iCloud Drive Setup

    private func setupICloudDriveDirectory() {
        guard let documentsURL = iCloudDocumentsURL else { return }

        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            do {
                try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
            } catch {
                // Log error but don't fail - directory will be created on first write
                NSLog("Failed to create iCloud Documents directory: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - File Name Validation

    /// Validate file name to prevent path traversal attacks
    private func validateFileName(_ fileName: String) -> Bool {
        // Only allow alphanumeric, underscore, hyphen, and dot
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "_.-"))
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
        // Validate file name
        guard validateFileName(fileName) else {
            completion(.failure("Invalid file name"))
            return
        }

        guard let documentsURL = iCloudDocumentsURL else {
            completion(.failure("iCloud container not available"))
            return
        }

        // Ensure directory exists
        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            do {
                try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
            } catch {
                completion(.failure("Failed to create iCloud Documents directory"))
                return
            }
        }

        let fileURL = documentsURL.appendingPathComponent("\(fileName).json")

        do {
            try jsonData.write(to: fileURL)
            completion(.success(fileURL.path))
        } catch {
            completion(.failure("Failed to write file"))
        }
    }

    /// Read JSON data from iCloud Drive
    func readFromiCloudDrive(fileName: String, completion: @escaping (ICloudDriveResult<Data>) -> Void) {
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
            completion(.failure("File not found"))
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            completion(.success(data))
        } catch {
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
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "VaultIndex", predicate: predicate)

        privateDatabase.fetch(withQuery: query) { result in
            switch result {
            case .success((let matchResults, _)):
                // Process results
                var vaultsData: [[String: Any]] = []

                for (_, result) in matchResults {
                    switch result {
                    case .success(let record):
                        if let vaultsDataField = record["vaults"] as? [String] {
                            // Parse vault IDs and metadata
                            for vaultJson in vaultsDataField {
                                if let data = vaultJson.data(using: .utf8),
                                   let vaultDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                    vaultsData.append(vaultDict)
                                }
                            }
                        }
                    case .failure(let error):
                        completion(nil, error)
                        return
                    }
                }

                let indexData: [String: Any] = [
                    "vaults": vaultsData,
                    "activeVaultID": matchResults.first?.record["activeVaultID"] as? String ?? ""
                ]

                completion(indexData, nil)

            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    /// Upload vault metadata to CloudKit
    func uploadVaultMetadata(vaultId: String, metadata: [String: Any], completion: @escaping (Error?) -> Void) {
        // Check if record exists
        let predicate = NSPredicate(format: "vaultID == %@", vaultId)
        let query = CKQuery(recordType: "VaultMetadata", predicate: predicate)

        privateDatabase.fetch(withQuery: query) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success((let matchResults, _)):
                // Try to find existing record
                var recordID: CKRecord.ID?

                for (_, result) in matchResults {
                    switch result {
                    case .success(let record):
                        recordID = record.recordID
                        break
                    case .failure:
                        continue
                    }
                }

                let record: CKRecord
                if let existingRecordID = recordID {
                    // Update existing record
                    record = CKRecord(recordType: "VaultMetadata", recordID: existingRecordID)
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
                self.privateDatabase.save(record) { saveResult in
                    switch saveResult {
                    case .success:
                        completion(nil)
                    case .failure(let error):
                        completion(error)
                    }
                }

            case .failure(let error):
                completion(error)
            }
        }
    }

    /// Delete vault metadata from CloudKit
    func deleteVaultMetadata(vaultId: String, completion: @escaping (Error?) -> Void) {
        let predicate = NSPredicate(format: "vaultID == %@", vaultId)
        let query = CKQuery(recordType: "VaultMetadata", predicate: predicate)

        privateDatabase.fetch(withQuery: query) { result in
            switch result {
            case .success((let matchResults, _)):
                for (_, result) in matchResults {
                    switch result {
                    case .success(let record):
                        // Delete record
                        self.privateDatabase.deleteRecord(withID: record.recordID) { deleteResult in
                            switch deleteResult {
                            case .success:
                                completion(nil)
                            case .failure(let error):
                                completion(error)
                            }
                        }
                        return
                    case .failure(let error):
                        completion(error)
                        return
                    }
                }
                // No record found
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
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
}
