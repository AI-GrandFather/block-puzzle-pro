import Foundation
import SwiftUI
import Combine

// MARK: - Power-Up Types

enum PowerUpType: String, Codable, CaseIterable {
    case rotateToken = "rotate_token"
    case bomb = "bomb"
    case singleBlock = "single_block"
    case clearRow = "clear_row"
    case clearColumn = "clear_column"

    var displayName: String {
        switch self {
        case .rotateToken: return "Rotate"
        case .bomb: return "Bomb"
        case .singleBlock: return "Single Block"
        case .clearRow: return "Clear Row"
        case .clearColumn: return "Clear Column"
        }
    }

    var iconName: String {
        switch self {
        case .rotateToken: return "arrow.triangle.2.circlepath"
        case .bomb: return "burst.fill"
        case .singleBlock: return "square.fill"
        case .clearRow: return "rectangle.fill"
        case .clearColumn: return "rectangle.portrait.fill"
        }
    }

    var description: String {
        switch self {
        case .rotateToken:
            return "Rotate a piece 90 degrees"
        case .bomb:
            return "Clear a 3x3 area"
        case .singleBlock:
            return "Place a single block anywhere"
        case .clearRow:
            return "Clear an entire row"
        case .clearColumn:
            return "Clear an entire column"
        }
    }

    var earnFrequency: Int {
        switch self {
        case .rotateToken: return 3  // Every 3 line clears
        case .bomb: return 5         // Every 5 line clears
        case .singleBlock: return 4  // Every 4 line clears
        case .clearRow: return 7     // Every 7 line clears
        case .clearColumn: return 7  // Every 7 line clears
        }
    }
}

// MARK: - Power-Up Item

struct PowerUpItem: Identifiable, Codable {
    let id: UUID
    let type: PowerUpType
    var count: Int

    init(type: PowerUpType, count: Int = 1) {
        self.id = UUID()
        self.type = type
        self.count = count
    }
}

// MARK: - Power-Up Manager

@MainActor
final class PowerUpManager: ObservableObject {

    // MARK: - Published Properties

    @Published var inventory: [PowerUpType: Int] = [:]
    @Published var activePowerUp: PowerUpType?
    @Published var isSelectingTarget: Bool = false

    // MARK: - Private Properties

    private var lineClearCounter: Int = 0
    private let userDefaultsKey = "powerup_inventory"

    // MARK: - Initialization

    init() {
        loadInventory()
    }

    // MARK: - Inventory Management

    func addPowerUp(_ type: PowerUpType, count: Int = 1) {
        inventory[type, default: 0] += count
        saveInventory()
    }

    func usePowerUp(_ type: PowerUpType) -> Bool {
        guard let count = inventory[type], count > 0 else {
            return false
        }

        inventory[type] = count - 1
        saveInventory()
        return true
    }

    func count(for type: PowerUpType) -> Int {
        return inventory[type, default: 0]
    }

    // MARK: - Power-Up Earning

    func onLineClear(linesCleared: Int) {
        lineClearCounter += linesCleared

        for type in PowerUpType.allCases {
            let frequency = type.earnFrequency
            if lineClearCounter % frequency == 0 {
                addPowerUp(type)
            }
        }
    }

    // MARK: - Power-Up Activation

    func selectPowerUp(_ type: PowerUpType) {
        guard count(for: type) > 0 else { return }

        activePowerUp = type

        // Some power-ups require target selection
        switch type {
        case .bomb, .singleBlock, .clearRow, .clearColumn:
            isSelectingTarget = true
        case .rotateToken:
            // Rotation is applied directly to selected piece
            isSelectingTarget = false
        }
    }

    func cancelSelection() {
        activePowerUp = nil
        isSelectingTarget = false
    }

    func confirmActivation() {
        activePowerUp = nil
        isSelectingTarget = false
    }

    // MARK: - Persistence

    private func saveInventory() {
        do {
            let data = try JSONEncoder().encode(inventory)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save power-up inventory: \(error)")
        }
    }

    private func loadInventory() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }

        do {
            inventory = try JSONDecoder().decode([PowerUpType: Int].self, from: data)
        } catch {
            print("Failed to load power-up inventory: \(error)")
        }
    }

    // MARK: - Reset

    func reset() {
        inventory.removeAll()
        activePowerUp = nil
        isSelectingTarget = false
        lineClearCounter = 0
        saveInventory()
    }
}

// MARK: - Power-Up Application Logic

extension PowerUpManager {

    func applyBomb(at position: GridPosition, gameEngine: GameEngine) -> Bool {
        guard usePowerUp(.bomb) else { return false }

        var clearedPositions: [GridPosition] = []

        // Clear 3x3 area around the position
        for row in (position.row - 1)...(position.row + 1) {
            for col in (position.column - 1)...(position.column + 1) {
                if let gridPos = GridPosition(row: row, column: col, gridSize: gameEngine.gridSize),
                   gameEngine.canClearAt(position: gridPos) {
                    clearedPositions.append(gridPos)
                }
            }
        }

        gameEngine.clearBlocks(at: clearedPositions)
        confirmActivation()
        return true
    }

    func applySingleBlock(at position: GridPosition, gameEngine: GameEngine, color: BlockColor) -> Bool {
        guard usePowerUp(.singleBlock) else { return false }
        guard gameEngine.canPlaceAt(position: position) else { return false }

        _ = gameEngine.placeBlocks(at: [position], color: color)
        confirmActivation()
        return true
    }

    func applyClearRow(row: Int, gameEngine: GameEngine) -> Bool {
        guard usePowerUp(.clearRow) else { return false }
        guard row >= 0 && row < gameEngine.gridSize else { return false }

        var clearedPositions: [GridPosition] = []
        for col in 0..<gameEngine.gridSize {
            if let pos = GridPosition(row: row, column: col, gridSize: gameEngine.gridSize) {
                clearedPositions.append(pos)
            }
        }

        gameEngine.clearBlocks(at: clearedPositions)
        confirmActivation()
        return true
    }

    func applyClearColumn(column: Int, gameEngine: GameEngine) -> Bool {
        guard usePowerUp(.clearColumn) else { return false }
        guard column >= 0 && column < gameEngine.gridSize else { return false }

        var clearedPositions: [GridPosition] = []
        for row in 0..<gameEngine.gridSize {
            if let pos = GridPosition(row: row, column: column, gridSize: gameEngine.gridSize) {
                clearedPositions.append(pos)
            }
        }

        gameEngine.clearBlocks(at: clearedPositions)
        confirmActivation()
        return true
    }
}
