import CloudKit
import Foundation

/// CloudKit service for vault synchronization
///
/// Manages CloudKit operations for syncing vault metadata and files
/// between devices via iCloud.
class CloudKitService {
    static let shared = CloudKitService()

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    private init() {
        // Initialize CloudKit container
        // Note: Replace "iCloud.com.example.futureproof" with your actual container ID
        self.container = CKContainer(identifier: "iCloud.com.example.futureproof")
        self.privateDatabase = container.privateCloudDatabase
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
