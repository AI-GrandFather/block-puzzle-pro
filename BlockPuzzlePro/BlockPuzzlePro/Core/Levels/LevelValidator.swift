import Foundation

/// Validates levels for solvability and balance
struct LevelValidator {
    /// Validation result
    struct ValidationResult {
        let solvable: Bool
        let estMoves: Int
        let estMinLines: Int
        let warnings: [String]
        let errors: [String]

        var isValid: Bool {
            return solvable && errors.isEmpty
        }
    }

    /// Validate a single JSON level
    static func validate(level: JSONLevel) -> ValidationResult {
        var warnings: [String] = []
        var errors: [String] = []

        // Check grid dimensions
        if level.`init`.prefill.count != 8 {
            errors.append("Prefill must be 8x8 (got \(level.`init`.prefill.count) rows)")
        }
        for (i, row) in level.`init`.prefill.enumerated() {
            if row.count != 8 {
                errors.append("Prefill row \(i) must have 8 columns (got \(row.count))")
            }
        }

        // Check obstacles if present
        if let obstacles = level.`init`.obstacles {
            if obstacles.count != 8 {
                errors.append("Obstacles must be 8x8")
            }
            for (i, row) in obstacles.enumerated() {
                if row.count != 8 {
                    errors.append("Obstacles row \(i) must have 8 columns")
                }
            }
        }

        // Analyze board state
        let analysis = analyzeBoardState(level: level)

        // Check solvability heuristics
        let solvable = checkSolvability(level: level, analysis: analysis, errors: &errors, warnings: &warnings)

        return ValidationResult(
            solvable: solvable,
            estMoves: analysis.estimatedMoves,
            estMinLines: analysis.estimatedLines,
            warnings: warnings,
            errors: errors
        )
    }

    /// Batch validate all levels
    static func validateAll(levels: [String: [JSONLevel]]) -> [String: [ValidationResult]] {
        var results: [String: [ValidationResult]] = [:]

        for (packName, packLevels) in levels {
            results[packName] = packLevels.map { validate(level: $0) }
        }

        return results
    }

    /// Print validation summary
    static func printValidationSummary(results: [String: [ValidationResult]]) {
        print("\n" + "="*60)
        print("LEVEL VALIDATION SUMMARY")
        print("="*60 + "\n")

        var totalLevels = 0
        var solvableLevels = 0
        var levelsWithWarnings = 0
        var levelsWithErrors = 0

        for (packName, packResults) in results.sorted(by: { $0.key < $1.key }) {
            print("📦 \(packName.uppercased()) Pack:")
            print("  Levels: \(packResults.count)")

            let solvable = packResults.filter { $0.solvable }.count
            let withWarnings = packResults.filter { !$0.warnings.isEmpty }.count
            let withErrors = packResults.filter { !$0.errors.isEmpty }.count

            print("  ✅ Solvable: \(solvable)/\(packResults.count)")
            if withWarnings > 0 {
                print("  ⚠️  Warnings: \(withWarnings)")
            }
            if withErrors > 0 {
                print("  ❌ Errors: \(withErrors)")
            }

            // Print individual level details
            for (i, result) in packResults.enumerated() {
                let status = result.solvable ? "✓" : "✗"
                print("    [\(status)] Level \(i+1): Est. \(result.estMoves) moves, \(result.estMinLines) lines")

                for warning in result.warnings {
                    print("        ⚠️  \(warning)")
                }
                for error in result.errors {
                    print("        ❌ \(error)")
                }
            }

            print("")

            totalLevels += packResults.count
            solvableLevels += solvable
            levelsWithWarnings += withWarnings
            levelsWithErrors += withErrors
        }

        print("="*60)
        print("TOTAL: \(solvableLevels)/\(totalLevels) solvable")
        if levelsWithWarnings > 0 {
            print("Warnings: \(levelsWithWarnings) levels")
        }
        if levelsWithErrors > 0 {
            print("Errors: \(levelsWithErrors) levels")
        }
        print("="*60 + "\n")
    }

    // MARK: - Private Helpers

    private struct BoardAnalysis {
        let prefillCount: Int
        let obstacleCount: Int
        let emptySpaces: Int
        let estimatedMoves: Int
        let estimatedLines: Int
        let prefillDensity: Double
    }

