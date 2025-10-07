import Foundation

// MARK: - JSON Level Models

/// JSON-based level definition (single source of truth)
struct JSONLevel: Codable, Identifiable {
    let id: String
    let pack: String
    let difficulty: JSONDifficulty
    let `init`: JSONLevelInit
    let pieceset: String
    let goal: JSONLevelGoal
    let limits: JSONLevelLimits
    let hints: JSONLevelHints
    let starRules: JSONStarRules

    enum CodingKeys: String, CodingKey {
        case id, pack, difficulty
        case `init`
        case pieceset, goal, limits, hints, starRules
    }
}

struct JSONLevelInit: Codable {
    let prefill: [[Int]]     // 8x8 grid: 0 = empty, 1 = filled
    let obstacles: [[Int]]?  // 8x8 grid: 0 = empty, 1 = obstacle (unremovable)
}

enum JSONDifficulty: String, Codable {
    case easy
    case normal
    case hard
    case expert
}

struct JSONLevelGoal: Codable {
    let type: JSONGoalType
    let value: Int

    enum JSONGoalType: String, Codable {
        case score
        case clear_lines
        case clear_cells
        case complete_pattern
        case survive_moves
    }
}

struct JSONLevelLimits: Codable {
    let moves: Int?
    let time: Int?  // seconds
}

struct JSONLevelHints: Codable {
    let pattern: String?  // "T", "ring", "diag", "none", etc.
}

struct JSONStarRules: Codable {
    let three: String  // e.g., ">= target"
    let two: String    // e.g., ">= 0.8*target"
    let one: String    // e.g., ">= 0.6*target"

    enum CodingKeys: String, CodingKey {
        case three = "3"
        case two = "2"
        case one = "1"
    }

    /// Calculate stars earned based on achieved value
    func calculateStars(achieved: Int, target: Int) -> Int {
        // Parse rules (simplified)
        let threeStarThreshold = target
        let twoStarThreshold = Int(Double(target) * 0.8)
        let oneStarThreshold = Int(Double(target) * 0.6)

        if achieved >= threeStarThreshold {
            return 3
        } else if achieved >= twoStarThreshold {
            return 2
        } else if achieved >= oneStarThreshold {
            return 1
        } else {
            return 0
        }
    }
}

// MARK: - Level Collection

struct JSONLevelCollection: Codable {
    let levels: [JSONLevel]
}

// MARK: - Conversion to Runtime Level

extension JSONLevel {
    /// Convert JSON level to runtime Level model
    func toLevel(packID: Int, indexInPack: Int) -> Level {
        let objective = convertGoal()
        let constraints = convertLimits()
        let prefillData = convertPrefill()
        let starThresholds = convertStarRules()
        let rewards = generateRewards()

        return Level(
            id: hashID(),
            packID: packID,
            indexInPack: indexInPack,
            title: generateTitle(),
            description: generateDescription(),
            objective: objective,
            constraints: constraints,
            prefill: prefillData,
            starThresholds: starThresholds,
            rewards: rewards,
            difficulty: convertDifficulty(),
            unlockRequirement: .none
        )
    }

    private func hashID() -> Int {
        // Generate deterministic ID from string ID
        return abs(id.hashValue) % 1000000
    }

    private func generateTitle() -> String {
        switch goal.type {
        case .score:
            return "Score \(goal.value) Points"
        case .clear_lines:
            return "Clear \(goal.value) Lines"
        case .clear_cells:
            return "Clear \(goal.value) Blocks"
        case .complete_pattern:
            return "Complete the Pattern"
        case .survive_moves:
            return "Survive \(goal.value) Moves"
        }
    }

    private func generateDescription() -> String {
        switch pack {
        case "learning":
            return "Learn the basics and have fun!"
        case "shape":
            return "Complete the pattern shown"
        case "quick":
            return "Quick challenge - beat the clock!"
        case "puzzle":
            return "Solve this tricky puzzle"
        case "expert":
            return "Expert challenge - use strategy!"
        default:
            return "Complete the objective"
        }
    }

    private func convertGoal() -> LevelObjective {
        switch goal.type {
        case .score:
            return LevelObjective(type: .reachScore, targetValue: goal.value)
        case .clear_lines:
            return LevelObjective(type: .clearLines, targetValue: goal.value)
        case .clear_cells:
            return LevelObjective(type: .clearAllBlocks, targetValue: goal.value)
        case .complete_pattern:
            return LevelObjective(type: .completePattern, targetValue: 1)
        case .survive_moves:
            return LevelObjective(type: .surviveMoves, targetValue: goal.value)
        }
    }

    private func convertLimits() -> LevelConstraints {
        return LevelConstraints(
            moveLimit: limits.moves,
            timeLimit: limits.time,
            allowedPieces: nil  // Use default pieceset
        )
    }

    private func convertPrefill() -> LevelPrefill? {
        var cells: [LevelPrefill.Cell] = []

        // Convert prefill array to cells
        for (row, rowData) in `init`.prefill.enumerated() {
            for (col, value) in rowData.enumerated() {
                if value == 1 {
                    cells.append(LevelPrefill.Cell(
                        row: row,
                        column: col,
                        color: .blue,
                        isLocked: false
                    ))
                }
            }
        }

        // Add obstacles as locked cells
        if let obstacles = `init`.obstacles {
            for (row, rowData) in obstacles.enumerated() {
                for (col, value) in rowData.enumerated() {
                    if value == 1 {
                        cells.append(LevelPrefill.Cell(
                            row: row,
                            column: col,
                            color: .gray,
                            isLocked: true
                        ))
                    }
                }
            }
        }

        return cells.isEmpty ? nil : LevelPrefill(cells: cells)
    }

    private func convertStarRules() -> LevelStarThresholds {
        let target = goal.value
        return LevelStarThresholds(
            oneStar: StarRequirement(type: .specificObjective, value: Int(Double(target) * 0.6)),
            twoStar: StarRequirement(type: .specificObjective, value: Int(Double(target) * 0.8)),
            threeStar: StarRequirement(type: .specificObjective, value: target)
        )
    }

    private func generateRewards() -> LevelRewards {
        let difficultyMultiplier: Int
        switch difficulty {
        case .easy: difficultyMultiplier = 1
        case .normal: difficultyMultiplier = 2
        case .hard: difficultyMultiplier = 3
        case .expert: difficultyMultiplier = 4
        }

        return LevelRewards(
            xp: 100 * difficultyMultiplier,
            coins: 50 * difficultyMultiplier,
            unlock: nil
        )
    }

    private func convertDifficulty() -> DifficultyLevel {
        switch difficulty {
        case .easy: return .easy
        case .normal: return .medium
        case .hard: return .hard
        case .expert: return .expert
        }
    }
}
