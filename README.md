# Game Backlog 🎮

An iPhone app for tracking your video game backlog, built with SwiftUI and SwiftData. Search the [RAWG](https://rawg.io) game database to add games with cover art, release year and genres, then track what you're playing and how you'd rate it.

## Features

- **Search as you type.** Find any game in RAWG's database of 500,000+ titles. Tapping a result fills in the title, cover art, release year, genres and a best-guess platform.
- **Status tabs.** Backlog, Playing, Done and Dropped. Move a game between tabs by editing it.
- **Ratings and notes.** Rate games from 1 to 5 stars and add notes.
- **Saved on the device** with SwiftData, so your list persists between launches.
- **Cover art** loads from the web, with a letter tile as a fallback.
- Tap to edit a game, and swipe left to delete one.

## Project structure

| File | What it does |
|---|---|
| `MyApp.swift` | App entry point; sets up the SwiftData database |
| `Game.swift` | Data model (the "games table") and status/platform choices |
| `ContentView.swift` | Main list with status tabs and cover art |
| `GameFormView.swift` | Form for adding and editing games, including RAWG search |
| `RAWG.swift` | API client: builds the request, downloads JSON, decodes results |
| `Secrets.swift` | Your API key (git-ignored; see setup below) |

## What I learned

- **Calling a REST API.** Build a URL with query parameters, send the request, check the response code, and decode the JSON into typed structs. It's the same request → JSON → rows pattern used to pull API data into a data pipeline.
- **Mapping JSON to a schema.** Only the fields the app needs are decoded, and `snake_case` keys like `background_image` are converted to Swift names automatically.
- **Keeping secrets out of source control.** The API key lives in a git-ignored file, so it never reaches GitHub.
- **Not overloading an API.** Search waits until you pause typing before calling RAWG, instead of sending a request on every keystroke.
- **Evolving a schema.** New columns (cover, year, genres) were added to an existing SwiftData model without losing saved data.

## Setup

1. Get a free API key at [rawg.io/apidocs](https://rawg.io/apidocs).
2. Create `Game-Backlog/Secrets.swift` with:
   ```swift
   enum Secrets {
       static let rawgAPIKey = "YOUR_KEY_HERE"
   }
   ```
3. Open `Game-Backlog.xcodeproj` in Xcode, choose an iPhone simulator, and press Run.

## Credits

Game data and images are provided by [RAWG](https://rawg.io).
