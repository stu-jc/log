import SwiftUI
import SwiftData
import PhotosUI
import UIKit

// MARK: - Color Theme
enum AppColors {
    static let accent = Color(hex: "79B8FF")
    static let accentSoft = Color(hex: "B9D8FF")
    static let accentStrong = Color(hex: "4A84C4")

    static let secondary = Color(hex: "8FB58A")
    static let warning = Color(hex: "C98A64")
    static let error = Color(hex: "FF6B6B")
    static let success = Color(hex: "8FCEB2")
    static let info = Color(hex: "8BA7C8")

    static let backgroundPrimary = Color(hex: "090C12")
    static let backgroundSecondary = Color(hex: "111722")
    static let backgroundTertiary = Color(hex: "1A2330")
    static let cardBackground = Color(hex: "151E2A")
    static let cardBackgroundStrong = Color(hex: "1E2A3A")

    static let textPrimary = Color(hex: "EEF1F5")
    static let textSecondary = Color(hex: "B4BDC9")
    static let textTertiary = Color(hex: "7E8A99")

    static let tabBarBackground = Color(hex: "0B1018")

    static var appGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "070B12"),
                Color(hex: "101828"),
                Color(hex: "26241F")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [cardBackgroundStrong, cardBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentSoft, accentStrong],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var headerGradient: LinearGradient {
        LinearGradient(
            colors: [accentStrong.opacity(0.34), Color(hex: "403729").opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 10)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundColor(AppColors.backgroundPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(AppColors.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(AppColors.backgroundTertiary)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Main Views
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label("Today", systemImage: "sun.max.fill") }
            .tag(0)

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock.fill") }
            .tag(1)

            NavigationStack {
                SearchView()
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(2)
        }
        .preferredColorScheme(.dark)
        .tint(AppColors.accent)
        .onAppear { configureTabBarAppearance() }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.tabBarBackground)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.06)

        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = UIColor(AppColors.textTertiary)
        normal.titleTextAttributes = [.foregroundColor: UIColor(AppColors.textTertiary)]

        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = UIColor(AppColors.accentSoft)
        selected.titleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]

        appearance.inlineLayoutAppearance = appearance.stackedLayoutAppearance
        appearance.compactInlineLayoutAppearance = appearance.stackedLayoutAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(AppColors.textTertiary)
    }
}

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
            NavigationStack {
                EntryEditorView(
                    entry: entry,
                    targetDate: entry.date,
                    showsCloseButton: true,
                    closeButtonTitle: "Back to History"
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColors.backgroundSecondary)
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }
}

struct EntryRow: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 3) {
                Text(entry.date, format: .dateTime.day())
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(entry.date, format: .dateTime.month(.abbreviated))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(AppColors.accentSoft)
                    .textCase(.uppercase)
            }
            .frame(width: 64, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.accentStrong.opacity(0.28))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColors.accentSoft.opacity(0.35), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.date, format: .dateTime.weekday(.wide))
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text(entry.previewText)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    if !entry.foodText.isEmpty {
                        Label("Food", systemImage: "fork.knife")
                            .foregroundColor(AppColors.secondary)
                    }
                    if !entry.workoutText.isEmpty {
                        Label("Workout", systemImage: "figure.run")
                            .foregroundColor(AppColors.info)
                    }
                    if !entry.workText.isEmpty {
                        Label("Work", systemImage: "briefcase")
                            .foregroundColor(AppColors.warning)
                    }
                    if !entry.photos.isEmpty {
                        Label("\(entry.photos.count)", systemImage: "photo")
                            .foregroundColor(AppColors.accentSoft)
                    }
                }
                .font(.caption2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.32), radius: 12, x: 0, y: 8)
    }
}

struct SearchView: View {
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var query = ""
    @State private var selectedEntry: JournalEntry?

    private var results: [JournalEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return entries }

        return entries.filter { entry in
            entry.foodText.lowercased().contains(trimmed)
                || entry.workoutText.lowercased().contains(trimmed)
                || entry.workText.lowercased().contains(trimmed)
        }
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            if results.isEmpty {
                EmptyStateCard(
                    icon: "magnifyingglass",
                    title: "No matches",
                    subtitle: "Try a different keyword for food, workout, or work."
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
            NavigationStack {
                EntryEditorView(
                    entry: entry,
                    targetDate: entry.date,
                    showsCloseButton: true,
                    closeButtonTitle: "Back to Search"
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColors.backgroundSecondary)
        }
    }
}

struct EntryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry?
    let targetDate: Date
    var showsCloseButton: Bool = false
    var closeButtonTitle: String = "Close"

