import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Today", systemImage: "sun.max")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock")
            }

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
        }
    }
}

struct TodayView: View {
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    private var todayDate: Date { Calendar.current.startOfDay(for: .now) }
    private var todayEntry: JournalEntry? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: todayDate) }
    }

    var body: some View {
        EntryEditorView(entry: todayEntry, targetDate: todayDate)
            .navigationTitle("Today")
    }
}

struct HistoryView: View {
    enum Mode: String, CaseIterable {
        case list = "List"
        case calendar = "Calendar"
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var mode: Mode = .list
    @State private var month: Date = .now
    @State private var selectedEntry: JournalEntry?
    @State private var shareURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        VStack {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if mode == .list {
                List(entries) { entry in
                    Button {
                        selectedEntry = entry
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date, format: .dateTime.year().month().day())
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(entry.previewText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                .listStyle(.plain)
            } else {
                MonthCalendarView(month: $month, entries: entries) { entry in
                    selectedEntry = entry
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal)
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Export") {
                    shareURL = CSVExporter.export(entries: entries)
                    showShareSheet = shareURL != nil
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            NavigationStack {
                EntryEditorView(entry: entry, targetDate: entry.date)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
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
        List(results) { entry in
            Button {
                selectedEntry = entry
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.date, format: .dateTime.year().month().day())
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(entry.previewText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Search")
        .searchable(text: $query, prompt: "Search food, workout, work")
        .sheet(item: $selectedEntry) { entry in
            NavigationStack {
                EntryEditorView(entry: entry, targetDate: entry.date)
            }
        }
    }
}

struct EntryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry?
    let targetDate: Date

    @State private var foodText = ""
    @State private var workoutText = ""
    @State private var workText = ""
    @State private var currentEntry: JournalEntry?
    @State private var photoPickerItems: [PhotosPickerItem] = []

    private var dayDate: Date { Calendar.current.startOfDay(for: targetDate) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(dayDate, format: .dateTime.weekday(.wide).month().day().year())
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Food")
                        .font(.title3.weight(.semibold))
                    TextEditor(text: $foodText)
                        .frame(minHeight: 110)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.quaternary)
                        }

                    HStack {
                        PhotosPicker(
                            selection: $photoPickerItems,
                            maxSelectionCount: max(0, 5 - (currentEntry?.photos.count ?? 0)),
                            matching: .images
                        ) {
                            Label("Add Photo", systemImage: "photo")
                        }
                        .disabled((currentEntry?.photos.count ?? 0) >= 5)

                        Spacer()
                        Text("\(currentEntry?.photos.count ?? 0)/5")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let photos = currentEntry?.photos, !photos.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                            ForEach(photos) { photo in
                                PhotoThumbnail(photo: photo) {
                                    deletePhoto(photo)
                                }
                            }
                        }
                    }
                }

                EntrySection(title: "Workout", text: $workoutText)
                EntrySection(title: "Work", text: $workText)

                Button("Save") {
                    saveNow()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Log")
        .toolbar {
            if currentEntry != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Delete", role: .destructive) {
                        deleteEntry()
                    }
                }
            }
        }
        .onAppear {
            loadEntry()
        }
        .onChange(of: foodText) { _, _ in autosave() }
        .onChange(of: workoutText) { _, _ in autosave() }
        .onChange(of: workText) { _, _ in autosave() }
        .onChange(of: photoPickerItems) { _, newItems in
            Task {
                await addPhotos(items: newItems)
            }
        }
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
        let entry = ensureEntry()
        entry.foodText = foodText
        entry.workoutText = workoutText
        entry.workText = workText
        entry.updatedAt = .now
        try? modelContext.save()
    }

    private func saveNow() {
        autosave()
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
        currentEntry?.updatedAt = .now
        try? modelContext.save()
    }

    private func deleteEntry() {
        guard let entry = currentEntry else { return }
        entry.photos.forEach { ImageStore.deleteImage(at: $0.localPath) }
        modelContext.delete(entry)
        try? modelContext.save()

        currentEntry = nil
        foodText = ""
        workoutText = ""
        workText = ""
        dismiss()
    }
}

struct EntrySection: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.weight(.semibold))
            TextEditor(text: $text)
                .frame(minHeight: 110)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.quaternary)
                }
        }
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
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.2))
                    .frame(width: 90, height: 90)
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white, .black.opacity(0.7))
                    .font(.title3)
            }
            .padding(4)
        }
    }
}

struct MonthCalendarView: View {
    @Binding var month: Date
    let entries: [JournalEntry]
    let onSelectEntry: (JournalEntry) -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    month = calendar.date(byAdding: .month, value: -1, to: month) ?? month
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(month, format: .dateTime.month(.wide).year())
                    .font(.headline)
                Spacer()
                Button {
                    month = calendar.date(byAdding: .month, value: 1, to: month) ?? month
                } label: {
                    Image(systemName: "chevron.right")
                }
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                let days = daysInMonth()
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let entry = entryFor(day)
                        Button {
                            if let entry {
                                onSelectEntry(entry)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(calendar.component(.day, from: day))")
                                    .font(.subheadline)
                                    .foregroundStyle(entry == nil ? Color.primary : Color.blue)
                                Circle()
                                    .fill(entry == nil ? Color.clear : Color.blue)
                                    .frame(width: 6, height: 6)
                            }
                            .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstWeekInterval = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let lastWeekStart = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end.addingTimeInterval(-1))?.start,
              let lastWeekInterval = calendar.dateInterval(of: .weekOfMonth, for: lastWeekStart)
        else {
            return []
        }

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
