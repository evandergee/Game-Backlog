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

    init(game: Game? = nil, onSave: @escaping (Game) -> Void = { _ in }) {
        self.game = game
        self.onSave = onSave
        _title = State(initialValue: game?.title ?? "")
        _status = State(initialValue: game?.status ?? .wantToPlay)
        _platform = State(initialValue: game?.platform ?? .pc)
        _rating = State(initialValue: game?.rating ?? 0)
        _notes = State(initialValue: game?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    TextField("Title", text: $title)
                    Picker("Platform", selection: $platform) {
                        ForEach(Platform.allCases) { Text($0.label).tag($0) }
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
            .navigationTitle(game == nil ? "Add Game" : "Edit Game")
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
        } else {
            // INSERT INTO games ...
            onSave(Game(title: cleanTitle, status: status, platform: platform, rating: rating, notes: notes))
        }
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
