import PhotosUI
import SwiftData
import SwiftUI

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
