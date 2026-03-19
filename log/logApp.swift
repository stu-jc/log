import SwiftUI
import SwiftData

@main
struct logApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [JournalEntry.self, FoodPhoto.self])
    }
}
