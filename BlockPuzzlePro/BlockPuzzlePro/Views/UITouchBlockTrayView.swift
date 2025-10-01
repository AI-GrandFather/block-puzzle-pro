import SwiftUI
import UIKit

// MARK: - UIKit Touch-Enabled Block Tray

/// UIKit-based touch detection for precise vicinity selection
/// This provides professional game-quality touch handling with generous hit areas
struct UITouchBlockTrayView: UIViewRepresentable {

    // MARK: - Properties

    @ObservedObject var blockFactory: BlockFactory
    @ObservedObject var dragController: DragController

    let cellSize: CGFloat
    let slotSize: CGFloat
    let horizontalInset: CGFloat
    let slotSpacing: CGFloat
    let vicinityRadius: CGFloat
    let onBlockDragged: (Int, BlockPattern) -> Void

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> TouchBlockTrayUIView {
        let view = TouchBlockTrayUIView()
        view.coordinator = context.coordinator
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = false // Only one block at a time
        return view
    }

    func updateUIView(_ uiView: TouchBlockTrayUIView, context: Context) {
        // Update block positions and frames
        context.coordinator.updateBlockData(
            blocks: blockFactory.getTraySlots(),
            slotSize: slotSize,
            slotSpacing: slotSpacing,
            horizontalInset: horizontalInset,
            vicinityRadius: vicinityRadius
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            dragController: dragController,
            onBlockDragged: onBlockDragged
        )
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        let dragController: DragController
        let onBlockDragged: (Int, BlockPattern) -> Void

        // Block layout data
        private var blockFrames: [Int: CGRect] = [:]
        private var blockPatterns: [Int: BlockPattern] = [:]
        private var vicinityRadius: CGFloat = 80.0

        // Touch tracking
        private var activeTouch: UITouch?
        private var activeDragBlockIndex: Int?

        init(dragController: DragController, onBlockDragged: @escaping (Int, BlockPattern) -> Void) {
            self.dragController = dragController
            self.onBlockDragged = onBlockDragged
        }

        func updateBlockData(
            blocks: [BlockPattern?],
            slotSize: CGFloat,
            slotSpacing: CGFloat,
            horizontalInset: CGFloat,
            vicinityRadius: CGFloat
        ) {
            self.vicinityRadius = vicinityRadius
            blockFrames.removeAll()
            blockPatterns.removeAll()

            // Calculate frame for each block slot
            let totalSpacing = slotSpacing * CGFloat(blocks.count - 1)
            let totalSlotWidth = slotSize * CGFloat(blocks.count)
            let startX = horizontalInset

            for (index, blockPattern) in blocks.enumerated() {
                guard let pattern = blockPattern else { continue }

                let x = startX + CGFloat(index) * (slotSize + slotSpacing)
                let y: CGFloat = 14 // Vertical padding

                blockFrames[index] = CGRect(
                    x: x,
                    y: y,
                    width: slotSize,
                    height: slotSize
                )
                blockPatterns[index] = pattern
            }
        }

        // MARK: - Touch Detection

        func handleTouchBegan(_ touch: UITouch, in view: UIView) {
            let location = touch.location(in: view)

            // Find which block (if any) was touched - using vicinity detection
            if let blockIndex = findBlockNearTouch(at: location) {
                guard let blockPattern = blockPatterns[blockIndex],
                      let blockFrame = blockFrames[blockIndex],
                      dragController.dragState == .idle else {
                    return
                }

                activeTouch = touch
                activeDragBlockIndex = blockIndex

                // Calculate touch offset from block's top-left corner
                let touchOffset = CGSize(
                    width: location.x - blockFrame.minX,
                    height: location.y - blockFrame.minY
                )

                // Convert to global coordinates for DragController
                let globalLocation = view.convert(location, to: nil)

                // Notify that drag started
                onBlockDragged(blockIndex, blockPattern)

                // Start drag in controller
                dragController.startDrag(
                    blockIndex: blockIndex,
                    blockPattern: blockPattern,
                    at: globalLocation,
                    touchOffset: touchOffset
                )

                DebugLog.trace("✅ UITouch: Started drag for block \(blockIndex) at \(location)")
            } else {
                DebugLog.trace("❌ UITouch: No block found near \(location)")
            }
        }

        func handleTouchMoved(_ touch: UITouch, in view: UIView) {
            guard touch == activeTouch,
                  let blockIndex = activeDragBlockIndex,
                  dragController.isBlockDragged(blockIndex) else {
                return
            }

            let location = touch.location(in: view)
            let globalLocation = view.convert(location, to: nil)

            dragController.updateDrag(to: globalLocation)
        }

        func handleTouchEnded(_ touch: UITouch, in view: UIView) {
            guard touch == activeTouch else { return }

            let location = touch.location(in: view)
            let globalLocation = view.convert(location, to: nil)

            if let blockIndex = activeDragBlockIndex,
               dragController.isBlockDragged(blockIndex) {
                dragController.endDrag(at: globalLocation)
                DebugLog.trace("🏁 UITouch: Ended drag for block \(blockIndex)")
            }

            activeTouch = nil
            activeDragBlockIndex = nil
        }

        func handleTouchCancelled(_ touch: UITouch, in view: UIView) {
            handleTouchEnded(touch, in: view)
        }

        // MARK: - Hit Testing

        private func findBlockNearTouch(at point: CGPoint) -> Int? {
            // Check each block with vicinity radius
            for (index, frame) in blockFrames {
                let blockCenter = CGPoint(x: frame.midX, y: frame.midY)
                let distance = hypot(point.x - blockCenter.x, point.y - blockCenter.y)

                // Accept touch if within vicinity radius
                if distance <= vicinityRadius {
                    DebugLog.trace("📍 UITouch: Block \(index) found at distance \(distance)pt (max: \(vicinityRadius)pt)")
                    return index
                }
            }

            return nil
        }
    }
}

// MARK: - UIView Subclass

/// Custom UIView that forwards touches to coordinator
class TouchBlockTrayUIView: UIView {
    weak var coordinator: UITouchBlockTrayView.Coordinator?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        DebugLog.trace("🎯 TouchBlockTrayUIView.touchesBegan called - touches:\(touches.count) bounds:\(bounds)")
        guard let touch = touches.first else {
            DebugLog.trace("❌ TouchBlockTrayUIView.touchesBegan - no touch found")
            return
        }
        let location = touch.location(in: self)
        DebugLog.trace("🎯 TouchBlockTrayUIView.touchesBegan - location:\(location)")
        coordinator?.handleTouchBegan(touch, in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        coordinator?.handleTouchMoved(touch, in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        coordinator?.handleTouchEnded(touch, in: self)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard let touch = touches.first else { return }
        coordinator?.handleTouchCancelled(touch, in: self)
    }
}
