import SwiftUI
import SwiftData

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Create the on-device database for Game and share it with every screen.
        .modelContainer(for: Game.self)
    }
}
