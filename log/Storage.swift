import Foundation
import UIKit

enum ImageStore {
    static func saveImageData(_ data: Data) -> String? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let directory = documents.appendingPathComponent("FoodPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

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
}

enum CSVExporter {
    static func export(entries: [JournalEntry]) -> URL? {
        var lines = ["date,foodText,workoutText,workText,photoCount"]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for entry in entries.sorted(by: { $0.date < $1.date }) {
            let line = [
                formatter.string(from: entry.date),
                escapeCSV(entry.foodText),
                escapeCSV(entry.workoutText),
                escapeCSV(entry.workText),
                "\(entry.photos.count)"
            ].joined(separator: ",")
            lines.append(line)
        }

        let csv = lines.joined(separator: "\n")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("log-export.csv")

        do {
            try csv.data(using: .utf8)?.write(to: tempURL)
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
