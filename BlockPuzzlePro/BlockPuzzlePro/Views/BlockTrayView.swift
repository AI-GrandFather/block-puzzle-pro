import SwiftUI

// MARK: - Block Tray View

/// Bottom tray container that displays available blocks for placement
struct BlockTrayView: View {
    
    // MARK: - Properties
    
    @ObservedObject var blockFactory: BlockFactory
    @State private var selectedBlockIndex: Int? = nil
    
    let onBlockSelected: (Int, BlockPattern) -> Void
    let cellSize: CGFloat
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Initialization
    
    init(blockFactory: BlockFactory, 
         cellSize: CGFloat = 35,
         onBlockSelected: @escaping (Int, BlockPattern) -> Void) {
        self.blockFactory = blockFactory
        self.cellSize = cellSize
        self.onBlockSelected = onBlockSelected
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Tray header (optional)
            trayHeader
            
            // Main tray container
            HStack(spacing: 0) {
                ForEach(Array(blockFactory.getTraySlots().enumerated()), id: \.offset) { index, blockPattern in
                    blockSlot(for: blockPattern, at: index)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(trayBackground)
        }
    }
    
    // MARK: - View Components
    
    private var trayHeader: some View {
        EmptyView()
    }
    
    private func blockSlot(for blockPattern: BlockPattern?, at index: Int) -> some View {
        let isSelected = selectedBlockIndex == index
        let blockSize = calculateBlockSlotSize()
        
        return VStack(spacing: 8) {
            // Block visualization
            ZStack {
                // Selection background
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                    .frame(width: blockSize.width, height: blockSize.height)
                
                // Block view
                if let pattern = blockPattern {
                    BlockView(
                        blockPattern: pattern,
                        cellSize: cellSize,
                        isInteractive: true
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                        .foregroundColor(.secondary.opacity(0.35))
                        .frame(width: blockSize.width - 8, height: blockSize.height - 8)
                        .overlay(
                            Image(systemName: "hourglass")
                                .font(.title3.bold())
                                .foregroundColor(.secondary.opacity(0.5))
                        )
                }
            }
            .frame(width: blockSize.width, height: blockSize.height)
            .contentShape(Rectangle()) // Makes entire area tappable
            .onTapGesture {
                guard let pattern = blockPattern else { return }
                handleBlockSelection(at: index, blockPattern: pattern)
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(blockPattern?.type.displayName ?? "Slot empty")
            .accessibilityHint(blockPattern == nil ? "Slot waits for the next block refresh" : "Double tap to select this block for placement")
            
            // Block type indicator
            if let pattern = blockPattern {
                Text(blockTypeIndicator(for: pattern.type))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(0.8)
            } else {
                Text("Awaiting")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity) // Equal spacing
        .padding(.horizontal, 8)
    }
    
    private var trayBackground: some View {
        let gradient = LinearGradient(
            colors: [
                Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.6 : 0.85),
                Color(UIColor.systemBackground).opacity(colorScheme == .dark ? 0.4 : 0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return RoundedRectangle(cornerRadius: 18)
            .fill(gradient)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.18), radius: 14, x: 0, y: 10)
    }
    
    // MARK: - Helper Methods
    
    private func calculateBlockSlotSize() -> CGSize {
        let maxBlockWidth: CGFloat = 3 * cellSize + 6 // accommodate wider shapes
        let maxBlockHeight: CGFloat = 3 * cellSize + 6 // accommodate taller shapes
        let padding: CGFloat = 16
        
        return CGSize(
            width: maxBlockWidth + padding,
            height: maxBlockHeight + padding
        )
    }
    
    private func blockTypeIndicator(for blockType: BlockType) -> String {
        switch blockType {
        case .single: return "•"
        case .horizontal: return "═"
        case .vertical: return "║"
        case .lineThree: return "≡"
        case .lineThreeVertical: return "‖"
        case .lineFourVertical: return "⎮"
        case .square: return "▣"
        case .lShape: return "└"
        case .tShape: return "┴"
        case .zigZag: return "≈"
        case .plus: return "✛"
        }
    }
    
    private func handleBlockSelection(at index: Int, blockPattern: BlockPattern) {
        // Visual feedback
        selectedBlockIndex = index
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Callback to parent
        onBlockSelected(index, blockPattern)
        
        // Reset selection after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            selectedBlockIndex = nil
        }
    }
}

// MARK: - Tray Container

/// Container that manages the tray position and layout within the game screen
struct TrayContainerView: View {
    
    // MARK: - Properties
    
    @ObservedObject var blockFactory: BlockFactory
    let screenSize: CGSize
    let onBlockSelected: (Int, BlockPattern) -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Spacer() // Push tray to bottom
            
            BlockTrayView(
                blockFactory: blockFactory,
                cellSize: calculateOptimalCellSize(),
                onBlockSelected: onBlockSelected
            )
            .padding(.horizontal, 20)
            .padding(.bottom, safeAreaInset)
        }
    }
    
    // MARK: - Layout Calculations
    
    private func calculateOptimalCellSize() -> CGFloat {
        let availableWidth = screenSize.width - 40 // Account for padding
        let maxCellSize: CGFloat = 40
        let minCellSize: CGFloat = 25
        
        // Calculate based on available space for three blocks
        let calculatedSize = (availableWidth - 60) / 8 // Rough calculation for three blocks
        
        return max(minCellSize, min(maxCellSize, calculatedSize))
    }
    
    private var safeAreaInset: CGFloat {
        // Calculate safe area for different device types
        let aspectRatio = screenSize.height / screenSize.width
        
        if aspectRatio > 2.0 { // iPhone X and later
            return 34.0
        } else { // Older iPhones
            return 16.0
        }
    }
}

// MARK: - Tray Constants

extension VisualConstants {
    struct BlockTray {
        /// Height percentage of screen dedicated to block tray
        static let heightPercentage: CGFloat = 0.15
        
        /// Minimum spacing between block slots
        static let minimumSlotSpacing: CGFloat = 20.0
        
        /// Padding around the entire tray
        static let containerPadding: CGFloat = 20.0
        
        /// Corner radius for tray background
        static let cornerRadius: CGFloat = 12.0
        
        /// Shadow properties
        static let shadowRadius: CGFloat = 4.0
        static let shadowOffset: CGPoint = CGPoint(x: 0, y: 2)
        
        /// Animation duration for block selection
        static let selectionAnimationDuration: TimeInterval = 0.2
        
        /// Scale factor for selected block
        static let selectionScaleFactor: CGFloat = 1.1
    }
}

// MARK: - Preview

#Preview {
    let mockBlockFactory = BlockFactory()
    
    return VStack {
        Spacer()
        
        BlockTrayView(
            blockFactory: mockBlockFactory,
            cellSize: 35
        ) { index, blockPattern in
            DebugLog.trace("Selected block \(index): \(blockPattern.type)")
        }
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor.systemBackground))
}
