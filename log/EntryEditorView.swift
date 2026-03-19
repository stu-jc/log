import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct EntryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry?
    let targetDate: Date
    var showsCloseButton: Bool = false
    var weekdayLocaleIdentifier: String? = nil
    var onPrimarySave: (() -> Void)? = nil

    @State private var dailyDopeMomentText = ""
    @State private var foodText = ""
    @State private var workoutText = ""
    @State private var workText = ""
    @State private var currentEntry: JournalEntry?
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showSaveFeedback = false
    @State private var saveFeedbackText = "Saved"
    @State private var isCompletingPrimarySave = false

    private var dayDate: Date { Calendar.current.startOfDay(for: targetDate) }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    editorHeader

                    VStack(spacing: 0) {
                        SectionCard(
                            title: "Daily Dope Moment",
                            icon: "sparkles.circle.fill",
                            iconColor: AppColors.accentStrong,
                            placeholder: "The best thing about this day.",
                            text: $dailyDopeMomentText
                        )

                        Divider()
                            .overlay(AppColors.divider)
                            .padding(.horizontal, 18)

                        SectionCard(
                            title: "Food",
                            icon: "fork.knife.circle.fill",
                            iconColor: AppColors.secondary,
                            placeholder: "Meals, cravings, groceries, photos.",
                            text: $foodText
                        ) {
                            PhotosPicker(
                                selection: $photoPickerItems,
                                maxSelectionCount: max(0, 5 - photoCount),
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
                                        .fill(AppColors.inputGradient)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(AppColors.divider, lineWidth: 1)
                                )
                                .shadow(color: AppColors.shadowColor.opacity(0.28), radius: 10, x: 0, y: 4)
                            }
                            .disabled(photoCount >= 5)

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
                                Text("\(photoCount)/5 photos")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }

                        Divider()
                            .overlay(AppColors.divider)
                            .padding(.horizontal, 18)

                        SectionCard(
                            title: "Workout",
                            icon: "figure.run.circle.fill",
                            iconColor: AppColors.info,
                            placeholder: "Training, movement, steps, energy.",
                            text: $workoutText
                        )

                        Divider()
                            .overlay(AppColors.divider)
                            .padding(.horizontal, 18)

                        SectionCard(
                            title: "Work",
                            icon: "briefcase.circle.fill",
                            iconColor: AppColors.warning,
                            placeholder: "Work, priorities, what moved forward.",
                            text: $workText
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(AppColors.panelGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppColors.divider, lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.14), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: AppColors.shadowColor.opacity(0.42), radius: 26, x: 0, y: 18)

                    Button("Save Entry") {
                        handleSaveTapped()
                    }
                    .buttonStyle(PrimaryButtonStyle(darker: true))
                    .disabled(isCompletingPrimarySave || !hasEntryContent)
                    .opacity(isCompletingPrimarySave || !hasEntryContent ? 0.72 : 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, showsCloseButton ? 14 : 8)
                .padding(.bottom, 28)
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
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
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
        .overlay(alignment: .top) {
            if showSaveFeedback {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(saveFeedbackText)
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(AppColors.success)
                )
                .overlay(
                    Capsule()
                        .stroke(AppColors.success.opacity(0.25), lineWidth: 1)
                )
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear { loadEntry() }
        .onChange(of: dailyDopeMomentText) { _, _ in autosave() }
        .onChange(of: foodText) { _, _ in autosave() }
        .onChange(of: workoutText) { _, _ in autosave() }
        .onChange(of: workText) { _, _ in autosave() }
        .onChange(of: photoPickerItems) { _, newItems in
            Task { await addPhotos(items: newItems) }
        }
    }

    private var editorHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(formattedWeekday)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(dayDate, format: .dateTime.month().day().year())
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 10) {
                if isEntryComplete {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete")
                    }
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(AppColors.success)
                }

                if !showsCloseButton && hasEntryContent {
                    Button("Clear") {
                        deleteEntry(shouldDismiss: false)
                        presentSaveFeedback("Cleared")
                    }
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(AppColors.inputGradient)
                    )
                    .overlay(
                        Capsule()
                            .stroke(AppColors.divider, lineWidth: 1)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.headerGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.16), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AppColors.shadowColor.opacity(0.34), radius: 24, x: 0, y: 16)
    }

    private var isEntryComplete: Bool {
        !trimmedDailyDopeMomentText.isEmpty
            && !trimmedFoodText.isEmpty
            && !trimmedWorkoutText.isEmpty
            && !trimmedWorkText.isEmpty
    }

    private var formattedWeekday: String {
        guard let weekdayLocaleIdentifier else {
            return dayDate.formatted(.dateTime.weekday(.wide))
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: weekdayLocaleIdentifier)
        formatter.dateFormat = "EEEE"
        return formatter.string(from: dayDate).capitalized(with: formatter.locale)
    }

    private var trimmedDailyDopeMomentText: String {
        dailyDopeMomentText.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private var photoCount: Int {
        currentEntry?.photos.count ?? 0
    }

    private var hasEntryContent: Bool {
        !trimmedDailyDopeMomentText.isEmpty
            || !trimmedFoodText.isEmpty
            || !trimmedWorkoutText.isEmpty
            || !trimmedWorkText.isEmpty
            || photoCount > 0
    }

    private func handleSaveTapped() {
        let shouldRouteToHistory = !showsCloseButton && hasEntryContent

        autosave()

        guard shouldRouteToHistory else {
            if showsCloseButton {
                dismiss()
            } else {
                presentSaveFeedback("Saved")
            }
            return
        }

        isCompletingPrimarySave = true
        presentSaveFeedback("Saved")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            onPrimarySave?()
            isCompletingPrimarySave = false
        }
    }

    private func loadEntry() {
        if let entry {
            currentEntry = entry
            dailyDopeMomentText = entry.dailyDopeMomentText
            foodText = entry.foodText
            workoutText = entry.workoutText
            workText = entry.workText
        } else {
            currentEntry = fetchEntry(for: dayDate)
            dailyDopeMomentText = currentEntry?.dailyDopeMomentText ?? ""
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
            entry.dailyDopeMomentText != dailyDopeMomentText
            || entry.foodText != foodText
            || entry.workoutText != workoutText
            || entry.workText != workText

        guard didChange else { return }

        entry.dailyDopeMomentText = dailyDopeMomentText
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

            let uniformTypeIdentifier = item.supportedContentTypes.first(where: { $0.conforms(to: .image) })?.identifier
            await PhotoLibraryStore.addImportedImage(
                data: data,
                uniformTypeIdentifier: uniformTypeIdentifier
            )
        }

        entry.updatedAt = .now
        try? modelContext.save()
        photoPickerItems = []
    }

    private func deletePhoto(_ photo: FoodPhoto) {
        ImageStore.deleteImage(at: photo.localPath)
        modelContext.delete(photo)

        if let entry = currentEntry {
            if entry.photos.count <= 1
                && trimmedDailyDopeMomentText.isEmpty
                && trimmedFoodText.isEmpty
                && trimmedWorkoutText.isEmpty
                && trimmedWorkText.isEmpty
            {
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
        dailyDopeMomentText = ""
        foodText = ""
        workoutText = ""
        workText = ""

        if shouldDismiss {
            dismiss()
        }
    }
}
