import SwiftUI

// MARK: - Power-Up Inventory View

struct PowerUpInventory: View {

    @ObservedObject var manager: PowerUpManager

    let onActivate: (PowerUpType) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(PowerUpType.allCases.prefix(3), id: \.self) { powerUp in
                PowerUpInventoryButton(
                    type: powerUp,
                    count: manager.count(for: powerUp),
                    isActive: manager.activePowerUp == powerUp,
                    onTap: {
                        if manager.count(for: powerUp) > 0 {
                            manager.selectPowerUp(powerUp)
                            onActivate(powerUp)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Power-Up Button

private struct PowerUpInventoryButton: View {

    let type: PowerUpType
    let count: Int
    let isActive: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                // Main button
                VStack(spacing: 4) {
                    Image(systemName: type.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(count > 0 ? iconColor : disabledColor)

                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(count > 0 ? .primary : disabledColor)
                }
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(buttonBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isActive ? Color.blue : borderColor, lineWidth: isActive ? 2.5 : 1.5)
                )

                // Active indicator
                if isActive {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .offset(x: 4, y: -4)
                }
            }
        }
        .disabled(count == 0)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }

    private var iconColor: Color {
        switch type {
        case .rotateToken: return .blue
        case .bomb: return .orange
        case .singleBlock: return .green
        case .clearRow, .clearColumn: return .purple
        }
    }

    private var disabledColor: Color {
        Color.secondary.opacity(0.3)
    }

    private var buttonBackground: Color {
        if colorScheme == .dark {
            return Color(UIColor.systemGray5).opacity(0.6)
        } else {
            return Color.white.opacity(0.8)
        }
    }

    private var borderColor: Color {
        count > 0 ? Color.secondary.opacity(0.4) : Color.secondary.opacity(0.2)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var manager = PowerUpManager()

    VStack {
        PowerUpInventory(manager: manager) { powerUp in
            print("Activated: \(powerUp)")
        }
    }
    .padding()
    .background(Color(UIColor.systemBackground))
    .onAppear {
        manager.addPowerUp(.rotateToken, count: 3)
        manager.addPowerUp(.bomb, count: 1)
    }
}
