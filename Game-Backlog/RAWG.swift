import Foundation

// STEP 2: Talking to the RAWG game database over the internet.
//
// The flow is the same as pulling data from any REST API:
//   1. Build a URL with your search + API key   (the "request")
//   2. Download the response                    (JSON text)
//   3. Decode the JSON into Swift structs       (like loading rows into a table)

// These structs mirror the parts of RAWG's JSON we care about.
// Anything we don't list here is simply ignored.
struct RAWGSearchResponse: Decodable {
    let results: [RAWGGame]
}

struct RAWGGame: Decodable, Identifiable {
    let id: Int
    let name: String
    let released: String?             // e.g. "2022-02-25"
    let backgroundImage: String?      // cover art URL (JSON key: background_image)
    let genres: [NamedItem]?
    let platforms: [PlatformEntry]?

    struct NamedItem: Decodable { let name: String }
    struct PlatformEntry: Decodable { let platform: NamedItem }

    var releaseYear: Int? {
        released.flatMap { Int($0.prefix(4)) }
    }

    var genreText: String {
        (genres ?? []).prefix(3).map(\.name).joined(separator: ", ")
    }

    // Best guess at which of OUR platform choices fits, based on RAWG's list.
    // Checks our platforms in order (PC first, then newest consoles) and takes the first match.
    var suggestedPlatform: Platform? {
        matchedPlatforms.first
    }

    // Every one of OUR platforms this game came out on, in our list order.
    var matchedPlatforms: [Platform] {
        let names = Set((platforms ?? []).map(\.platform.name))
        return Platform.allCases.filter { p in p.rawgNames.contains(where: names.contains) }
    }
}

enum RAWG {
    static var hasKey: Bool {
        !Secrets.rawgAPIKey.isEmpty && !Secrets.rawgAPIKey.contains("PASTE")
    }

    static func search(_ query: String) async throws -> [RAWGGame] {
        // 1. Build the request URL: https://api.rawg.io/api/games?key=...&search=...
        var components = URLComponents(string: "https://api.rawg.io/api/games")!
        components.queryItems = [
            URLQueryItem(name: "key", value: Secrets.rawgAPIKey),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "page_size", value: "10"),
        ]

        // 2. Download the JSON
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }

        // 3. Decode JSON into structs. convertFromSnakeCase maps background_image → backgroundImage.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(RAWGSearchResponse.self, from: data).results
    }
}
