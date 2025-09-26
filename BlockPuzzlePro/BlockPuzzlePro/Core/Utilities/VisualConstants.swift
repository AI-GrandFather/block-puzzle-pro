import Foundation
import SpriteKit
import UIKit

// MARK: - Visual Constants

/// Constants for visual design throughout the game
struct VisualConstants {
    
    // MARK: - Grid Constants
    
    struct Grid {
        /// Default number of cells per side when a specific game mode is unavailable
        static let defaultSize: Int = 10
        
        /// Grid line width in points
        static let lineWidth: CGFloat = 1.0
        
        /// Grid line opacity
        static let lineOpacity: CGFloat = 0.3
        
        /// Minimum cell size for accessibility
        static let minimumCellSize: CGFloat = 30.0
        
        /// Grid margins from screen edges
        static let minimumMargin: CGFloat = 20.0
        
        /// Cell corner radius for rounded appearance
        static let cellCornerRadius: CGFloat = 2.0
    }
    
    // MARK: - Layout Constants
    
    struct Layout {
        /// Percentage of screen height for score area
        static let scoreAreaPercentage: CGFloat = 0.15
        
        /// Percentage of screen height for grid area
        static let gridAreaPercentage: CGFloat = 0.70
        
        /// Percentage of screen height for block tray area
        static let blockTrayPercentage: CGFloat = 0.15
        
        /// Minimum touch target size (iOS Human Interface Guidelines)
        static let minimumTouchTarget: CGFloat = 44.0
    }
    
    // MARK: - Color Constants
    
    struct Colors {
        /// Grid background color
        static let gridBackground = SKColor.systemBackground

        /// Grid line color - subtle gray for clean geometric style
        static let gridLines = SKColor(red: 0.875, green: 0.875, blue: 0.875, alpha: 1.0) // #E0E0E0
        
        /// Valid placement zone highlight - subtle green tint
        static let validPlacement = SKColor(red: 0.91, green: 0.96, blue: 0.91, alpha: 1.0) // #E8F5E8
        
        /// Invalid placement zone - subtle red tint
        static let invalidPlacement = SKColor(red: 0.96, green: 0.91, blue: 0.91, alpha: 1.0) // #F5E8E8
        
        /// Cell border color - neutral gray
        static let cellBorder = SKColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0) // #CCCCCC

