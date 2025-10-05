import Foundation
import SwiftUI
import Combine
import os.log

// MARK: - Swap Mode

/// Different swap limitation strategies
enum SwapMode: Equatable, Codable {
    case unlimited              // No restrictions (beginner-friendly)
    case oncePerTurn           // One swap per piece placement
    case limitedUses(Int)      // Fixed number of swaps per game

    var displayName: String {
        switch self {
        case .unlimited:
            return "Unlimited"
        case .oncePerTurn:
            return "Once Per Turn"
        case .limitedUses(let count):
            return "\(count) Uses"
        }
    }
}

// MARK: - Hold Piece Manager

/// Manages the "hold piece" mechanic where players can store one piece for later use
@MainActor
@Observable
final class HoldPieceManager {

    // MARK: - Published Properties

    /// The currently held piece (if any)
    var heldPiece: BlockPattern?

    /// Whether a hold swap is allowed
    var canSwap: Bool = true

    /// Current swap mode configuration
    var swapMode: SwapMode = .unlimited

    /// Remaining hold swaps (for limited mode)
    var remainingHolds: Int = 10

    /// Whether a swap animation is in progress
    var isSwapping: Bool = false

    /// Cooldown state for once-per-turn mode
    var isOnCooldown: Bool = false

    /// Animation rotation angle for swap effect
    var swapRotation: Double = 0.0

    /// Animation scale for swap effect
    var swapScale: Double = 1.0

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.blockpuzzlepro", category: "HoldPieceManager")

    /// Initial holds count for limited mode
    private let initialHoldsCount: Int = 10

    // MARK: - Initialization

    init(swapMode: SwapMode = .unlimited) {
        self.swapMode = swapMode
        self.remainingHolds = initialHoldsCount
    }

    // MARK: - Hold Operations

    /// Attempt to hold a piece or swap with currently held piece
    /// - Parameters:
    ///   - piece: The piece to hold
    ///   - completion: Called with the piece to return (if swapping)
    /// - Returns: True if the hold was successful
    @discardableResult
    func holdOrSwap(_ piece: BlockPattern, completion: ((BlockPattern?) -> Void)? = nil) -> Bool {
        // Check if swap is allowed
        guard canSwapPiece() else {
            logger.info("Hold swap denied: \(self.swapDenialReason())")
            return false
        }

        // Start swap animation
        isSwapping = true
        triggerSwapAnimation()

        // Perform swap
        let previousPiece = heldPiece
        heldPiece = piece

        // Update state based on swap mode
        updateStateAfterSwap()

        // Call completion after animation
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds (animation duration)
            self.isSwapping = false
            completion?(previousPiece)
        }

        logger.info("Hold swap successful: mode=\(self.swapMode.displayName) remaining=\(self.remainingHolds)")
        return true
    }

    /// Release the held piece back to play
    /// - Returns: The held piece, if any
    func release() -> BlockPattern? {
        guard let piece = heldPiece else { return nil }

        heldPiece = nil
        logger.info("Released held piece: \(piece.type.displayName)")

        return piece
    }

    /// Reset cooldown after piece placement
    func resetCooldown() {
        isOnCooldown = false
        logger.debug("Cooldown reset")
    }

    /// Check if a piece can be swapped
    func canSwapPiece() -> Bool {
        // Check cooldown
        if isOnCooldown {
            return false
        }

        // Check limited uses
        if case .limitedUses = swapMode, remainingHolds <= 0 {
            return false
        }

        // Check if already swapping
        if isSwapping {
            return false
        }

        return canSwap
    }

    /// Get reason why swap is denied (for UI feedback)
    func swapDenialReason() -> String {
        if isOnCooldown {
            return "Cooldown active - place piece first"
        }
        if case .limitedUses = swapMode, remainingHolds <= 0 {
            return "No holds remaining"
        }
        if isSwapping {
            return "Swap in progress"
        }
        if !canSwap {
            return "Swap not allowed"
        }
        return "Unknown"
    }

    /// Check if there's a piece currently held
    var hasHeldPiece: Bool {
        heldPiece != nil
    }

    /// Reset the hold state
    func reset() {
        heldPiece = nil
        canSwap = true
        isSwapping = false
        isOnCooldown = false
        remainingHolds = initialHoldsCount
        swapRotation = 0.0
        swapScale = 1.0
        logger.info("Hold state reset")
    }

    /// Configure swap mode
    func configureSwapMode(_ mode: SwapMode) {
        swapMode = mode

        // Reset state for new mode
        isOnCooldown = false

        if case .limitedUses(let count) = mode {
            remainingHolds = count
        } else {
            remainingHolds = initialHoldsCount
        }

        logger.info("Swap mode configured: \(mode.displayName)")
    }

    // MARK: - Private Helpers

    private func updateStateAfterSwap() {
        switch swapMode {
        case .unlimited:
            // No restrictions
            break

        case .oncePerTurn:
            // Enable cooldown until piece is placed
            isOnCooldown = true

        case .limitedUses(let count):
            // Decrement remaining holds
            remainingHolds = max(0, count - 1)

            // Update mode with new count
            if remainingHolds > 0 {
                swapMode = .limitedUses(remainingHolds)
            }
        }
    }

    private func triggerSwapAnimation() {
        // Rotation animation (180° clockwise for active, counter-clockwise for held)
        withAnimation(.easeInOut(duration: 0.3)) {
            swapRotation = 180.0
            swapScale = 0.8
        }

        // Reset rotation after animation
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation(.easeOut(duration: 0.15)) {
                self.swapRotation = 0.0
                self.swapScale = 1.0
            }
        }
    }

    // MARK: - Badge State

    /// Get badge color based on remaining holds
    func getBadgeColor() -> Color {
        guard case .limitedUses = swapMode else {
            return .clear
        }

        switch remainingHolds {
        case 6...:
            return .green
        case 3...5:
            return .yellow
        case 1...2:
            return .orange
        case 0:
            return .red
        default:
            return .gray
        }
    }

    /// Whether to show the badge (only for limited mode)
    var shouldShowBadge: Bool {
        if case .limitedUses = swapMode {
            return true
        }
        return false
    }

    // MARK: - Persistence

    func save() -> HoldPieceState {
        HoldPieceState(
            heldPiece: heldPiece,
            canSwap: canSwap,
            swapMode: swapMode,
            remainingHolds: remainingHolds,
            isOnCooldown: isOnCooldown
        )
    }

    func restore(from state: HoldPieceState) {
        heldPiece = state.heldPiece
        canSwap = state.canSwap
        swapMode = state.swapMode
        remainingHolds = state.remainingHolds
        isOnCooldown = state.isOnCooldown
        isSwapping = false
        swapRotation = 0.0
        swapScale = 1.0

        logger.info("Hold state restored: mode=\(swapMode.displayName) remaining=\(remainingHolds)")
    }
}

// MARK: - Hold Piece State

struct HoldPieceState: Codable {
    let heldPiece: BlockPattern?
    let canSwap: Bool
    let swapMode: SwapMode
    let remainingHolds: Int
    let isOnCooldown: Bool
}

// MARK: - BlockPattern Codable Extension

extension BlockPattern: Codable {
    enum CodingKeys: String, CodingKey {
        case type, color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BlockType.self, forKey: .type)
        let color = try container.decode(BlockColor.self, forKey: .color)
        self.init(type: type, color: color)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(color, forKey: .color)
    }
}

// MARK: - BlockType Codable Extension

extension BlockType: Codable {}
