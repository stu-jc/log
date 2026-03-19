import SwiftUI
import UIKit

struct EntryEditorSheet: View {
    let entry: JournalEntry

    var body: some View {
        NavigationStack {
            EntryEditorView(entry: entry, targetDate: entry.date, showsCloseButton: true)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColors.backgroundPrimary)
    }
}

struct HistoryEntryPagerSheet: View {
    let entries: [JournalEntry]
    @State private var selectedDay: Date

    init(entries: [JournalEntry], initialEntryDate: Date) {
        self.entries = entries
        _selectedDay = State(initialValue: Calendar.current.startOfDay(for: initialEntryDate))
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedDay) {
                ForEach(entries) { entry in
                    EntryEditorView(
                        entry: entry,
                        targetDate: entry.date,
                        showsCloseButton: true,
                        weekdayLocaleIdentifier: "sw_KE"
                    )
                        .tag(Calendar.current.startOfDay(for: entry.date))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.88), value: selectedDay)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColors.backgroundPrimary)
    }
}

struct EntryRow: View {
    let entry: JournalEntry
    var minimal: Bool = false
    var weekdayLocaleIdentifier: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 3) {
                Text(entry.date, format: .dateTime.day())
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(entry.date, format: .dateTime.month(.abbreviated))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(AppColors.accentStrong)
                    .textCase(.uppercase)
            }
            .frame(width: 64, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.dateBadgeGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(formattedWeekday)
                    .font(.system(minimal ? .title3 : .headline, design: .rounded).weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)

                if minimal, let minimalSummaryText {
                    Text(minimalSummaryText)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }

                if !minimal {
                    Text(entry.previewText)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        if !entry.dailyDopeMomentText.isEmpty {
                            Label("Dope", systemImage: "sparkles")
                                .foregroundColor(AppColors.accentStrong)
                        }
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
                                .foregroundColor(AppColors.accentStrong)
                        }
                    }
                    .font(.caption2)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.panelGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AppColors.shadowColor.opacity(0.38), radius: 18, x: 0, y: 12)
    }

    private var formattedWeekday: String {
        guard let weekdayLocaleIdentifier else {
            return entry.date.formatted(.dateTime.weekday(.wide))
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: weekdayLocaleIdentifier)
        formatter.dateFormat = "EEEE"
        return formatter.string(from: entry.date).capitalized(with: formatter.locale)
    }

    private var minimalSummaryText: String? {
        let dopeMoment = entry.dailyDopeMomentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !dopeMoment.isEmpty {
            return dopeMoment
        }

        let fallback = entry.previewText.trimmingCharacters(in: .whitespacesAndNewlines)
        return fallback == "No content" ? nil : fallback
    }
}

struct SectionCard<AdditionalContent: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let placeholder: String
    @Binding var text: String
    @ViewBuilder var additionalContent: () -> AdditionalContent

    init(
        title: String,
        icon: String,
        iconColor: Color,
        placeholder: String,
        text: Binding<String>,
        @ViewBuilder additionalContent: @escaping () -> AdditionalContent = { EmptyView() }
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.placeholder = placeholder
        self._text = text
        self.additionalContent = additionalContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 16) {
                ZStack(alignment: .topLeading) {
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(placeholder)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.top, 10)
                            .padding(.leading, 8)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 126)
                        .padding(.horizontal, 4)
                        .foregroundColor(AppColors.textPrimary)
                        .tint(AppColors.accentStrong)
                }

                additionalContent()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.inputGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    .blur(radius: 0.5)
                    .mask(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.white, .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
            .shadow(color: AppColors.shadowColor.opacity(0.28), radius: 14, x: 0, y: 8)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
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
                    .fill(AppColors.inputGradient)
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
                .stroke(AppColors.divider, lineWidth: 1)
        )
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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
