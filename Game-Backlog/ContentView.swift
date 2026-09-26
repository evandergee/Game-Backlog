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
    @State private var showingStats = false

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
                // STEP 3: open the stats dashboard
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingStats = true
                    } label: {
                        Label("Stats", systemImage: "chart.bar.xaxis")
                    }
                }
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
            .sheet(isPresented: $showingStats) {
                StatsView()
            }
        }
    }
}

struct GameRow: View {
    let game: Game

    var body: some View {
        HStack(spacing: 14) {
            CoverArt(url: game.coverURL, title: game.title, width: 48, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.headline)
                // e.g. "PC · 2017 · Action, Indie"
                Text([game.platform.label, game.releaseYear.map(String.init) ?? "", game.genres]
                        .filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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

// Cover image loaded from the web, with the letter tile as a fallback
// while it loads or if there's no image.
struct CoverArt: View {
    let url: String?
    let title: String
    var width: CGFloat = 48
    var height: CGFloat = 64

    var body: some View {
        AsyncImage(url: url.flatMap(URL.init(string:))) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                ZStack {
                    Rectangle().fill(.indigo.gradient)
                    Text(String(title.prefix(1)).uppercased())
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Game.self, inMemory: true)
}
