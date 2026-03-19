import Foundation
import Photos
import SwiftData
import UIKit
import UniformTypeIdentifiers

enum ImageStore {
    private static let folderName = "FoodPhotos"

    static func saveImageData(_ data: Data) -> String? {
        guard let directory = imageDirectoryURL() else { return nil }

        let fileURL = directory.appendingPathComponent("\(UUID().uuidString).jpg")

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            return nil
        }
    }

    static func loadUIImage(at path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }

    static func deleteImage(at path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    static func pruneOrphanedFiles(referencedPaths: Set<String>) {
        guard let directory = imageDirectoryURL() else { return }

        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? []

        for url in urls where !referencedPaths.contains(url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func imageDirectoryURL() -> URL? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let directory = documents.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

enum StorageMaintenance {
    static func reconcilePhotoStore(entries: [JournalEntry], modelContext: ModelContext) {
        let referencedPaths = Set(entries.flatMap { $0.photos.map(\.localPath) })
        ImageStore.pruneOrphanedFiles(referencedPaths: referencedPaths)

        var didMutate = false

        for entry in entries {
            let missingPhotos = entry.photos.filter { !FileManager.default.fileExists(atPath: $0.localPath) }
            guard !missingPhotos.isEmpty else { continue }

            missingPhotos.forEach { modelContext.delete($0) }

            let hasRemainingPhoto = entry.photos.contains { FileManager.default.fileExists(atPath: $0.localPath) }
            let hasTextContent = !entry.dailyDopeMomentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !entry.foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !entry.workoutText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !entry.workText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            if !hasRemainingPhoto && !hasTextContent {
                modelContext.delete(entry)
            }

            didMutate = true
        }

        if didMutate {
            try? modelContext.save()
        }
    }
}

enum PhotoLibraryStore {
    static let defaultAlbumName = "Log Food"

    static func addImportedImage(
        data: Data,
        uniformTypeIdentifier: String?
    ) async {
        await addImportedImage(
            data: data,
            uniformTypeIdentifier: uniformTypeIdentifier,
            albumName: defaultAlbumName
        )
    }

    static func addImportedImage(
        data: Data,
        uniformTypeIdentifier: String?,
        albumName: String
    ) async {
        let status = await ensureAuthorization()
        guard status == .authorized || status == .limited else { return }

        do {
            let assetIdentifier = try await createAsset(from: data, uniformTypeIdentifier: uniformTypeIdentifier)
            let album = try await fetchOrCreateAlbum(named: albumName)
            try await addAsset(withLocalIdentifier: assetIdentifier, to: album)
        } catch {
            // Best-effort sync only. The local store remains the source of truth.
        }
    }

    private static func ensureAuthorization() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard currentStatus == .notDetermined else { return currentStatus }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    private static func createAsset(
        from data: Data,
        uniformTypeIdentifier: String?
    ) async throws -> String {
        var placeholderIdentifier: String?

        try await performChanges {
            let creationRequest = PHAssetCreationRequest.forAsset()
            let resourceOptions = PHAssetResourceCreationOptions()
            resourceOptions.uniformTypeIdentifier = uniformTypeIdentifier ?? UTType.jpeg.identifier
            creationRequest.addResource(with: .photo, data: data, options: resourceOptions)
            placeholderIdentifier = creationRequest.placeholderForCreatedAsset?.localIdentifier
        }

        guard let placeholderIdentifier else {
            throw PhotoLibraryError.assetCreationFailed
        }

        return placeholderIdentifier
    }

    private static func fetchOrCreateAlbum(named title: String) async throws -> PHAssetCollection {
        if let album = fetchAlbum(named: title) {
            return album
        }

        var placeholderIdentifier: String?

        try await performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            placeholderIdentifier = request.placeholderForCreatedAssetCollection.localIdentifier
        }

        if let placeholderIdentifier,
           let album = fetchAlbum(localIdentifier: placeholderIdentifier) {
            return album
        }

        if let album = fetchAlbum(named: title) {
            return album
        }

        throw PhotoLibraryError.albumCreationFailed
    }

    private static func addAsset(withLocalIdentifier localIdentifier: String, to album: PHAssetCollection) async throws {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            throw PhotoLibraryError.assetLookupFailed
        }

        try await performChanges {
            let changeRequest = PHAssetCollectionChangeRequest(for: album)
            changeRequest?.addAssets(NSArray(object: asset))
        }
    }

    private static func fetchAlbum(named title: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "localizedTitle == %@", title)

        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        return collections.firstObject
    }

    private static func fetchAlbum(localIdentifier: String) -> PHAssetCollection? {
        let collections = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        )
        return collections.firstObject
    }

    private static func performChanges(_ changes: @escaping () throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var capturedError: Error?

            PHPhotoLibrary.shared().performChanges({
                do {
                    try changes()
                } catch {
                    capturedError = error
                }
            }, completionHandler: { success, error in
                if let capturedError {
                    continuation.resume(throwing: capturedError)
                    return
                }

                if success {
                    continuation.resume(returning: ())
                    return
                }

                continuation.resume(throwing: error ?? PhotoLibraryError.performChangesFailed)
            })
        }
    }
}

enum PhotoLibraryError: Error {
    case assetCreationFailed
    case albumCreationFailed
    case assetLookupFailed
    case performChangesFailed
}

enum CSVExporter {
    static func export(entries: [JournalEntry], startDate: Date, endDate: Date) -> URL? {
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: min(startDate, endDate))
        let normalizedEnd = calendar.startOfDay(for: max(startDate, endDate))
        let endBoundary = calendar.date(byAdding: .day, value: 1, to: normalizedEnd) ?? normalizedEnd

        var lines = ["date,dailyDopeMomentText,foodText,workoutText,workText,photoCount"]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let filenameFormatter = DateFormatter()
        filenameFormatter.locale = Locale(identifier: "en_US_POSIX")
        filenameFormatter.dateFormat = "yyyy-MM-dd"

        let filteredEntries = entries
            .filter { $0.date >= normalizedStart && $0.date < endBoundary }
            .sorted(by: { $0.date < $1.date })

        for entry in filteredEntries {
            let line = [
                formatter.string(from: entry.date),
                escapeCSV(entry.dailyDopeMomentText),
                escapeCSV(entry.foodText),
                escapeCSV(entry.workoutText),
                escapeCSV(entry.workText),
                "\(entry.photos.count)"
            ].joined(separator: ",")
            lines.append(line)
        }

        let csv = lines.joined(separator: "\n")
        let timestampFormatter = DateFormatter()
        timestampFormatter.locale = Locale(identifier: "en_US_POSIX")
        timestampFormatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let startString = filenameFormatter.string(from: normalizedStart)
        let endString = filenameFormatter.string(from: normalizedEnd)
        let filename = "log-export-\(startString)-to-\(endString)-\(timestampFormatter.string(from: .now))-\(UUID().uuidString.prefix(6)).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try csv.data(using: .utf8)?.write(to: tempURL, options: .atomic)
            return tempURL
        } catch {
            return nil
        }
    }

    private static func escapeCSV(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\"", with: "\"\"")
            .replacingOccurrences(of: "\n", with: " ")
        return "\"\(escaped)\""
    }
}