    private static func analyzeBoardState(level: JSONLevel) -> BoardAnalysis {
        var prefillCount = 0
        var obstacleCount = 0

        // Count prefilled cells
        for row in level.`init`.prefill {
            prefillCount += row.filter { $0 == 1 }.count
        }

        // Count obstacles
        if let obstacles = level.`init`.obstacles {
            for row in obstacles {
                obstacleCount += row.filter { $0 == 1 }.count
            }
        }

        let totalCells = 64
        let emptySpaces = totalCells - prefillCount - obstacleCount
        let prefillDensity = Double(prefillCount) / Double(totalCells)

        // Estimate moves based on goal type
        let estimatedMoves: Int
        switch level.goal.type {
        case .score:
            // Rough estimate: 15 points per move average
            estimatedMoves = max(1, level.goal.value / 15)
        case .clear_lines:
            // Each line needs ~2-4 moves to complete
            estimatedMoves = level.goal.value * 3
        case .clear_cells:
            // Each block placed clears ~2-4 cells
            estimatedMoves = max(1, level.goal.value / 3)
        case .complete_pattern:
            estimatedMoves = 6  // Pattern completion usually 4-8 moves
        case .survive_moves:
            estimatedMoves = level.goal.value
        }

        // Estimate minimum lines clearable
        let estimatedLines = max(0, emptySpaces / 8)  // Very rough heuristic

        return BoardAnalysis(
            prefillCount: prefillCount,
            obstacleCount: obstacleCount,
            emptySpaces: emptySpaces,
            estimatedMoves: estimatedMoves,
            estimatedLines: estimatedLines,
            prefillDensity: prefillDensity
        )
    }

    private static func checkSolvability(
        level: JSONLevel,
        analysis: BoardAnalysis,
        errors: inout [String],
        warnings: inout [String]
    ) -> Bool {
        var solvable = true

        // Check if move limit is reasonable
        if let moveLimit = level.limits.moves {
            if moveLimit < analysis.estimatedMoves / 2 {
                errors.append("Move limit too tight: \(moveLimit) vs estimated \(analysis.estimatedMoves)")
                solvable = false
            } else if moveLimit < analysis.estimatedMoves {
                warnings.append("Move limit challenging: \(moveLimit) vs estimated \(analysis.estimatedMoves)")
            }
        }

        // Check if time limit is reasonable (if goal is time-based)
        if let timeLimit = level.limits.time {
            if timeLimit < 30 && analysis.estimatedMoves > 10 {
                warnings.append("Time limit may be tight: \(timeLimit)s for ~\(analysis.estimatedMoves) moves")
            }
        }

        // Check if goal is achievable
        switch level.goal.type {
        case .clear_lines:
            if level.goal.value > analysis.estimatedLines + 5 {
                warnings.append("Clear lines goal may be difficult: \(level.goal.value) vs estimated \(analysis.estimatedLines)")
            }

        case .clear_cells:
            if level.goal.value > analysis.prefillCount {
                errors.append("Clear cells goal impossible: \(level.goal.value) > prefill \(analysis.prefillCount)")
                solvable = false
            }

        case .score:
            // Very rough check: assume 10-20 points per move
            let maxPossibleScore = (level.limits.moves ?? 20) * 20
            if level.goal.value > maxPossibleScore {
                warnings.append("Score goal may be difficult: \(level.goal.value) vs max ~\(maxPossibleScore)")
            }

        case .survive_moves:
            if let moveLimit = level.limits.moves, moveLimit < level.goal.value {
                errors.append("Survive moves impossible: goal \(level.goal.value) > limit \(moveLimit)")
                solvable = false
            }

        case .complete_pattern:
            // Pattern completion validation would require pattern definition
            break
        }

        // Check density is reasonable
        if analysis.prefillDensity > 0.5 {
            warnings.append("High prefill density: \(Int(analysis.prefillDensity * 100))%")
        }

        // Check for impossible board states (all obstacles, no space)
        if analysis.emptySpaces < 9 {  // Need at least 3x3 space
            errors.append("Not enough empty space: \(analysis.emptySpaces) cells")
            solvable = false
        }

        return solvable
    }
}

// MARK: - String Repeat Helper

private extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
