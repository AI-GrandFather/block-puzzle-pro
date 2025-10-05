import Foundation
import SwiftUI
import Combine

/// Manages the "hold piece" mechanic where players can store one piece for later use
@MainActor
final class HoldPieceManager: ObservableObject {

    // MARK: - Published Properties

    /// The currently held piece (if any)
    @Published var heldPiece: BlockPattern?

    /// Whether a hold swap is allowed (prevents rapid swapping)
    @Published var canSwap: Bool = true

    /// Animation state for hold slot
    @Published var isSwapping: Bool = false

    // MARK: - Private Properties

    private let maxHolds: Int = 1

    // MARK: - Initialization

    init() {
        self.heldPiece = nil
    }

    // MARK: - Hold Operations

    /// Attempt to hold a piece or swap with currently held piece
    /// - Parameters:
    ///   - piece: The piece to hold
    ///   - completion: Called with the piece to return to tray (if swapping)
    /// - Returns: True if the hold was successful
    @discardableResult
    func holdOrSwap(_ piece: BlockPattern, completion: ((BlockPattern?) -> Void)? = nil) -> Bool {
        guard canSwap else { return false }

        isSwapping = true

        // Swap or store
        let previousPiece = heldPiece
        heldPiece = piece

        // Temporarily disable swapping to prevent rapid cycling
        canSwap = false

        // Re-enable after a brief cooldown
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            self.canSwap = true
            self.isSwapping = false
        }

        // Call completion with the piece to return (if any)
        completion?(previousPiece)

        return true
    }

    /// Release the held piece back to play
    /// - Returns: The held piece, if any
    func release() -> BlockPattern? {
        guard let piece = heldPiece else { return nil }

        heldPiece = nil
        canSwap = true

        return piece
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
    }

    // MARK: - Persistence

    func save() -> HoldPieceState {
        HoldPieceState(
            heldPiece: heldPiece,
            canSwap: canSwap
        )
    }

    func restore(from state: HoldPieceState) {
        heldPiece = state.heldPiece
        canSwap = state.canSwap
        isSwapping = false
    }
}

// MARK: - Hold Piece State

struct HoldPieceState {
    let heldPiece: BlockPattern?
    let canSwap: Bool
}
