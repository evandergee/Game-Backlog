import SwiftUI
import SwiftData

// STEP 1: Your game backlog.
// Tabs across the top filter by status, like WHERE status = 'playing' in SQL.

struct ContentView: View {
    @Query(sort: \Game.dateAdded, order: .reverse) private var games: [Game]
    @Environment(\.modelContext) private var context

    @State private var filter: GameStatus = .playing
    @State private var showingAdd = false
    @State private var editingGame: Game?

    // The games matching the selected tab.
    private var filtered: [Game] {
        games.filter { $0.status == filter }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Status", selection: $filter) {
                    ForEach(GameStatus.allCases) { status in
                        Text(status.shortLabel).tag(status)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    // Count for this tab, like SELECT COUNT(*) FROM games WHERE status = ...
                    if !filtered.isEmpty {
                        Text("\(filtered.count) game\(filtered.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                    }
                    ForEach(filtered) { game in
                        GameRow(game: game)
                            .contentShape(Rectangle())
                            .onTapGesture { editingGame = game }
                    }
                    .onDelete { rows in
                        for row in rows { context.delete(filtered[row]) }
                    }
                }
                .overlay {
                    if filtered.isEmpty {
                        ContentUnavailableView("Nothing here yet",
                                               systemImage: filter.icon,
                                               description: Text("Tap + to add a game."))
                    }
                }
            }
            .navigationTitle("Game Backlog 🎮")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add Game", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                GameFormView { newGame in
                    context.insert(newGame)
                    filter = newGame.status      // jump to the tab the new game landed in
                }
            }
            .sheet(item: $editingGame) { game in
                GameFormView(game: game)
            }
        }
    }
}

struct GameRow: View {
    let game: Game

    var body: some View {
        HStack(spacing: 14) {
            // Placeholder "cover art" — Step 2 replaces this with real covers from the API.
            RoundedRectangle(cornerRadius: 8)
                .fill(.indigo.gradient)
                .frame(width: 48, height: 64)
                .overlay(
                    Text(String(game.title.prefix(1)).uppercased())
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.headline)
                Text(game.platform.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if game.rating > 0 {
                    Text(String(repeating: "★", count: game.rating))
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Game.self, inMemory: true)
}
