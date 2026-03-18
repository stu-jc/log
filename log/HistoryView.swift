import SwiftUI
import SwiftData

struct HistoryView: View {
    enum Mode: String, CaseIterable {
        case list = "List"
        case calendar = "Calendar"
    }

    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var mode: Mode = .list
    @State private var month: Date = .now
    @State private var selectedEntry: JournalEntry?
    @State private var shareURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 14) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColors.backgroundSecondary.opacity(0.95))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal)

                if mode == .list {
                    if entries.isEmpty {
                        EmptyStateCard(
                            icon: "clock.arrow.circlepath",
                            title: "No history yet",
                            subtitle: "Save entries in Today to build your timeline."
                        )
                        .padding(.horizontal)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(entries) { entry in
                                    EntryRow(entry: entry)
                                        .onTapGesture { selectedEntry = entry }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                } else {
                    MonthCalendarView(month: $month, entries: entries) { entry in
                        selectedEntry = entry
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.top, 8)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shareURL = CSVExporter.export(entries: entries)
                    showShareSheet = shareURL != nil
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(AppColors.backgroundTertiary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            EntryEditorSheet(entry: entry, closeButtonTitle: "Back to History")
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }
}

struct MonthCalendarView: View {
    @Binding var month: Date
    let entries: [JournalEntry]
    let onSelectEntry: (JournalEntry) -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private var today: Date { calendar.startOfDay(for: .now) }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 18) {
                Button {
                    month = calendar.date(byAdding: .month, value: -1, to: month) ?? month
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.accentSoft)
                }

                Text(month, format: .dateTime.month(.wide).year())
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)

                Button {
                    month = calendar.date(byAdding: .month, value: 1, to: month) ?? month
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.accentSoft)
                }
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textSecondary)
                }

                let days = daysInMonth()
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let entry = entryFor(day)
                        let isToday = calendar.isDate(day, inSameDayAs: today)

                        Button {
                            if let entry {
                                onSelectEntry(entry)
                            }
                        } label: {
                            VStack(spacing: 5) {
                                Text("\(calendar.component(.day, from: day))")
                                    .font(.system(.subheadline, design: .rounded).weight(entry == nil ? .regular : .semibold))
                                    .foregroundColor(entry == nil ? AppColors.textSecondary : AppColors.textPrimary)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(
                                                entry == nil
                                                    ? (isToday ? AppColors.backgroundTertiary : Color.clear)
                                                    : AppColors.accentStrong.opacity(0.55)
                                            )
                                    )

                                Circle()
                                    .fill(entry == nil ? Color.clear : AppColors.secondary)
                                    .frame(width: 4, height: 4)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(entry == nil ? Color.clear : AppColors.accentStrong.opacity(0.18))
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 10)
        .padding(.horizontal)
    }

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstWeekInterval = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let lastWeekStart = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end.addingTimeInterval(-1))?.start,
              let lastWeekInterval = calendar.dateInterval(of: .weekOfMonth, for: lastWeekStart)
        else { return [] }

        var days: [Date?] = []
        var day = firstWeekInterval.start

        while day < lastWeekInterval.end {
            if day >= monthInterval.start && day < monthInterval.end {
                days.append(calendar.startOfDay(for: day))
            } else {
                days.append(nil)
            }
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        }

        return days
    }

    private func entryFor(_ day: Date) -> JournalEntry? {
        entries.first { calendar.isDate($0.date, inSameDayAs: day) }
    }
}
