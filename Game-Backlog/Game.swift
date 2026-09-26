import Foundation
import SwiftData

// STEP 1: The data model — the "games" table.
// Like PlantCare, choices are saved as short stable keys with separate display labels.

enum GameStatus: String, CaseIterable, Identifiable, Codable {
    case wantToPlay, playing, finished, dropped
    var id: String { rawValue }
    var label: String {
        switch self {
        case .wantToPlay: "Want to Play"
        case .playing: "Playing"
        case .finished: "Finished"
        case .dropped: "Dropped"
        }
    }
    // Shorter name for the tabs, so all four fit across an iPhone screen.
    var shortLabel: String {
        switch self {
        case .wantToPlay: "Backlog"
        case .playing: "Playing"
        case .finished: "Done"
        case .dropped: "Dropped"
        }
    }
    var icon: String {
        switch self {
        case .wantToPlay: "bookmark.fill"
        case .playing: "gamecontroller.fill"
        case .finished: "checkmark.seal.fill"
        case .dropped: "xmark.circle.fill"
        }
    }
}

enum Platform: String, CaseIterable, Identifiable, Codable {
    case pc, playstation, xbox, nintendoSwitch, mobile, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .pc: "PC"
        case .playstation: "PlayStation"
        case .xbox: "Xbox"
        case .nintendoSwitch: "Nintendo Switch"
        case .mobile: "Mobile"
        case .other: "Other"
        }
    }
}

@Model
final class Game {
    var title: String
    var status: GameStatus
    var platform: Platform
    var rating: Int          // 0 = not rated, 1–5 stars
    var notes: String
    var dateAdded: Date

    // STEP 2: extra columns filled in from RAWG (optional, since games can still be added by hand).
    // New columns with defaults are added to the existing database automatically.
    var coverURL: String? = nil
    var releaseYear: Int? = nil
    var genres: String = ""
    var rawgID: Int? = nil

    init(title: String, status: GameStatus, platform: Platform, rating: Int = 0, notes: String = "",
         coverURL: String? = nil, releaseYear: Int? = nil, genres: String = "", rawgID: Int? = nil) {
        self.title = title
        self.status = status
        self.platform = platform
        self.rating = rating
        self.notes = notes
        self.dateAdded = Date()
        self.coverURL = coverURL
        self.releaseYear = releaseYear
        self.genres = genres
        self.rawgID = rawgID
    }
}
