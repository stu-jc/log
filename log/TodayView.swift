import Foundation
import SwiftUI
import SwiftData

struct TodayView: View {
    @EnvironmentObject private var navigation: AppNavigationModel
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    private var todayDate: Date { Calendar.current.startOfDay(for: .now) }

    private var todayEntry: JournalEntry? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: todayDate) }
    }

    var body: some View {
        ZStack {
            AppBackground()
            EntryEditorView(
                entry: todayEntry,
                targetDate: todayDate
            ) {
                navigation.showHistoryCalendar(for: todayDate)
            }
        }
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.large)
    }
}
