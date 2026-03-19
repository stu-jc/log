import SwiftUI
import SwiftData
import UIKit
import Foundation
import Combine

enum AppTab: Hashable {
    case today
    case history
    case search
}

final class AppNavigationModel: ObservableObject {
    struct HistoryFocusRequest: Equatable {
        let id = UUID()
        let date: Date
    }

    @Published var selectedTab: AppTab = .today
    @Published var historyMode: HistoryDisplayMode = .list
    @Published var historyFocusRequest: HistoryFocusRequest?
    @Published var historyHighlightedDate: Date?

    func showHistoryCalendar(for date: Date) {
        let day = Calendar.current.startOfDay(for: date)

        historyMode = .calendar
        historyFocusRequest = HistoryFocusRequest(date: day)
        historyHighlightedDate = day

        withAnimation(.spring(response: 0.55, dampingFraction: 0.92)) {
            selectedTab = .history
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            guard let self else { return }
            guard let historyHighlightedDate = self.historyHighlightedDate,
                  Calendar.current.isDate(historyHighlightedDate, inSameDayAs: day)
            else { return }
            self.historyHighlightedDate = nil
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var didRunStorageMaintenance = false
    @StateObject private var navigation = AppNavigationModel()

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tag(AppTab.today)
            .tabItem { Label("Today", systemImage: "sun.max.fill") }

            NavigationStack {
                HistoryView()
            }
            .tag(AppTab.history)
            .tabItem { Label("History", systemImage: "clock.fill") }

            NavigationStack {
                SearchView()
            }
            .tag(AppTab.search)
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
        .environmentObject(navigation)
        .preferredColorScheme(.dark)
        .tint(AppColors.accent)
        .onAppear {
            if !didRunStorageMaintenance {
                StorageMaintenance.reconcilePhotoStore(entries: entries, modelContext: modelContext)
                didRunStorageMaintenance = true
            }

            AppChromeAppearance.configure()
        }
    }
}

private enum AppChromeAppearance {
    static func configure() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(AppColors.tabBarBackground.opacity(0.88))
        appearance.shadowColor = UIColor(AppColors.divider)

        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = UIColor(AppColors.textTertiary)
        normal.titleTextAttributes = [.foregroundColor: UIColor(AppColors.textTertiary)]

        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = UIColor(AppColors.accent)
        selected.titleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]

        appearance.inlineLayoutAppearance = appearance.stackedLayoutAppearance
        appearance.compactInlineLayoutAppearance = appearance.stackedLayoutAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(AppColors.textTertiary)

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithTransparentBackground()
        navigationAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        navigationAppearance.backgroundColor = UIColor(AppColors.backgroundPrimary.opacity(0.65))
        navigationAppearance.shadowColor = .clear
        navigationAppearance.titleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]
        navigationAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = UIColor(AppColors.accent)

        let segmented = UISegmentedControl.appearance()
        segmented.selectedSegmentTintColor = UIColor(AppColors.accentStrong)
        segmented.backgroundColor = UIColor(AppColors.backgroundSecondary)
        segmented.setTitleTextAttributes([.foregroundColor: UIColor(AppColors.textSecondary)], for: .normal)
        segmented.setTitleTextAttributes([.foregroundColor: UIColor(AppColors.textPrimary)], for: .selected)

        let searchBar = UISearchBar.appearance()
        searchBar.barStyle = .black
        searchBar.tintColor = UIColor(AppColors.accent)

        let searchField = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        searchField.backgroundColor = UIColor(AppColors.backgroundTertiary)
        searchField.textColor = UIColor(AppColors.textPrimary)
        searchField.attributedPlaceholder = NSAttributedString(
            string: "Search entries",
            attributes: [.foregroundColor: UIColor(AppColors.textTertiary)]
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [JournalEntry.self, FoodPhoto.self], inMemory: true)
}
