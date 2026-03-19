import Foundation
import SwiftUI
import SwiftData

enum HistoryDisplayMode: String, CaseIterable {
    case list = "List"
    case calendar = "Calendar"
}

struct HistoryView: View {
    @EnvironmentObject private var navigation: AppNavigationModel
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var month: Date = .now
    @State private var selectedEntry: JournalEntry?
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var showExportSheet = false
    @State private var pendingShareURL: URL?
    @State private var exportStartDate: Date = .now
    @State private var exportEndDate: Date = .now

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 14) {
                Picker("Mode", selection: $navigation.historyMode) {
                    ForEach(HistoryDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColors.inputGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.divider, lineWidth: 1)
                )
                .shadow(color: AppColors.shadowColor.opacity(0.32), radius: 18, x: 0, y: 12)
                .padding(.horizontal)

                TabView(selection: $navigation.historyMode) {
                    historyListPage
                        .tag(HistoryDisplayMode.list)

                    historyCalendarPage
                        .tag(HistoryDisplayMode.calendar)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.45, dampingFraction: 0.9), value: navigation.historyMode)
            }
            .padding(.top, 8)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentExportSheet()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(AppColors.inputGradient)
                        )
                        .overlay(
                            Circle()
                                .stroke(AppColors.divider, lineWidth: 1)
                        )
                }
            }
        }
        .onAppear {
            applyHistoryFocusRequest()
        }
        .onChange(of: navigation.historyFocusRequest?.id) { _, _ in
            applyHistoryFocusRequest()
        }
        .sheet(isPresented: $showExportSheet, onDismiss: {
            if let pendingShareURL {
                shareURL = pendingShareURL
                showShareSheet = true
                self.pendingShareURL = nil
            }
        }) {
            DateRangeExportSheet(
                startDate: exportStartDate,
                endDate: exportEndDate
            ) { startDate, endDate in
                let url = CSVExporter.export(entries: entries, startDate: startDate, endDate: endDate)
                pendingShareURL = url
                return url
            }
        }
        .sheet(item: $selectedEntry) { entry in
            HistoryEntryPagerSheet(entries: entries, initialEntryDate: entry.date)
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }

    private func presentExportSheet() {
        let defaultStartDate = entries.last?.date ?? .now
        let defaultEndDate = entries.first?.date ?? defaultStartDate
        exportStartDate = defaultStartDate
        exportEndDate = defaultEndDate
        pendingShareURL = nil
        showExportSheet = true
    }

    @ViewBuilder
    private var historyListPage: some View {
        if entries.isEmpty {
            VStack {
                EmptyStateCard(
                    icon: "clock.arrow.circlepath",
                    title: "No history yet",
                    subtitle: "Save entries in Today to build your timeline."
                )
                .padding(.horizontal)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(entries) { entry in
                        EntryRow(
                            entry: entry,
                            minimal: true,
                            weekdayLocaleIdentifier: "sw_KE"
                        )
                            .onTapGesture { selectedEntry = entry }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var historyCalendarPage: some View {
        VStack(spacing: 0) {
            MonthCalendarView(
                month: $month,
                entries: entries,
                highlightedDate: navigation.historyHighlightedDate
            ) { entry in
                selectedEntry = entry
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func applyHistoryFocusRequest() {
        guard let request = navigation.historyFocusRequest else { return }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.92)) {
            navigation.historyMode = .calendar
            month = request.date
        }

        navigation.historyFocusRequest = nil
    }
}

struct MonthCalendarView: View {
    @Binding var month: Date
    let entries: [JournalEntry]
    let highlightedDate: Date?
    let onSelectEntry: (JournalEntry) -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private var today: Date { calendar.startOfDay(for: .now) }
    private var swahiliWeekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sw_KE")
        return formatter.veryShortStandaloneWeekdaySymbols
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 18) {
                Button {
                    month = calendar.date(byAdding: .month, value: -1, to: month) ?? month
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.accentSoft, AppColors.accentStrong)
                }

                Text(month, format: .dateTime.month(.wide).year())
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)

                Button {
                    month = calendar.date(byAdding: .month, value: 1, to: month) ?? month
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.accentSoft, AppColors.accentStrong)
                }
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(swahiliWeekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textSecondary)
                }

                let days = daysInMonth()
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let entry = entryFor(day)
                        let isToday = calendar.isDate(day, inSameDayAs: today)
                        let isHighlighted = highlightedDate.map { calendar.isDate(day, inSameDayAs: $0) } ?? false

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
                                                    ? AnyShapeStyle(isToday ? AppColors.backgroundTertiary : Color.clear)
                                                    : AnyShapeStyle(isHighlighted ? AppColors.accentGradient : AppColors.dateBadgeGradient)
                                            )
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                isHighlighted ? Color.white.opacity(0.38) : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )

                                Circle()
                                    .fill(entry == nil ? Color.clear : AppColors.secondary)
                                    .frame(width: 4, height: 4)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(
                                        entry == nil
                                            ? (isHighlighted ? AppColors.accent.opacity(0.12) : Color.clear)
                                            : (isHighlighted ? AppColors.accent.opacity(0.16) : AppColors.accent.opacity(0.06))
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(
                                        isHighlighted ? Color.white.opacity(0.12) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                            .scaleEffect(isHighlighted ? 1.03 : 1)
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHighlighted)
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
                .fill(AppColors.panelGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.16), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AppColors.shadowColor.opacity(0.42), radius: 22, x: 0, y: 16)
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

struct DateRangeExportSheet: View {
    @Environment(\.dismiss) private var dismiss

    let exportAction: (Date, Date) -> URL?
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var showingError = false

    init(
        startDate: Date,
        endDate: Date,
        exportAction: @escaping (Date, Date) -> URL?
    ) {
        self.exportAction = exportAction
        _startDate = State(initialValue: startDate)
        _endDate = State(initialValue: endDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Export a date range")
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("The CSV includes only journal text and photo counts.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        VStack(spacing: 12) {
                            DatePicker(
                                "Start",
                                selection: $startDate,
                                displayedComponents: .date
                            )
                            .tint(AppColors.accentStrong)

                            Divider()
                                .overlay(AppColors.divider.opacity(0.8))

                            DatePicker(
                                "End",
                                selection: $endDate,
                                displayedComponents: .date
                            )
                            .tint(AppColors.accentStrong)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppColors.panelGradient)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(AppColors.divider, lineWidth: 1)
                        )

                        Button {
                            export()
                        } label: {
                            Text("Export CSV")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textPrimary)
                }
            }
            .alert("Couldn’t create export", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Try again.")
            }
        }
    }

    private func export() {
        guard exportAction(startDate, endDate) != nil else {
            showingError = true
            return
        }

        dismiss()
    }
}
