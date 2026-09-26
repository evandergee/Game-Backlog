import Foundation

// Every game platform the app knows about, grouped by family for the picker.
// Covers all 51 platforms in RAWG's database (checked Sept 2026), plus a few RAWG doesn't track.
//
// IMPORTANT: the text after "=" (the raw value) is what's saved in the database.
// The first six keep their ORIGINAL saved values ("playstation", "xbox", ...) so games
// you already added still load. Never change a raw value once it's been used;
// only add new cases.

enum PlatformFamily: String, CaseIterable, Identifiable {
    case pc = "PC & Mac"
    case playstation = "PlayStation"
    case xbox = "Xbox"
    case nintendo = "Nintendo"
    case mobile = "Mobile & Web"
    case vr = "VR"
    case sega = "Sega"
    case atari = "Atari"
    case retro = "Other Retro & Computers"
    case other = "Other"
    var id: String { rawValue }
}

enum Platform: String, CaseIterable, Identifiable, Codable {
    // PC & Mac
    case pc                          // "pc"  (original)
    case mac, linux, steamDeck

    // PlayStation
    case ps5 = "playstation"         // original "PlayStation" choice → now PS5
    case ps4, ps3, ps2, ps1, psVita, psp

    // Xbox
    case xboxSeries = "xbox"         // original "Xbox" choice → now Series X|S
    case xboxOne, xbox360, xboxOriginal

    // Nintendo
    case switch2
    case nintendoSwitch              // "nintendoSwitch" (original)
    case wiiU, wii, gameCube, n64, snes, nes
    case n3ds, nds, gba, gbc, gameBoy, virtualBoy

    // Mobile & Web
    case ios = "mobile"              // original "Mobile" choice → now iOS
    case android, web

    // VR
    case metaQuest, psvr2, visionPro, pcVR

    // Sega
    case dreamcast, saturn, genesis, segaCD, sega32X, masterSystem, gameGear

    // Atari
    case atari2600, atari5200, atari7800, jaguar, lynx, atariST, atari8bit, atariFlashback

    // Other retro consoles & computers
    case neoGeo, neoGeoPocket, turboGrafx, threeDO, cdi, colecoVision, intellivision
    case wonderSwan, nGage, playdate, commodore64, amiga, msx, zxSpectrum, appleII, dos

