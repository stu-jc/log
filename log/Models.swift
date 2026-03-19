import Foundation
import SwiftData

@Model
final class JournalEntry {
    var date: Date
    var dailyDopeMomentText: String
    var foodText: String
    var workoutText: String
    var workText: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \FoodPhoto.entry) var photos: [FoodPhoto]

    init(
        date: Date,
        dailyDopeMomentText: String = "",
        foodText: String = "",
        workoutText: String = "",
        workText: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        photos: [FoodPhoto] = []
    ) {
        self.date = date
        self.dailyDopeMomentText = dailyDopeMomentText
        self.foodText = foodText
        self.workoutText = workoutText
        self.workText = workText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.photos = photos
    }

    var previewText: String {
        let candidates = [dailyDopeMomentText, foodText, workoutText, workText]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let first = candidates.first(where: { !$0.isEmpty }) {
            return String(first.prefix(80))
        }
        return "No content"
    }
}

@Model
final class FoodPhoto {
    var id: UUID
    var localPath: String
    var createdAt: Date
    var entry: JournalEntry?

    init(localPath: String, entry: JournalEntry? = nil, createdAt: Date = .now) {
        self.id = UUID()
        self.localPath = localPath
        self.entry = entry
        self.createdAt = createdAt
    }
}
