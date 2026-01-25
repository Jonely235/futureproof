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
        self.container = CKContainer(identifier: "iCloud.com.example.futureproof")
        self.privateDatabase = container.privateCloudDatabase
        setupICloudDriveDirectory()
    }

    private func setupICloudDriveDirectory() {
        guard let documentsURL = iCloudDocumentsURL else { return }
        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            do {
                try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
            } catch {
                NSLog("Failed to create iCloud Documents directory: \(error.localizedDescription)")
            }
        }
    }

    private func validateFileName(_ fileName: String) -> Bool {
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "_.-"))
        return fileName.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
            && !fileName.isEmpty
            && fileName.count <= 255
    }

    enum ICloudDriveResult<T> {
        case success(T)
        case failure(String)
    }

    func saveToiCloudDrive(fileName: String, jsonData: Data, completion: @escaping (ICloudDriveResult<String>) -> Void) {
        guard validateFileName(fileName) else {
            completion(.failure("Invalid file name"))
            return
        }
        guard let documentsURL = iCloudDocumentsURL else {
            completion(.failure("iCloud container not available"))
            return
        }
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

    func readFromiCloudDrive(fileName: String, completion: @escaping (ICloudDriveResult<Data>) -> Void) {
        guard validateFileName(fileName) else {
            completion(.failure("Invalid file name"))
            return
        }
        guard let documentsURL = iCloudDocumentsURL else {
            completion(.failure("iCloud container not available"))
            return
        }
        let fileURL = documentsURL.appendingPathComponent("\(fileName).json")
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

    func fileExistsInICloudDrive(fileName: String, completion: @escaping (Bool) -> Void) {
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

    func deleteFromICloudDrive(fileName: String, completion: @escaping (ICloudDriveResult<Void>) -> Void) {
        guard validateFileName(fileName) else {
            completion(.failure("Invalid file name"))
            return
        }
        guard let documentsURL = iCloudDocumentsURL else {
            completion(.failure("iCloud container not available"))
            return
        }
        let fileURL = documentsURL.appendingPathComponent("\(fileName).json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            completion(.success(()))
            return
        }
        do {
            try FileManager.default.removeItem(at: fileURL)
            completion(.success(()))
        } catch {
            completion(.failure("Failed to delete file"))
        }
    }

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
}
