import SwiftUI
import SwiftData

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)   // white text on the dark neon background
                .tint(.purple)                 // buttons and icons pick up the neon color
                .fontDesign(.rounded)          // softer, friendlier font everywhere
        }
        // Create the on-device database for Game and share it with every screen.
        .modelContainer(for: Game.self)
    }
}
