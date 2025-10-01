// FILE: PerformanceFlags.swift
import Foundation
import SpriteKit
import os.signpost

final class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    private let signpostLog = OSLog(subsystem: "com.blockpuzzle.performance", category: "GameEngine")
    private var frameStartTime: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var lastFPSUpdate: CFTimeInterval = 0
    private var currentFPS: Double = 0
    private var frameBuffer: [CFTimeInterval] = []
    private let maxFrameBufferSize = 60

    // Performance flags
    struct Flags {
        static var enableVSync = true
        static var enableNodePooling = true
        static var enableSpatialIndexing = true
        static var enableFrameSkipping = false
        static var enableMemoryOptimizations = true
        static var showPerformanceOverlay = false
        static var profileMemoryAllocations = false
        static var maxNodesPerFrame = 1000
        static var enableAutoCulling = true
    }

    private init() {}

    func startFrame() {
        frameStartTime = CACurrentMediaTime()
        os_signpost(.begin, log: signpostLog, name: "GameFrame")
    }

    func endFrame() {
        let frameTime = CACurrentMediaTime() - frameStartTime
        os_signpost(.end, log: signpostLog, name: "GameFrame")

        recordFrameTime(frameTime)
        updateFPS()

        if frameTime > GameConfig.maxFrameTime {
            os_signpost(.event, log: signpostLog, name: "FrameDrop", "Frame time: %.2fms", frameTime * 1000)
        }
    }

    private func recordFrameTime(_ frameTime: CFTimeInterval) {
        frameBuffer.append(frameTime)
        if frameBuffer.count > maxFrameBufferSize {
            frameBuffer.removeFirst()
        }
    }

    private func updateFPS() {
        frameCount += 1
        let currentTime = CACurrentMediaTime()

        if currentTime - lastFPSUpdate >= 1.0 {
            currentFPS = Double(frameCount) / (currentTime - lastFPSUpdate)
            frameCount = 0
            lastFPSUpdate = currentTime

            if Flags.showPerformanceOverlay {
                print("FPS: \(String(format: "%.1f", currentFPS))")
            }
        }
    }

    var averageFrameTime: CFTimeInterval {
        guard !frameBuffer.isEmpty else { return 0 }
        return frameBuffer.reduce(0, +) / Double(frameBuffer.count)
    }

    var maxFrameTime: CFTimeInterval {
        return frameBuffer.max() ?? 0
    }

    var minFrameTime: CFTimeInterval {
        return frameBuffer.min() ?? 0
    }

    var fps: Double {
        return currentFPS
    }

    func logPerformanceStats() {
        let avgMs = averageFrameTime * 1000
        let maxMs = maxFrameTime * 1000
        let minMs = minFrameTime * 1000

        print("""
        Performance Stats:
        FPS: \(String(format: "%.1f", currentFPS))
        Avg Frame Time: \(String(format: "%.2f", avgMs))ms
        Max Frame Time: \(String(format: "%.2f", maxMs))ms
        Min Frame Time: \(String(format: "%.2f", minMs))ms
        """)
    }
}

final class FPSCounter: SKNode {
    private let label: SKLabelNode
    private var lastUpdateTime: TimeInterval = 0
    private var frameCount = 0

    override init() {
        label = SKLabelNode(text: "FPS: --")
        super.init()

        label.fontName = "Helvetica-Bold"
        label.fontSize = 16
        label.fontColor = .white
        label.position = CGPoint.zero
        addChild(label)

        name = "FPSCounter"
        zPosition = 1000
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ currentTime: TimeInterval) {
        frameCount += 1

        if currentTime - lastUpdateTime >= 1.0 {
            let fps = Double(frameCount) / (currentTime - lastUpdateTime)
            label.text = "FPS: \(Int(fps))"

            frameCount = 0
            lastUpdateTime = currentTime
        }
    }
}

struct MemoryProfiler {
    static func logMemoryUsage(context: String = "") {
        guard PerformanceMonitor.Flags.profileMemoryAllocations else { return }

        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMemoryMB = Float(info.resident_size) / 1024.0 / 1024.0
            print("Memory usage \(context): \(String(format: "%.1f", usedMemoryMB)) MB")
        }
    }

    static func checkMemoryPressure() -> Bool {
        return GameConfig.memoryPressureLevel > 1
    }
}

// MARK: - Debug Helpers
struct DebugFlags {
    static var showGridBounds = false
    static var showHitBoxes = false
    static var showSpatialGrid = false
    static var logDragEvents = false
    static var showFrameTime = false
    static var enableGodMode = false
    static var skipAnimations = false

    static func enableDebugMode() {
        showGridBounds = true
        showHitBoxes = true
        PerformanceMonitor.Flags.showPerformanceOverlay = true
        logDragEvents = true
        showFrameTime = true
    }

    static func disableDebugMode() {
        showGridBounds = false
        showHitBoxes = false
        PerformanceMonitor.Flags.showPerformanceOverlay = false
        logDragEvents = false
        showFrameTime = false
    }
}

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