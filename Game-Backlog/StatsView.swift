import SwiftUI
import SwiftData
import Charts

// STEP 3: A stats dashboard: a mini Power BI report inside the app.
// Each chart is an aggregation over the games table, shown next to its SQL equivalent.

struct StatsView: View {
    @Query private var games: [Game]
    @Environment(\.dismiss) private var dismiss
    @State private var pick: ChartPick?          // the bar you tapped (nil = none)
    @State private var editingGame: Game?        // the game you tapped in a drill-down list

    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    ContentUnavailableView("No stats yet",
                                           systemImage: "chart.bar.xaxis",
                                           description: Text("Add a few games to see your stats."))
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            kpiTiles
                            Label("Tap any bar to see its games", systemImage: "hand.tap")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            statusChart
                            if !byPlatform.isEmpty { platformChart }
                            if !topGenres.isEmpty { genreChart }
                            if ratingCounts.contains(where: { $0.count > 0 }) { ratingChart }
                            if !byDecade.isEmpty { decadeChart }
                        }
                        .padding()
                    }
                }
            }
            .background(NeonBackground())
            .navigationTitle("Stats")
            .toolbar {
                // STEP 5: export every game as a CSV file through the share sheet
                if !games.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(item: GamesCSV(games: games),
                                  preview: SharePreview("Game Backlog (\(games.count) games)")) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                                .labelStyle(.titleAndIcon)   // show the words, not just the icon
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $editingGame) { game in
                GameFormView(game: game)
            }
        }
    }

    // MARK: - Aggregations (the "queries")
    // Each bar keeps the list of games behind its number, so tapping it can show them
    // (like drill-through in Power BI).

    // SELECT status, COUNT(*) FROM games GROUP BY status
    private var byStatus: [CountRow] {
        GameStatus.allCases.map { status in
            CountRow(label: status.shortLabel, games: games.filter { $0.status == status }, color: status.chartColor)
        }
    }

    // SELECT platform, COUNT(*) FROM games GROUP BY platform ORDER BY COUNT(*) DESC
    private var byPlatform: [CountRow] {
        Platform.allCases
            .map { p in CountRow(label: p.label, games: games.filter { $0.platform == p }) }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
    }

    // Genres are stored as "Action, Indie", so split them first (like UNNEST / STRING_SPLIT),
    // then: SELECT genre, COUNT(*) ... GROUP BY genre ORDER BY COUNT(*) DESC LIMIT 6
    private func genreList(_ game: Game) -> [String] {
        game.genres.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var topGenres: [CountRow] {
        let allGenres = Set(games.flatMap(genreList))
        return allGenres
            .map { genre in CountRow(label: genre, games: games.filter { genreList($0).contains(genre) }) }
            .sorted { $0.count == $1.count ? $0.label < $1.label : $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }

    // SELECT rating, COUNT(*) FROM games WHERE rating > 0 GROUP BY rating
    private var ratingCounts: [CountRow] {
        (1...5).map { stars in
            CountRow(label: String(repeating: "★", count: stars), games: games.filter { $0.rating == stars })
        }
    }

    // SELECT (release_year / 10) * 10 AS decade, COUNT(*) ... GROUP BY decade ORDER BY decade
    private var byDecade: [CountRow] {
        Set(games.compactMap(\.releaseYear).map { $0 / 10 * 10 })
            .sorted()
            .map { decade in
                CountRow(label: "\(decade)s", games: games.filter { $0.releaseYear.map { $0 / 10 * 10 } == decade })
            }
    }

    private var averageRating: String {
        let rated = games.filter { $0.rating > 0 }
        guard !rated.isEmpty else { return "—" }
        let avg = Double(rated.map(\.rating).reduce(0, +)) / Double(rated.count)
        return String(format: "%.1f ★", avg)
    }

    // MARK: - KPI tiles

    private var kpiTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(title: "Total games", value: "\(games.count)", icon: "square.stack.fill")
            StatTile(title: "Finished", value: "\(games.filter { $0.status == .finished }.count)", icon: "checkmark.seal.fill")
            StatTile(title: "Playing now", value: "\(games.filter { $0.status == .playing }.count)", icon: "gamecontroller.fill")
            StatTile(title: "Average rating", value: averageRating, icon: "star.fill")
        }
    }

    // MARK: - Charts

    private var statusChart: some View {
        ChartCard(title: "Games by status") {
            verticalBars("status", byStatus, height: 170)
        }
    }

    private var platformChart: some View {
        ChartCard(title: "Games by platform") {
            horizontalBars("platform", byPlatform)
        }
    }

    private var genreChart: some View {
        ChartCard(title: "Top genres", subtitle: "From RAWG data on games you added by search") {
            horizontalBars("genre", topGenres)
        }
    }

    private var ratingChart: some View {
        ChartCard(title: "Your ratings") {
            verticalBars("rating", ratingCounts, height: 150)
        }
    }

    private var decadeChart: some View {
        ChartCard(title: "Release decade") {
            verticalBars("decade", byDecade, height: 150)
        }
    }

    // Vertical bars for short labels (status, stars, decades).
    private func verticalBars(_ chart: String, _ rows: [CountRow], height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart(rows) { row in
                BarMark(x: .value("Category", row.label), y: .value("Games", row.count), width: .ratio(0.55))
                    .foregroundStyle(row.color ?? ChartPalette.series1)
                    .cornerRadius(4)
                    .opacity(isDimmed(chart, row) ? 0.3 : 1)     // fade the bars you didn't tap
                    .annotation(position: .top) { valueLabel(row.count) }
            }
            .chartYAxis(.hidden)
            .frame(height: height)
            // An invisible layer over the chart that turns a tap into "which bar was that?"
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let plot = proxy.plotFrame else { return }
                            let x = location.x - geo[plot].origin.x
                            if let label: String = proxy.value(atX: x) { toggle(chart, label) }
                        }
                }
            }

            drillDown(chart, rows)
        }
    }

    // Horizontal bars for category lists (easier to read long names like "Nintendo Switch").
    private func horizontalBars(_ chart: String, _ rows: [CountRow]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart(rows) { row in
                BarMark(x: .value("Games", row.count), y: .value("Name", row.label), height: .ratio(0.6))
                    .foregroundStyle(ChartPalette.series1)
                    .cornerRadius(4)
                    .opacity(isDimmed(chart, row) ? 0.3 : 1)
                    .annotation(position: .trailing) { valueLabel(row.count) }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(rows.count) * 34 + 8)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let plot = proxy.plotFrame else { return }
                            let y = location.y - geo[plot].origin.y
                            if let label: String = proxy.value(atY: y) { toggle(chart, label) }
                        }
                }
            }

            drillDown(chart, rows)
        }
    }

    private func valueLabel(_ count: Int) -> some View {
        Text("\(count)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)     // values use text color, not the bar color
    }

    // MARK: - Tap a bar to see its games (drill-through)

    // Tap a bar to select it; tap the same bar again to clear.
    private func toggle(_ chart: String, _ label: String) {
        let tapped = ChartPick(chart: chart, label: label)
        withAnimation(.snappy) {
            pick = (pick == tapped) ? nil : tapped
        }
    }

    // A bar is dimmed when a DIFFERENT bar in the same chart is selected.
    private func isDimmed(_ chart: String, _ row: CountRow) -> Bool {
        guard let pick, pick.chart == chart else { return false }
        return pick.label != row.label
    }

    // The list of games under a chart, shown when one of its bars is selected.
    @ViewBuilder
    private func drillDown(_ chart: String, _ rows: [CountRow]) -> some View {
        if let pick, pick.chart == chart, let row = rows.first(where: { $0.label == pick.label }) {
            VStack(alignment: .leading, spacing: 10) {
                Divider()
                HStack {
                    Text("\(row.label) · \(row.count) game\(row.count == 1 ? "" : "s")")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Button("Clear") { withAnimation(.snappy) { self.pick = nil } }
                        .font(.caption)
                }
                if row.games.isEmpty {
                    Text("No games here yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                // SELECT * FROM games WHERE <this bar's category> ORDER BY title
                ForEach(row.games.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }) { game in
                    Button { editingGame = game } label: {
                        HStack(spacing: 10) {
                            CoverArt(url: game.coverURL, title: game.title, width: 30, height: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(game.title).font(.subheadline)
                                Text("\(game.status.label) · \(game.platform.label)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .transition(.opacity)
        }
    }
}

// Which bar is selected: the chart it's in and the bar's label.
struct ChartPick: Equatable {
    let chart: String
    let label: String
}

// One row of an aggregated result: a label and the games behind it.
struct CountRow: Identifiable {
    let label: String
    let games: [Game]
    var color: Color? = nil
    var count: Int { games.count }      // COUNT(*)
    var id: String { label }
}

// A single headline number, like a KPI card in Power BI.
struct StatTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))   // frosted glass
    }
}

// A titled card that holds one chart.
struct ChartCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))   // frosted glass
    }
}

// MARK: - Chart colors
// A tested, colorblind-friendly palette, with separate light and dark mode shades.

enum ChartPalette {
    static let series1 = Color(light: 0x2a78d6, dark: 0x3987e5)   // blue
    static let series2 = Color(light: 0xeb6834, dark: 0xd95926)   // orange
    static let series3 = Color(light: 0x1baf7a, dark: 0x199e70)   // aqua
    static let series4 = Color(light: 0xeda100, dark: 0xc98500)   // yellow
}

extension GameStatus {
    // Each status always gets the same color, in a fixed order.
    var chartColor: Color {
        switch self {
        case .wantToPlay: ChartPalette.series1
        case .playing: ChartPalette.series2
        case .finished: ChartPalette.series3
        case .dropped: ChartPalette.series4
        }
    }
}

extension Color {
    // A color that automatically switches between a light-mode and dark-mode hex value.
    init(light: UInt32, dark: UInt32) {
        self = Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: Game.self, inMemory: true)
}
