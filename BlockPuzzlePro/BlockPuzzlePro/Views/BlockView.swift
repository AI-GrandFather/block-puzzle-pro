import SwiftUI
import SpriteKit
import UIKit

// MARK: - Block View

/// SwiftUI view for displaying individual blocks
struct BlockView: View {

    // MARK: - Properties

    let blockPattern: BlockPattern
    let cellSize: CGFloat
    let isInteractive: Bool
    let showShadow: Bool  // Control whether to show shadow

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(blockPattern: BlockPattern, cellSize: CGFloat = 30, isInteractive: Bool = true, showShadow: Bool = false) {
        self.blockPattern = blockPattern
        self.cellSize = cellSize
        self.isInteractive = isInteractive
        self.showShadow = showShadow
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: max(cellSize * 0.03, 0.6)) {
            ForEach(0..<blockPattern.cells.count, id: \.self) { row in
                HStack(spacing: max(cellSize * 0.03, 0.6)) {
                    ForEach(0..<blockPattern.cells[row].count, id: \.self) { col in
                        if blockPattern.cells[row][col] {
                            blockCell
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isInteractive ? .isButton : [])
    }
    
    // MARK: - View Components
    
    private var blockCell: some View {
        ZStack {
            // Main cell background
            RoundedRectangle(cornerRadius: cellCornerRadius)
                .fill(cellColor)
                .frame(width: cellSize, height: cellSize)
            
            // Subtle border for definition
            RoundedRectangle(cornerRadius: cellCornerRadius)
                .strokeBorder(borderColor, lineWidth: 1)
                .frame(width: cellSize, height: cellSize)
            
            // Accessibility pattern overlay (opt-in via system accessibility)
            if differentiateWithoutColor {
                accessibilityOverlay
            }
            
            // Subtle highlight for depth
            RoundedRectangle(cornerRadius: cellCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear,
                            Color.black.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: cellSize, height: cellSize)
        }
    }

    private var cellCornerRadius: CGFloat {
        max(4, cellSize * 0.22)
    }
    
    private var cellColor: Color {
        Color(blockPattern.color.uiColor)
    }

    private var borderColor: Color {
        let baseOpacity: Double = colorScheme == .dark ? 0.55 : 0.7
        return cellColor.opacity(baseOpacity)
    }
    
    @ViewBuilder
    private var accessibilityOverlay: some View {
        switch blockPattern.color.accessibilityPattern {
        case "dots":
            dotsPattern
        case "stripes":
            stripesPattern
        case "grid":
            gridPattern
        case "diagonal":
            diagonalPattern
        case "cross":
            crossPattern
        case "waves":
            wavesPattern
        case "checker":
            checkerPattern
        default:
            EmptyView() // solid - no pattern needed
        }
    }
    
    // MARK: - Accessibility Patterns
    
    private var dotsPattern: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: cellSize * 0.3, height: cellSize * 0.3)
        }
    }
    
    private var stripesPattern: some View {
        VStack(spacing: 2) {
            ForEach(0..<Int(cellSize / 6), id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 2)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .clipped()
    }
    
    private var gridPattern: some View {
        Grid {
            ForEach(0..<Int(cellSize / 6), id: \.self) { _ in
                GridRow {
                    ForEach(0..<Int(cellSize / 6), id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 1, height: 1)
                    }
                }
            }
        }
    }
    
    private var diagonalPattern: some View {
        Path { path in
            for i in stride(from: -cellSize, to: cellSize * 2, by: 8) {
                path.move(to: CGPoint(x: i, y: 0))
                path.addLine(to: CGPoint(x: i + cellSize, y: cellSize))
            }
        }
        .stroke(Color.white.opacity(0.4), lineWidth: 2)
        .frame(width: cellSize, height: cellSize)
        .clipped()
    }
    
