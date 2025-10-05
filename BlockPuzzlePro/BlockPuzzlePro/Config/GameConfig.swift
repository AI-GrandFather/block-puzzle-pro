// FILE: GameConfig.swift
import Foundation
import UIKit

struct GameConfig {
    static let gridSize = 10
    static let trayBlockCount = 3
    static let maxFrameTime: TimeInterval = 8.3 / 1000.0 // 120fps budget
    static let fallbackFrameTime: TimeInterval = 16.7 / 1000.0 // 60fps budget

    // Touch and interaction
    static let vicinityRadius: CGFloat = 32.0
    static let touchTolerance: CGFloat = 4.0
    static let dragThreshold: CGFloat = 8.0

    // Animation timings
    static let blockScaleOnSelect: CGFloat = 1.1
    static let springAnimationDuration: TimeInterval = 0.3
    static let elasticAnimationDuration: TimeInterval = 0.45
    static let fadeAnimationDuration: TimeInterval = 0.25

    // Performance
    static let maxTextureSize: CGFloat = 2048
    static let nodePoolInitialSize = 50
    static let maxDrawCallsPerFrame = 10
    static let memoryWarningThreshold = 100_000_000 // 100MB

    // ProMotion settings
    static let preferredFrameRate = 120
    static let minimumFrameRate = 80
    static let fallbackFrameRate = 60

    // Grid rendering
    static let gridLineWidth: CGFloat = 1.0
    static let cellBorderWidth: CGFloat = 0.5
    static let previewAlpha: CGFloat = 0.2
    static let invalidPreviewAlpha: CGFloat = 0.12

    // Difficulty progression
    enum Difficulty: Int, CaseIterable {
        case easy = 0
        case medium = 1
        case hard = 2
        case expert = 3

        var blockComplexityWeight: Float {
            switch self {
            case .easy: return 0.3
            case .medium: return 0.5
            case .hard: return 0.7
            case .expert: return 1.0
            }
        }

        var minBlockSize: Int {
            switch self {
            case .easy: return 1
            case .medium: return 1
            case .hard: return 2
            case .expert: return 2
            }
        }

        var maxBlockSize: Int {
            switch self {
            case .easy: return 3
            case .medium: return 4
            case .hard: return 5
            case .expert: return 6
            }
        }
    }

    static var currentDifficulty: Difficulty {
        get {
            let rawValue = UserDefaults.standard.integer(forKey: "gameDifficulty")
            return Difficulty(rawValue: rawValue) ?? .medium
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "gameDifficulty")
        }
    }

    // Device capability detection
    static var isProMotionDevice: Bool {
        return UIScreen.main.maximumFramesPerSecond >= 120
    }

    static var preferredMaxFrameRate: Int {
        return isProMotionDevice ? preferredFrameRate : fallbackFrameRate
    }

    static var memoryPressureLevel: Int {
        // Simplified memory pressure detection
        var memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMemory = Int(memoryInfo.resident_size)
            if usedMemory > memoryWarningThreshold {
                return 2 // High pressure
            } else if usedMemory > memoryWarningThreshold / 2 {
                return 1 // Medium pressure
            }
        }

        return 0 // Low pressure
    }
}

// C interop for memory info
private struct mach_task_basic_info {
    var virtual_size: mach_vm_size_t = 0
    var resident_size: mach_vm_size_t = 0
    var resident_size_max: mach_vm_size_t = 0
    var user_time: time_value_t = time_value_t()
    var system_time: time_value_t = time_value_t()
    var policy: policy_t = 0
    var suspend_count: integer_t = 0
}

private struct time_value_t {
    var seconds: integer_t = 0
    var microseconds: integer_t = 0
}
