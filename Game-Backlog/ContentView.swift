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
    @State private var searchText = ""
    // @AppStorage remembers the choice even after the app is closed.
    @AppStorage("sortOrder") private var sortOrder: SortOrder = .newest

    // The games to show, like:
    //   SELECT * FROM games
    //   WHERE status = <tab> AND title LIKE '%<search>%'
    //   ORDER BY <sort choice>
    private var filtered: [Game] {
        games
            .filter { $0.status == filter }
            .filter { searchText.isEmpty || $0.title.localizedStandardContains(searchText) }
            .sorted(by: sortOrder.areInOrder)
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
                            .listRowSeparator(.hidden)
                    }
                    ForEach(filtered) { game in
                        GameRow(game: game)
                            .contentShape(Rectangle())
                            .onTapGesture { editingGame = game }
                            // Frosted-glass card: the glows blur through it
                            .listRowBackground(Rectangle().fill(.ultraThinMaterial))
                            .listRowSeparator(.hidden)
                            // Swipe right: move the game to another tab
                            .swipeActions(edge: .leading) {
                                ForEach(GameStatus.allCases.filter { $0 != game.status }) { status in
                                    Button {
                                        withAnimation { game.status = status }
                                    } label: {
                                        Label(status.shortLabel, systemImage: status.icon)
                                    }
                                    .tint(status.chartColor)
                                }
                            }
                            // Swipe left: delete
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation { context.delete(game) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .scrollContentBackground(.hidden)   // hide the default gray so the neon shows
                .listRowSpacing(10)                 // gaps so each row is its own card
                .overlay {
                    if filtered.isEmpty {
                        if searchText.isEmpty {
                            ContentUnavailableView("Nothing here yet",
                                                   systemImage: filter.icon,
                                                   description: Text("Tap + to add a game."))
                        } else {
                            ContentUnavailableView.search(text: searchText)   // "No results for ..."
                        }
                    }
                }
            }
            .background(NeonBackground())
            .navigationTitle("Game Backlog 🎮")
            .searchable(text: $searchText, prompt: "Search this tab")
            .toolbar {
                // Sort menu (the ORDER BY part)
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort by", selection: $sortOrder) {
                            ForEach(SortOrder.allCases) { order in
                                Label(order.label, systemImage: order.icon).tag(order)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
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

// The ways the list can be sorted: each one is an ORDER BY.
enum SortOrder: String, CaseIterable, Identifiable {
    case newest, title, rating, releaseYear
    var id: String { rawValue }

    var label: String {
        switch self {
        case .newest: "Recently Added"
        case .title: "Title (A–Z)"
        case .rating: "Highest Rated"
        case .releaseYear: "Release Year"
        }
    }

    var icon: String {
        switch self {
        case .newest: "clock"
        case .title: "textformat"
        case .rating: "star"
        case .releaseYear: "calendar"
        }
    }

    // Should game a come before game b?
    func areInOrder(_ a: Game, _ b: Game) -> Bool {
        switch self {
        case .newest:        // ORDER BY date_added DESC
            return a.dateAdded > b.dateAdded
        case .title:         // ORDER BY title ASC
            return a.title.localizedStandardCompare(b.title) == .orderedAscending
        case .rating:        // ORDER BY rating DESC, title ASC  (ties broken by title)
            if a.rating != b.rating { return a.rating > b.rating }
            return a.title.localizedStandardCompare(b.title) == .orderedAscending
        case .releaseYear:   // ORDER BY release_year DESC  (unknown years go last)
            return (a.releaseYear ?? 0) > (b.releaseYear ?? 0)
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
