import SwiftUI
import SwiftData
import Charts

// STEP 3: A stats dashboard: a mini Power BI report inside the app.
// Each chart is an aggregation over the games table, shown next to its SQL equivalent.

struct StatsView: View {
    @Query private var games: [Game]
    @Environment(\.dismiss) private var dismiss

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
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Aggregations (the "queries")

    // SELECT status, COUNT(*) FROM games GROUP BY status
    private var byStatus: [CountRow] {
        GameStatus.allCases.map { status in
            CountRow(label: status.shortLabel, count: games.filter { $0.status == status }.count, color: status.chartColor)
        }
    }

    // SELECT platform, COUNT(*) FROM games GROUP BY platform ORDER BY COUNT(*) DESC
    private var byPlatform: [CountRow] {
        Platform.allCases
            .map { p in CountRow(label: p.label, count: games.filter { $0.platform == p }.count) }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
    }

    // Genres are stored as "Action, Indie", so split them first (like UNNEST / STRING_SPLIT),
    // then: SELECT genre, COUNT(*) ... GROUP BY genre ORDER BY COUNT(*) DESC LIMIT 6
    private var topGenres: [CountRow] {
        let allGenres = games.flatMap { game in
            game.genres.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }.filter { !$0.isEmpty }
        let counts = Dictionary(grouping: allGenres, by: { $0 }).mapValues(\.count)
        return counts
            .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .prefix(6)
            .map { CountRow(label: $0.key, count: $0.value) }
    }

    // SELECT rating, COUNT(*) FROM games WHERE rating > 0 GROUP BY rating
    private var ratingCounts: [CountRow] {
        (1...5).map { stars in
            CountRow(label: String(repeating: "★", count: stars), count: games.filter { $0.rating == stars }.count)
        }
    }

    // SELECT (release_year / 10) * 10 AS decade, COUNT(*) ... GROUP BY decade ORDER BY decade
    private var byDecade: [CountRow] {
        let decades = games.compactMap(\.releaseYear).map { $0 / 10 * 10 }
        return Dictionary(grouping: decades, by: { $0 }).mapValues(\.count)
            .sorted { $0.key < $1.key }
            .map { CountRow(label: "\($0.key)s", count: $0.value) }
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
            Chart(byStatus) { row in
                BarMark(x: .value("Status", row.label), y: .value("Games", row.count), width: .ratio(0.55))
                    .foregroundStyle(row.color ?? ChartPalette.series1)
                    .cornerRadius(4)
                    .annotation(position: .top) { valueLabel(row.count) }
            }
            .chartYAxis(.hidden)
            .frame(height: 170)
        }
    }

    private var platformChart: some View {
        ChartCard(title: "Games by platform") {
            horizontalBars(byPlatform)
        }
    }

    private var genreChart: some View {
        ChartCard(title: "Top genres", subtitle: "From RAWG data on games you added by search") {
            horizontalBars(topGenres)
        }
    }

    private var ratingChart: some View {
        ChartCard(title: "Your ratings") {
            Chart(ratingCounts) { row in
                BarMark(x: .value("Rating", row.label), y: .value("Games", row.count), width: .ratio(0.55))
                    .foregroundStyle(ChartPalette.series1)
                    .cornerRadius(4)
                    .annotation(position: .top) { valueLabel(row.count) }
            }
            .chartYAxis(.hidden)
            .frame(height: 150)
        }
    }

    private var decadeChart: some View {
        ChartCard(title: "Release decade") {
            Chart(byDecade) { row in
                BarMark(x: .value("Decade", row.label), y: .value("Games", row.count), width: .ratio(0.55))
                    .foregroundStyle(ChartPalette.series1)
                    .cornerRadius(4)
                    .annotation(position: .top) { valueLabel(row.count) }
            }
            .chartYAxis(.hidden)
            .frame(height: 150)
        }
    }

    // Horizontal bars for category lists (easier to read long names like "Nintendo Switch").
    private func horizontalBars(_ rows: [CountRow]) -> some View {
        Chart(rows) { row in
            BarMark(x: .value("Games", row.count), y: .value("Name", row.label), height: .ratio(0.6))
                .foregroundStyle(ChartPalette.series1)
                .cornerRadius(4)
                .annotation(position: .trailing) { valueLabel(row.count) }
        }
        .chartXAxis(.hidden)
        .frame(height: CGFloat(rows.count) * 34 + 8)
    }

    private func valueLabel(_ count: Int) -> some View {
        Text("\(count)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)     // values use text color, not the bar color
    }
}

// One row of an aggregated result: a label and a count.
struct CountRow: Identifiable {
    let label: String
    let count: Int
    var color: Color? = nil
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
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
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
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
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
