import Foundation
import SwiftUI
import SwiftData

struct SearchView: View {
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var query = ""
    @State private var selectedEntry: JournalEntry?

    private var results: [JournalEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return entries }

        return entries.filter { entry in
            entry.dailyDopeMomentText.lowercased().contains(trimmed)
                || entry.foodText.lowercased().contains(trimmed)
                || entry.workoutText.lowercased().contains(trimmed)
                || entry.workText.lowercased().contains(trimmed)
        }
    }

    var body: some View {
        ZStack {
            AppBackground()

            if results.isEmpty {
                EmptyStateCard(
                    icon: "magnifyingglass",
                    title: "No matches",
                    subtitle: "Try a different keyword for your dope moment, food, workout, or work."
                )
                .padding(.horizontal)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(results) { entry in
                            EntryRow(entry: entry)
                                .onTapGesture { selectedEntry = entry }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Search entries")
        .sheet(item: $selectedEntry) { entry in
            EntryEditorSheet(entry: entry)
        }
    }
}