    // Other
    case other                       // "other" (original)

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pc: "PC (Windows)"
        case .mac: "Mac"
        case .linux: "Linux"
        case .steamDeck: "Steam Deck"
        case .ps5: "PlayStation 5"
        case .ps4: "PlayStation 4"
        case .ps3: "PlayStation 3"
        case .ps2: "PlayStation 2"
        case .ps1: "PlayStation (PS1)"
        case .psVita: "PS Vita"
        case .psp: "PSP"
        case .xboxSeries: "Xbox Series X|S"
        case .xboxOne: "Xbox One"
        case .xbox360: "Xbox 360"
        case .xboxOriginal: "Xbox (Original)"
        case .switch2: "Nintendo Switch 2"
        case .nintendoSwitch: "Nintendo Switch"
        case .wiiU: "Wii U"
        case .wii: "Wii"
        case .gameCube: "GameCube"
        case .n64: "Nintendo 64"
        case .snes: "Super Nintendo (SNES)"
        case .nes: "NES"
        case .n3ds: "Nintendo 3DS"
        case .nds: "Nintendo DS"
        case .gba: "Game Boy Advance"
        case .gbc: "Game Boy Color"
        case .gameBoy: "Game Boy"
        case .virtualBoy: "Virtual Boy"
        case .ios: "iOS (iPhone / iPad)"
        case .android: "Android"
        case .web: "Web Browser"
        case .metaQuest: "Meta Quest"
        case .psvr2: "PlayStation VR2"
        case .visionPro: "Apple Vision Pro"
        case .pcVR: "PC VR (SteamVR)"
        case .dreamcast: "Dreamcast"
        case .saturn: "Sega Saturn"
        case .genesis: "Genesis / Mega Drive"
        case .segaCD: "Sega CD"
        case .sega32X: "Sega 32X"
        case .masterSystem: "Master System"
        case .gameGear: "Game Gear"
        case .atari2600: "Atari 2600"
        case .atari5200: "Atari 5200"
        case .atari7800: "Atari 7800"
        case .jaguar: "Atari Jaguar"
        case .lynx: "Atari Lynx"
        case .atariST: "Atari ST"
        case .atari8bit: "Atari 8-bit"
        case .atariFlashback: "Atari Flashback"
        case .neoGeo: "Neo Geo"
        case .neoGeoPocket: "Neo Geo Pocket"
        case .turboGrafx: "TurboGrafx-16 / PC Engine"
        case .threeDO: "3DO"
        case .cdi: "Philips CD-i"
        case .colecoVision: "ColecoVision"
        case .intellivision: "Intellivision"
        case .wonderSwan: "WonderSwan"
        case .nGage: "N-Gage"
        case .playdate: "Playdate"
        case .commodore64: "Commodore 64"
        case .amiga: "Amiga"
        case .msx: "MSX"
        case .zxSpectrum: "ZX Spectrum"
        case .appleII: "Apple II"
        case .dos: "MS-DOS"
        case .other: "Other"
        }
    }

    // Which section of the picker this platform appears in.
    var family: PlatformFamily {
        switch self {
        case .pc, .mac, .linux, .steamDeck: .pc
        case .ps5, .ps4, .ps3, .ps2, .ps1, .psVita, .psp: .playstation
        case .xboxSeries, .xboxOne, .xbox360, .xboxOriginal: .xbox
        case .switch2, .nintendoSwitch, .wiiU, .wii, .gameCube, .n64, .snes, .nes,
             .n3ds, .nds, .gba, .gbc, .gameBoy, .virtualBoy: .nintendo
        case .ios, .android, .web: .mobile
        case .metaQuest, .psvr2, .visionPro, .pcVR: .vr
        case .dreamcast, .saturn, .genesis, .segaCD, .sega32X, .masterSystem, .gameGear: .sega
        case .atari2600, .atari5200, .atari7800, .jaguar, .lynx, .atariST, .atari8bit, .atariFlashback: .atari
        case .neoGeo, .neoGeoPocket, .turboGrafx, .threeDO, .cdi, .colecoVision, .intellivision,
             .wonderSwan, .nGage, .playdate, .commodore64, .amiga, .msx, .zxSpectrum, .appleII, .dos: .retro
        case .other: .other
        }
    }

    // How RAWG spells this platform, so a search result can pick it automatically.
    var rawgNames: [String] {
        switch self {
        case .pc: ["PC"]
        case .mac: ["macOS", "Classic Macintosh"]
        case .linux: ["Linux"]
        case .ps5: ["PlayStation 5"]
        case .ps4: ["PlayStation 4"]
        case .ps3: ["PlayStation 3"]
        case .ps2: ["PlayStation 2"]
        case .ps1: ["PlayStation"]
        case .psVita: ["PS Vita"]
        case .psp: ["PSP"]
        case .xboxSeries: ["Xbox Series S/X"]
        case .xboxOne: ["Xbox One"]
        case .xbox360: ["Xbox 360"]
        case .xboxOriginal: ["Xbox"]
        case .switch2: ["Nintendo Switch 2"]
        case .nintendoSwitch: ["Nintendo Switch"]
        case .wiiU: ["Wii U"]
        case .wii: ["Wii"]
        case .gameCube: ["GameCube"]
        case .n64: ["Nintendo 64"]
        case .snes: ["SNES"]
        case .nes: ["NES"]
        case .n3ds: ["Nintendo 3DS"]
        case .nds: ["Nintendo DS", "Nintendo DSi"]
        case .gba: ["Game Boy Advance"]
        case .gbc: ["Game Boy Color"]
        case .gameBoy: ["Game Boy"]
        case .ios: ["iOS"]
        case .android: ["Android"]
        case .web: ["Web"]
        case .dreamcast: ["Dreamcast"]
        case .saturn: ["SEGA Saturn"]
        case .genesis: ["Genesis"]
        case .segaCD: ["SEGA CD"]
        case .sega32X: ["SEGA 32X"]
        case .masterSystem: ["SEGA Master System"]
        case .gameGear: ["Game Gear"]
        case .atari2600: ["Atari 2600"]
        case .atari5200: ["Atari 5200"]
        case .atari7800: ["Atari 7800"]
        case .jaguar: ["Jaguar"]
        case .lynx: ["Atari Lynx"]
        case .atariST: ["Atari ST"]
        case .atari8bit: ["Atari 8-bit", "Atari XEGS"]
        case .atariFlashback: ["Atari Flashback"]
        case .neoGeo: ["Neo Geo"]
        case .threeDO: ["3DO"]
        case .commodore64, .amiga: ["Commodore / Amiga"]
        case .appleII: ["Apple II"]
        default: []
        }
    }

    // Platforms in one family, in the order listed above (newest first).
    static func inFamily(_ family: PlatformFamily) -> [Platform] {
        allCases.filter { $0.family == family }
    }
}