    private var crossPattern: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(width: cellSize * 0.8, height: 2)
            
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 2, height: cellSize * 0.8)
        }
    }
    
    private var wavesPattern: some View {
        Path { path in
            let waveHeight: CGFloat = 4
            let waveWidth: CGFloat = cellSize / 3
            
            path.move(to: CGPoint(x: 0, y: cellSize / 2))
            
            for i in 0..<3 {
                let x = CGFloat(i) * waveWidth
                path.addCurve(
                    to: CGPoint(x: x + waveWidth, y: cellSize / 2),
                    control1: CGPoint(x: x + waveWidth / 3, y: cellSize / 2 - waveHeight),
                    control2: CGPoint(x: x + 2 * waveWidth / 3, y: cellSize / 2 + waveHeight)
                )
            }
        }
        .stroke(Color.white.opacity(0.5), lineWidth: 2)
        .frame(width: cellSize, height: cellSize)
        .clipped()
    }
    
    private var checkerPattern: some View {
        let checkSize = cellSize / 4
        return VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { col in
                        Rectangle()
                            .fill((row + col) % 2 == 0 ? Color.white.opacity(0.3) : Color.clear)
                            .frame(width: checkSize, height: checkSize)
                    }
                }
            }
        }
        .frame(width: cellSize, height: cellSize)
        .clipped()
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        let typeDescription = blockPattern.type.displayName
        let colorDescription = blockPattern.color.accessibilityDescription
        let sizeDescription = "\(blockPattern.cellCount) cell\(blockPattern.cellCount > 1 ? "s" : "")"
        
        return "\(colorDescription) \(typeDescription), \(sizeDescription)"
    }
}

// MARK: - SpriteKit Block Node

/// SpriteKit node for rendering blocks in the game scene
class BlockNode: SKNode {
    
    // MARK: - Properties
    
    let blockPattern: BlockPattern
    private let cellSize: CGFloat
    private var cellNodes: [SKShapeNode] = []
    
    // MARK: - Initialization
    
    init(blockPattern: BlockPattern, cellSize: CGFloat) {
        self.blockPattern = blockPattern
        self.cellSize = cellSize
        super.init()
        
        setupBlockNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupBlockNodes() {
        // Remove any existing nodes
        removeAllChildren()
        cellNodes.removeAll()
        
        // Create nodes for occupied cells
        for position in blockPattern.occupiedPositions {
            let cellNode = createCellNode(at: position)
            addChild(cellNode)
            cellNodes.append(cellNode)
        }
    }
    
    private func createCellNode(at position: CGPoint) -> SKShapeNode {
        let cellRect = CGRect(
            x: position.x * cellSize,
            y: position.y * cellSize,
            width: cellSize,
            height: cellSize
        )
        
        let cellNode = SKShapeNode(rect: cellRect, cornerRadius: 4)
        
        // Set colors
        cellNode.fillColor = blockPattern.color.skColor
        cellNode.strokeColor = blockPattern.color.skColor.withBrightnessMultiplied(by: 0.8)
        cellNode.lineWidth = 1.0
        
        // Add subtle shadow for depth
        let shadowNode = SKShapeNode(rect: cellRect, cornerRadius: 4)
        shadowNode.fillColor = SKColor.black.withAlphaComponent(0.2)
        shadowNode.strokeColor = SKColor.clear
        shadowNode.position = CGPoint(x: 1, y: -1)
        shadowNode.zPosition = -1
        cellNode.addChild(shadowNode)
        
        return cellNode
    }
    
    // MARK: - Animation Support
    
    func animateAppearance() {
        alpha = 0
        setScale(0.1)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        let animation = SKAction.group([fadeIn, scaleUp])
        
        run(animation)
    }
    
    func animateRemoval(completion: @escaping () -> Void) {
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.2)
        let animation = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([animation, remove])
        
        run(sequence) {
            completion()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Block Types")
            .font(.title2)
            .bold()
        
        HStack(spacing: 30) {
            ForEach(BlockType.allCases) { blockType in
                VStack {
                    BlockView(
                        blockPattern: BlockPattern(
                            type: blockType, 
                            color: blockType == .lShape ? .orange : 
                                   blockType == .single ? .blue : .green
                        ),
                        cellSize: 40
                    )
                    
                    Text(blockType.displayName)
                        .font(.caption)
                }
            }
        }
    }
    .padding()
}

// MARK: - UIColor Extensions

extension UIColor {
    
    /// Creates a new color by multiplying the brightness component
    /// - Parameter factor: The factor to multiply brightness by (0.0 to 1.0+)
    /// - Returns: A new UIColor with adjusted brightness
    func withBrightnessMultiplied(by factor: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Try to get HSB values
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            // Multiply brightness and clamp to [0.0, 1.0]
            let newBrightness = max(0.0, min(1.0, brightness * factor))
            return UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
        }
        
        // Fallback: try RGB manipulation if HSB doesn't work
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        
        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            // Apply brightness factor to RGB components
            let newRed = max(0.0, min(1.0, red * factor))
            let newGreen = max(0.0, min(1.0, green * factor))
            let newBlue = max(0.0, min(1.0, blue * factor))
            return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: alpha)
        }
        
        // If all else fails, return the original color
        return self
    }
}
