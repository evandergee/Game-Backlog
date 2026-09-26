# Game Backlog 🎮

An iPhone app for tracking your video game backlog, built with SwiftUI and SwiftData. Search the [RAWG](https://rawg.io) game database to add games with cover art, release year and genres, then track what you're playing and how you'd rate it.

## Features

- **Search as you type.** Find any game in RAWG's database of 500,000+ titles. Tapping a result fills in the title, cover art, release year and genres, and narrows the platform list to the platforms that game was released on.
- **Every platform.** 68 platforms grouped by family (PlayStation, Xbox, Nintendo, Sega, Atari, retro computers and more), covering all 51 platforms in RAWG's database.
- **Status tabs.** Backlog, Playing, Done and Dropped. Swipe a game right to move it to another tab, or swipe left to delete it.
- **Search and sort.** Search the current tab by title, and sort by recently added, title, rating or release year. The app remembers your sort choice.
- **Ratings and notes.** Rate games from 1 to 5 stars and add notes.
- **Saved on the device** with SwiftData, so your list persists between launches.
- **Cover art** loads from the web, with a letter tile as a fallback.
- **Stats dashboard.** KPI tiles plus charts of games by status, platform, top genres, ratings and release decade, built with Swift Charts. Tap any bar to see the games behind it, then tap a game to edit it.
- **Neon theme.** A dark gradient background with soft glows and frosted-glass cards on every screen.

## Project structure

| File | What it does |
|---|---|
| `MyApp.swift` | App entry point; sets up the SwiftData database |
| `Game.swift` | Data model (the "games table") and status choices |
| `Platform.swift` | Every platform, grouped by family, with RAWG's name for each |
| `ContentView.swift` | Main list with status tabs, search, sorting and swipe actions |
| `GameFormView.swift` | Form for adding and editing games, including RAWG search |
| `StatsView.swift` | Stats dashboard: aggregations, charts and tap-to-drill-through |
| `NeonBackground.swift` | The shared neon gradient background |
| `RAWG.swift` | API client: builds the request, downloads JSON, decodes results |
| `Secrets.swift` | Your API key (git-ignored; see setup below) |

## What I learned

- **Calling a REST API.** Build a URL with query parameters, send the request, check the response code, and decode the JSON into typed structs. It's the same request → JSON → rows pattern used to pull API data into a data pipeline.
- **Mapping JSON to a schema.** Only the fields the app needs are decoded, and `snake_case` keys like `background_image` are converted to Swift names automatically.
- **Keeping secrets out of source control.** The API key lives in a git-ignored file, so it never reaches GitHub.
- **Not overloading an API.** Search waits until you pause typing before calling RAWG, instead of sending a request on every keystroke.
- **Aggregating data for a dashboard.** Each chart is a GROUP BY and COUNT over the games table. Genres are stored as a comma-separated string, so they're split into one row per genre first, like `STRING_SPLIT` or `UNNEST` in SQL.
- **Evolving a schema.** New columns (cover, year, genres) were added to an existing SwiftData model without losing saved data.
- **Keeping stored values stable.** When the platform list grew from 6 choices to 68, the original saved codes (like `"playstation"`) were kept and pointed at the closest new choice, so games already saved still load. Display labels can change freely; stored keys can't.
- **Filtering and sorting like SQL.** The main list is a `WHERE status = … AND title LIKE …` plus an `ORDER BY` the user picks, with the choice remembered using `@AppStorage`.
- **Drill-through on charts.** Each bar keeps the rows behind its count, like a `SELECT *` behind a `COUNT(*)`, so tapping a bar lists those games. It's the same idea as drill-through in Power BI.

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
