// FILE: Extensions.swift
import Foundation
import SpriteKit
import UIKit

extension CGFloat {
    func interpolate(to target: CGFloat, factor: CGFloat) -> CGFloat {
        return self + (target - self) * factor
    }

    static func lerp(from: CGFloat, to: CGFloat, progress: CGFloat) -> CGFloat {
        return from + (to - from) * progress
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }

    func interpolate(to target: CGPoint, factor: CGFloat) -> CGPoint {
        return CGPoint(
            x: x.interpolate(to: target.x, factor: factor),
            y: y.interpolate(to: target.y, factor: factor)
        )
    }

    static func +(lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func -(lhs: CGPoint, rhs: CGPoint) -> CGVector {
        return CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }
}

extension CGVector {
    var magnitude: CGFloat {
        return sqrt(dx * dx + dy * dy)
    }

    func normalized() -> CGVector {
        let mag = magnitude
        guard mag > 0 else { return CGVector.zero }
        return CGVector(dx: dx / mag, dy: dy / mag)
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    func toSKColor() -> SKColor {
        return self
    }
}

extension SKAction {
    static func spring(to destination: CGPoint, duration: TimeInterval, damping: CGFloat = 0.8) -> SKAction {
        return SKAction.customAction(withDuration: duration) { node, elapsed in
            MainActor.assumeIsolated {
                let progress = elapsed / duration
                let springProgress = 1 - pow(damping, progress * 10) * cos(progress * .pi * 6)
                let currentPos = node.position
                let startPos = node.value(forKey: "springStartPos") as? CGPoint ?? currentPos

                if elapsed == 0 {
                    node.setValue(currentPos, forKey: "springStartPos")
                }

                node.position = startPos.interpolate(to: destination, factor: springProgress)
            }
        }
    }

    static func elasticScale(to scale: CGFloat, duration: TimeInterval) -> SKAction {
        return SKAction.customAction(withDuration: duration) { node, elapsed in
            MainActor.assumeIsolated {
                let progress = elapsed / duration
                let elasticProgress = pow(2, -10 * progress) * sin((progress - 0.1) * (2 * .pi) / 0.4) + 1
                let startScale = node.value(forKey: "elasticStartScale") as? CGFloat ?? node.xScale

                if elapsed == 0 {
                    node.setValue(node.xScale, forKey: "elasticStartScale")
                }

                let currentScale = CGFloat.lerp(from: startScale, to: scale, progress: elasticProgress)
                node.setScale(currentScale)
            }
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }

    mutating func removeFirstWhere(_ predicate: (Element) throws -> Bool) rethrows -> Element? {
        if let index = try firstIndex(where: predicate) {
            return remove(at: index)
        }
        return nil
    }
}