        /// Empty cell background - clean white/neutral
        static let emptyCellBackground = SKColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0) // #FAFAFA

        /// Hover state color for interactive feedback
        static let hoverState = SKColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0) // #F0F0F5

        /// Grid container shadow/outline
        static let gridShadow = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.05)
        
        /// High contrast colors for accessibility
        static let highContrastBorder = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        static let highContrastBackground = SKColor.white
    }
    
    // MARK: - Animation Constants
    
    struct Animation {
        /// Duration for cell state transitions
        static let cellTransitionDuration: TimeInterval = 0.2
        
        /// Duration for preview feedback
        static let previewFeedbackDuration: TimeInterval = 0.1
        
        /// Duration for line clearing animation
        static let lineClearDuration: TimeInterval = 0.3
        
        /// Easing function for smooth transitions
        static let easeInOut: SKActionTimingMode = .easeInEaseOut
    }
    
    // MARK: - Performance Constants
    
    struct Performance {
        /// Target frame rate for smooth gameplay (adaptive based on display)
        static let standardTargetFPS: Int = 60
        static let proMotionTargetFPS: Int = 120
        
        /// Maximum number of nodes to update per frame (scaled for ProMotion)
        static let maxNodesPerFrameStandard: Int = 20
        static let maxNodesPerFrameProMotion: Int = 40
        
        /// Enable node pooling for performance
        static let enableNodePooling: Bool = true
        
        /// ProMotion optimization thresholds
        static let proMotionMinimumRefreshRate: Int = 120
        static let proMotionFrameTimeThreshold: Double = 1.0 / 110.0 // 110 FPS threshold for performance warnings
        
        /// Animation frame rate scaling factors
        static let standardAnimationScale: Double = 1.0
        static let proMotionAnimationScale: Double = 0.5 // Faster animations on ProMotion
    }
    
    // MARK: - Device-Specific Calculations
    
    /// Calculate optimal cell size for current screen
    static func calculateCellSize(for screenSize: CGSize, gridSize: Int = Grid.defaultSize) -> CGFloat {
        let availableWidth = screenSize.width - (Grid.minimumMargin * 2)
        let availableHeight = screenSize.height * Layout.gridAreaPercentage - (Grid.minimumMargin * 2)
        
        // Use the smaller dimension to ensure grid fits
        let availableSize = min(availableWidth, availableHeight)
        
        // Calculate cell size based on grid size and spacing
        let cellSize = availableSize / CGFloat(gridSize)
        
        // Ensure minimum cell size for accessibility
        let calculatedSize = max(cellSize, Grid.minimumCellSize)
        
        // Apply device-specific optimizations
        return optimizeCellSizeForDevice(calculatedSize, screenSize: screenSize)
    }
    
    /// Optimize cell size for specific device characteristics
    private static func optimizeCellSizeForDevice(_ cellSize: CGFloat, screenSize: CGSize) -> CGFloat {
        var optimizedSize = cellSize
        
        // iPhone SE and similar compact devices
        if isCompactDevice(screenSize) {
            // Slightly reduce cell size on compact devices for better fit
            optimizedSize = min(optimizedSize, 32.0)
        }
        
        // iPad and larger devices
        if screenSize.width > 750 { // iPad threshold
            // Ensure cells don't become too large on iPad
            optimizedSize = min(optimizedSize, 60.0)
        }
        
        // Ensure we maintain minimum accessibility requirements
        return max(optimizedSize, Grid.minimumCellSize)
    }
    
    /// Calculate grid position centered on screen
    static func calculateGridPosition(for screenSize: CGSize, cellSize: CGFloat, gridSize: Int = Grid.defaultSize) -> CGPoint {
        let gridWidth = cellSize * CGFloat(gridSize)
        let gridHeight = gridWidth // Square grid
        
        // Calculate center position
        let centerX = screenSize.width / 2
        let centerY = screenSize.height / 2
        
        // Offset slightly up to account for UI elements
        let offsetY = screenSize.height * (Layout.scoreAreaPercentage - Layout.blockTrayPercentage) / 2
        
        return CGPoint(
            x: centerX - gridWidth / 2,
            y: centerY - gridHeight / 2 + offsetY
        )
    }
    
    /// Check if device size requires compact layout
    static func isCompactDevice(_ screenSize: CGSize) -> Bool {
        return screenSize.width <= 375 // iPhone SE and similar
    }
    
    /// Get device category for layout optimizations
    static func getDeviceCategory(for screenSize: CGSize) -> DeviceCategory {
        let width = screenSize.width
        let height = screenSize.height
        let maxDimension = max(width, height)
        
        if maxDimension >= 1024 { // iPad Pro 12.9" and larger
            return .large
        } else if maxDimension >= 820 { // iPad Air/Pro 11" range
            return .medium
        } else if width <= 375 { // iPhone SE, iPhone 12/13 mini
            return .compact
        } else { // Standard iPhone sizes
            return .standard
        }
    }
    
    /// Calculate safe area adjustments for notched devices
    static func calculateSafeAreaAdjustment(for screenSize: CGSize) -> CGFloat {
        let aspectRatio = screenSize.height / screenSize.width
        
        // iPhone X and later have notches/Dynamic Island
        if aspectRatio > 2.0 {
            return 44.0 // Additional top margin for notched devices
        }
        
        return 20.0 // Standard status bar height
    }
    
    /// Get optimal animation duration based on display capabilities
    static func getAnimationDuration(_ baseDuration: TimeInterval, isProMotion: Bool) -> TimeInterval {
        if isProMotion {
            return baseDuration * Performance.proMotionAnimationScale
        }
        return baseDuration
    }
    
    /// Get target frame rate for current display
    static func getTargetFrameRate(isProMotion: Bool) -> Int {
        return isProMotion ? Performance.proMotionTargetFPS : Performance.standardTargetFPS
    }
    
    /// Get max nodes per frame based on display capabilities
    static func getMaxNodesPerFrame(isProMotion: Bool) -> Int {
        return isProMotion ? Performance.maxNodesPerFrameProMotion : Performance.maxNodesPerFrameStandard
    }
    
    /// Check if ProMotion is available and should be used
    @available(iOS 15.0, *)
    @MainActor
    static func detectProMotionCapability() -> (isAvailable: Bool, maxRefreshRate: Int) {
        let maxRefreshRate = UIScreen.main.maximumFramesPerSecond
        let isProMotionAvailable = maxRefreshRate >= Performance.proMotionMinimumRefreshRate
        return (isProMotionAvailable, maxRefreshRate)
    }
}

// MARK: - Device Categories

enum DeviceCategory {
    case compact    // iPhone SE, iPhone 12/13 mini
    case standard   // iPhone 12/13/14/15
    case medium     // iPad Air/Pro 11"
    case large      // iPad Pro 12.9"
    
    var description: String {
        switch self {
        case .compact: return "Compact iPhone"
        case .standard: return "Standard iPhone"
        case .medium: return "iPad"
        case .large: return "iPad Pro Large"
        }
    }
}
