import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label("Today", systemImage: "sun.max.fill") }

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock.fill") }

            NavigationStack {
                SearchView()
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
        .preferredColorScheme(.dark)
        .tint(AppColors.accent)
        .onAppear { AppTabBarAppearance.configure() }
    }
}

private enum AppTabBarAppearance {
    static func configure() {
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

#Preview {
    ContentView()
        .modelContainer(for: [JournalEntry.self, FoodPhoto.self], inMemory: true)
}
