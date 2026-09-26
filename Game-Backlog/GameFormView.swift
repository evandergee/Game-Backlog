import SwiftUI

// Form for adding a new game or editing an existing one (same pattern as PlantCare).

struct GameFormView: View {
    var game: Game?                       // nil = adding, otherwise editing
    var onSave: (Game) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var status: GameStatus
    @State private var platform: Platform
    @State private var rating: Int
    @State private var notes: String
    @State private var coverURL: String?
    @State private var releaseYear: Int?
    @State private var genres: String
    @State private var rawgID: Int?

    // Platforms of the game picked from search (empty = show every platform)
    @State private var availablePlatforms: [Platform] = []
    @State private var showAllPlatforms = false
    private var showingGamePlatformsOnly: Bool {
        !availablePlatforms.isEmpty && !showAllPlatforms
    }

    // Search state
    @State private var searchText = ""
    @State private var results: [RAWGGame] = []
    @State private var isSearching = false
    @State private var searchError: String?

    init(game: Game? = nil, onSave: @escaping (Game) -> Void = { _ in }) {
        self.game = game
        self.onSave = onSave
        _title = State(initialValue: game?.title ?? "")
        _status = State(initialValue: game?.status ?? .wantToPlay)
        _platform = State(initialValue: game?.platform ?? .pc)
        _rating = State(initialValue: game?.rating ?? 0)
        _notes = State(initialValue: game?.notes ?? "")
        _coverURL = State(initialValue: game?.coverURL)
        _releaseYear = State(initialValue: game?.releaseYear)
        _genres = State(initialValue: game?.genres ?? "")
        _rawgID = State(initialValue: game?.rawgID)
    }

    var body: some View {
        NavigationStack {
            Form {
                // STEP 2: search RAWG and tap a result to fill in the form.
                Section {
                    TextField("Search RAWG, e.g. Hollow Knight", text: $searchText)
                        .autocorrectionDisabled()

                    if !RAWG.hasKey {
                        Text("Add your RAWG API key in Secrets.swift to turn on search.")
                            .font(.caption).foregroundStyle(.orange)
                    } else if isSearching {
                        ProgressView()
                    } else if let searchError {
                        Text(searchError).font(.caption).foregroundStyle(.red)
                    }

                    ForEach(results) { result in
                        Button { choose(result) } label: {
                            HStack(spacing: 12) {
                                CoverArt(url: result.backgroundImage, title: result.name, width: 40, height: 54)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.name).foregroundStyle(.primary)
                                    Text([result.releaseYear.map(String.init) ?? "", result.genreText]
                                            .filter { !$0.isEmpty }.joined(separator: " · "))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Find the game")
                } footer: {
                    Link("Game data and images from RAWG", destination: URL(string: "https://rawg.io")!)
                        .font(.caption2)
                }

                // Preview of what was picked from RAWG
                if coverURL != nil || releaseYear != nil || !genres.isEmpty {
                    Section {
                        HStack(spacing: 14) {
                            CoverArt(url: coverURL, title: title, width: 60, height: 80)
                            VStack(alignment: .leading, spacing: 4) {
                                if let releaseYear { Text("Released \(String(releaseYear))") }
                                if !genres.isEmpty { Text(genres).foregroundStyle(.secondary) }
                            }
                            .font(.subheadline)
                        }
                    }
                }

                Section("Game") {
                    TextField("Title", text: $title)
                    // After picking a search result: only that game's platforms.
                    // Otherwise: every platform, grouped by family (PlayStation, Xbox, ...).
                    Picker("Platform", selection: $platform) {
                        if showingGamePlatformsOnly {
                            ForEach(availablePlatforms) { Text($0.label).tag($0) }
                        } else {
                            ForEach(PlatformFamily.allCases) { family in
                                Section(family.rawValue) {
                                    ForEach(Platform.inFamily(family)) { Text($0.label).tag($0) }
                                }
                            }
                        }
                    }
                    .pickerStyle(.navigationLink)
                    if showingGamePlatformsOnly {
                        Button("Played it somewhere else? Show all platforms") {
                            showAllPlatforms = true
                        }
                        .font(.caption)
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(GameStatus.allCases) { Label($0.label, systemImage: $0.icon).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Your rating") {
                    StarRating(rating: $rating)
                }

                Section("Notes") {
                    TextField("Thoughts, where you left off…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)   // let the neon background show through
            .background(NeonBackground())
            .navigationTitle(game == nil ? "Add Game" : "Edit Game")
            // Runs a search whenever searchText changes. Waiting 0.4s first means we
            // only call the API once you pause typing, not on every keystroke.
            .task(id: searchText) {
                let query = searchText.trimmingCharacters(in: .whitespaces)
                guard query.count >= 2, RAWG.hasKey else { results = []; searchError = nil; return }
                try? await Task.sleep(for: .milliseconds(400))
                if Task.isCancelled { return }
                isSearching = true
                defer { isSearching = false }
                do {
                    results = try await RAWG.search(query)
                    searchError = results.isEmpty ? "No matches found." : nil
                } catch {
                    if !Task.isCancelled {
                        searchError = "Couldn't reach RAWG. Check your connection and API key."
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        if let game {
            // UPDATE games SET ... WHERE id = this game
            game.title = cleanTitle
            game.status = status
            game.platform = platform
            game.rating = rating
            game.notes = notes
            game.coverURL = coverURL
            game.releaseYear = releaseYear
            game.genres = genres
            game.rawgID = rawgID
        } else {
            // INSERT INTO games ...
            onSave(Game(title: cleanTitle, status: status, platform: platform, rating: rating, notes: notes,
                        coverURL: coverURL, releaseYear: releaseYear, genres: genres, rawgID: rawgID))
        }
    }

    // Copy a search result's details into the form.
    private func choose(_ result: RAWGGame) {
        title = result.name
        coverURL = result.backgroundImage
        releaseYear = result.releaseYear
        genres = result.genreText
        rawgID = result.id
        // If RAWG lists a platform we don't have, fall back to "Other" rather than
        // leaving whatever was picked before (which could be wrong).
        platform = result.suggestedPlatform ?? .other
        availablePlatforms = result.matchedPlatforms
        showAllPlatforms = false
        searchText = ""
        results = []
        searchError = nil
    }
}

// Tap a star to set the rating; tap the same star again to clear it.
struct StarRating: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundStyle(star <= rating ? .yellow : .secondary)
                    .onTapGesture { rating = (rating == star) ? 0 : star }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GameFormView()
}
