import SwiftUI
import UniformTypeIdentifiers

// STEP 5: Export the games table as a CSV file.
//
// A CSV is the simplest "table as text" format: one line per row, commas between
// columns, and a header line with the column names. Excel, Power BI, Python (pandas)
// and SQL tools can all load it directly.

// The finished file, ready to hand to the iOS share sheet (AirDrop, Save to Files, Mail...).
// It only holds plain text, so it's safe to pass around ("nonisolated").
nonisolated struct GamesCSV: Transferable {
    let fileName: String
    let text: String

    // Tells iOS: "this item can be shared as a .csv file".
    // The file is only written when the user actually picks where to send it.
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { csv in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(csv.fileName)
            try csv.text.write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}

extension GamesCSV {
    // Build the CSV from the games table, like:
    //   SELECT title, status, platform, ... FROM games ORDER BY date_added
    init(games: [Game]) {
        let header = ["title", "status", "platform", "platform_family", "rating",
                      "release_year", "genres", "date_added", "notes", "rawg_id"]

        let rows = games
            .sorted { $0.dateAdded < $1.dateAdded }
            .map { game in
                [
                    game.title,
                    game.status.label,
                    game.platform.label,
                    game.platform.family.rawValue,
                    game.rating > 0 ? String(game.rating) : "",      // blank = not rated (NULL)
                    game.releaseYear.map(String.init) ?? "",
                    game.genres,
                    game.dateAdded.formatted(.iso8601.year().month().day()),   // e.g. 2026-09-26
                    game.notes,
                    game.rawgID.map(String.init) ?? "",
                ]
            }

        let lines = ([header] + rows).map { row in
            row.map(Self.escape).joined(separator: ",")
        }

        let today = Date.now.formatted(.iso8601.year().month().day())
        self.init(fileName: "GameBacklog-\(today).csv", text: lines.joined(separator: "\n"))
    }

    // A value containing a comma, quote or line break must be wrapped in quotes,
    // with any quotes inside doubled. Otherwise "Action, Indie" would split into two columns.
    static func escape(_ value: String) -> String {
        guard value.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
