import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    private var todayDate: Date { Calendar.current.startOfDay(for: .now) }

    private var todayEntry: JournalEntry? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: todayDate) }
    }

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()
            EntryEditorView(entry: todayEntry, targetDate: todayDate)
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
    }
}
