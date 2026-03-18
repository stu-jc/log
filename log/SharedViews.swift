import SwiftUI
import UIKit

struct EntryEditorSheet: View {
    let entry: JournalEntry
    let closeButtonTitle: String

    var body: some View {
        NavigationStack {
            EntryEditorView(
                entry: entry,
                targetDate: entry.date,
                showsCloseButton: true,
                closeButtonTitle: closeButtonTitle
            )
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColors.backgroundSecondary)
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