    @State private var foodText = ""
    @State private var workoutText = ""
    @State private var workText = ""
    @State private var currentEntry: JournalEntry?
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showSaveFeedback = false
    @State private var saveFeedbackText = "Saved"

    private var dayDate: Date { Calendar.current.startOfDay(for: targetDate) }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dayDate, format: .dateTime.weekday(.wide))
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundColor(AppColors.textPrimary)
                            Text(dayDate, format: .dateTime.month().day().year())
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            if isEntryComplete {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title2)
                                    .foregroundColor(AppColors.success)
                            }

                            if !showsCloseButton && hasEntryContent {
                                Button("Clear") {
                                    deleteEntry(shouldDismiss: false)
                                    presentSaveFeedback("Cleared")
                                }
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(AppColors.backgroundPrimary.opacity(0.45))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppColors.headerGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                    SectionCard(
                        title: "Food",
                        icon: "fork.knife.circle.fill",
                        iconColor: AppColors.secondary,
                        text: $foodText,
                        flatFieldStyle: !showsCloseButton
                    ) {
                        PhotosPicker(
                            selection: $photoPickerItems,
                            maxSelectionCount: max(0, 5 - (currentEntry?.photos.count ?? 0)),
                            matching: .images
                        ) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.stack")
                                Text("Add Photos")
                            }
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(AppColors.backgroundTertiary)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .disabled((currentEntry?.photos.count ?? 0) >= 5)

                        if let photos = currentEntry?.photos, !photos.isEmpty {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                                ForEach(photos) { photo in
                                    PhotoThumbnail(photo: photo) { deletePhoto(photo) }
                                }
                            }
                            .padding(.top, 6)
                        }

                        HStack {
                            Spacer()
                            Text("\(currentEntry?.photos.count ?? 0)/5 photos")
                                .font(.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }

                    SectionCard(
                        title: "Workout",
                        icon: "figure.run.circle.fill",
                        iconColor: AppColors.info,
                        text: $workoutText,
                        flatFieldStyle: !showsCloseButton
                    )

                    SectionCard(
                        title: "Work",
                        icon: "briefcase.circle.fill",
                        iconColor: AppColors.warning,
                        text: $workText,
                        flatFieldStyle: !showsCloseButton
                    )

                    Button("Save Entry") {
                        autosave()
                        if showsCloseButton {
                            dismiss()
                        } else {
                            presentSaveFeedback("Saved")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 4)
                }
                .padding(.horizontal)
                .padding(.top, showsCloseButton ? 10 : 2)
                .padding(.bottom, showsCloseButton ? 94 : 24)
            }
        }
        .navigationTitle(showsCloseButton ? "Log" : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(showsCloseButton ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            if currentEntry != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        deleteEntry(shouldDismiss: true)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(AppColors.error)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if showsCloseButton {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.down.circle.fill")
                            Text(closeButtonTitle)
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal)
                .padding(.top, 6)
                .padding(.bottom, 8)
                .background(
                    LinearGradient(
                        colors: [
                            AppColors.backgroundPrimary.opacity(0),
                            AppColors.backgroundPrimary.opacity(0.82),
                            AppColors.backgroundPrimary
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
        }
        .overlay(alignment: .top) {
            if showSaveFeedback {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(saveFeedbackText)
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(AppColors.backgroundPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(AppColors.success)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear { loadEntry() }
        .onChange(of: foodText) { _, _ in autosave() }
        .onChange(of: workoutText) { _, _ in autosave() }
        .onChange(of: workText) { _, _ in autosave() }
        .onChange(of: photoPickerItems) { _, newItems in
            Task { await addPhotos(items: newItems) }
        }
    }

    private var isEntryComplete: Bool {
        !trimmedFoodText.isEmpty && !trimmedWorkoutText.isEmpty && !trimmedWorkText.isEmpty
    }

    private var trimmedFoodText: String {
        foodText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedWorkoutText: String {
        workoutText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedWorkText: String {
        workText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasEntryContent: Bool {
        !trimmedFoodText.isEmpty
            || !trimmedWorkoutText.isEmpty
            || !trimmedWorkText.isEmpty
            || !(currentEntry?.photos.isEmpty ?? true)
    }

    private func loadEntry() {
        if let entry {
            currentEntry = entry
            foodText = entry.foodText
            workoutText = entry.workoutText
            workText = entry.workText
        } else {
            currentEntry = fetchEntry(for: dayDate)
            foodText = currentEntry?.foodText ?? ""
            workoutText = currentEntry?.workoutText ?? ""
            workText = currentEntry?.workText ?? ""
        }
    }

    private func fetchEntry(for day: Date) -> JournalEntry? {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.date == day }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func ensureEntry() -> JournalEntry {
        if let currentEntry {
            return currentEntry
        }

        if let existing = fetchEntry(for: dayDate) {
            currentEntry = existing
            return existing
        }

        let newEntry = JournalEntry(date: dayDate)
        modelContext.insert(newEntry)
        currentEntry = newEntry
        return newEntry
    }

    private func autosave() {
        guard hasEntryContent else {
            if let entry = currentEntry {
                deleteEntry(entry, shouldDismiss: false)
            }
            return
        }

        let entry = ensureEntry()
        let didChange =
            entry.foodText != foodText
            || entry.workoutText != workoutText
            || entry.workText != workText

        guard didChange else { return }

        entry.foodText = foodText
        entry.workoutText = workoutText
        entry.workText = workText
        entry.updatedAt = .now
        try? modelContext.save()
    }

    private func presentSaveFeedback(_ text: String) {
        guard !showsCloseButton else { return }
        saveFeedbackText = text
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            showSaveFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.2)) {
                showSaveFeedback = false
            }
        }
    }

    private func addPhotos(items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        let entry = ensureEntry()
        let remaining = max(0, 5 - entry.photos.count)
        guard remaining > 0 else {
            photoPickerItems = []
            return
        }

        for item in items.prefix(remaining) {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            guard let path = ImageStore.saveImageData(data) else { continue }
            let photo = FoodPhoto(localPath: path, entry: entry)
            modelContext.insert(photo)
            entry.photos.append(photo)
        }

        entry.updatedAt = .now
        try? modelContext.save()
        photoPickerItems = []
    }

    private func deletePhoto(_ photo: FoodPhoto) {
        ImageStore.deleteImage(at: photo.localPath)
        modelContext.delete(photo)
        if let entry = currentEntry {
            if entry.photos.count <= 1 && trimmedFoodText.isEmpty && trimmedWorkoutText.isEmpty && trimmedWorkText.isEmpty {
                deleteEntry(entry, shouldDismiss: false)
            } else {
                entry.updatedAt = .now
                try? modelContext.save()
            }
        }
    }

    private func deleteEntry(shouldDismiss: Bool) {
        guard let entry = currentEntry else { return }
        deleteEntry(entry, shouldDismiss: shouldDismiss)
    }

    private func deleteEntry(_ entry: JournalEntry, shouldDismiss: Bool) {
        entry.photos.forEach { ImageStore.deleteImage(at: $0.localPath) }
        modelContext.delete(entry)
        try? modelContext.save()

        currentEntry = nil
        foodText = ""
        workoutText = ""
        workText = ""
        if shouldDismiss {
            dismiss()
        }
    }
}

struct SectionCard<AdditionalContent: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var flatFieldStyle: Bool = false
    @Binding var text: String
    @ViewBuilder var additionalContent: () -> AdditionalContent

    init(
        title: String,
        icon: String,
        iconColor: Color,
        text: Binding<String>,
        flatFieldStyle: Bool = false,
        @ViewBuilder additionalContent: @escaping () -> AdditionalContent = { EmptyView() }
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.flatFieldStyle = flatFieldStyle
        self._text = text
        self.additionalContent = additionalContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 110)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(flatFieldStyle ? AppColors.backgroundPrimary.opacity(0.38) : AppColors.backgroundTertiary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(flatFieldStyle ? 0.18 : 0.08), lineWidth: 1)
                )
                .foregroundColor(AppColors.textPrimary)

            additionalContent()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(flatFieldStyle ? AnyShapeStyle(AppColors.backgroundSecondary) : AnyShapeStyle(AppColors.cardGradient))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: flatFieldStyle ? .clear : .black.opacity(0.4), radius: 16, x: 0, y: 10)
    }
}

struct PhotoThumbnail: View {
    let photo: FoodPhoto
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = ImageStore.loadUIImage(at: photo.localPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.backgroundTertiary)
                    .frame(width: 80, height: 80)
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white, AppColors.error.opacity(0.85))
                    .font(.title3)
            }
            .padding(4)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
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

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(AppColors.accentSoft)
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            Text(subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

// MARK: - Supporting Types
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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
        .modelContainer(for: [JournalEntry.self, FoodPhoto.self], inMemory: true)
}
