import Foundation

/// Loads levels from JSON files in the app bundle
@MainActor
class JSONLevelLoader {
    static let shared = JSONLevelLoader()

    private init() {}

    /// Load all levels from JSON files
    func loadAllLevels() -> [String: [JSONLevel]] {
        var levelsByPack: [String: [JSONLevel]] = [:]

        let packNames = ["learning", "shape", "quick", "puzzle", "expert"]

        for packName in packNames {
            if let levels = loadPack(named: packName) {
                levelsByPack[packName] = levels
            }
        }

        return levelsByPack
    }

    /// Load a specific pack's levels
    func loadPack(named packName: String) -> [JSONLevel]? {
        // Try loading from single file first
        if let levels = loadFromSingleFile(packName: packName) {
            return levels
        }

        // Try loading from multiple files
        if let levels = loadFromMultipleFiles(packName: packName) {
            return levels
        }

        return nil
    }

    /// Load pack from single JSON file (e.g., "learning.json")
    private func loadFromSingleFile(packName: String) -> [JSONLevel]? {
        guard let url = Bundle.main.url(forResource: packName, withExtension: "json", subdirectory: "Levels") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let collection = try JSONDecoder().decode(JSONLevelCollection.self, from: data)
            return collection.levels
        } catch {
            print("❌ Failed to load \(packName).json: \(error)")
            return nil
        }
    }

    /// Load pack from multiple JSON files (e.g., "learning_01.json", "learning_02.json", ...)
    private func loadFromMultipleFiles(packName: String) -> [JSONLevel]? {
        var allLevels: [JSONLevel] = []

        for i in 1...20 {  // Try up to 20 files
            let filename = String(format: "%@_%02d", packName, i)
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Levels") else {
                break  // No more files
            }

            do {
                let data = try Data(contentsOf: url)
                let level = try JSONDecoder().decode(JSONLevel.self, from: data)
                allLevels.append(level)
            } catch {
                print("❌ Failed to load \(filename).json: \(error)")
                continue
            }
        }

        return allLevels.isEmpty ? nil : allLevels
    }

    /// Convert JSON levels to runtime Level models
    func convertToRuntimeLevels(jsonLevels: [String: [JSONLevel]], packMapping: [String: Int]) -> [Int: [Level]] {
        var levelsByPackID: [Int: [Level]] = [:]

        for (packName, jsonLevels) in jsonLevels {
            guard let packID = packMapping[packName] else { continue }

            let runtimeLevels = jsonLevels.enumerated().map { index, jsonLevel in
                jsonLevel.toLevel(packID: packID, indexInPack: index)
            }

            levelsByPackID[packID] = runtimeLevels
        }

        return levelsByPackID
    }

    /// Pack name to ID mapping (matches existing system)
    static let packMapping: [String: Int] = [
        "learning": 1,
        "shape": 2,
        "quick": 3,
        "puzzle": 4,
        "expert": 5
    ]
}
