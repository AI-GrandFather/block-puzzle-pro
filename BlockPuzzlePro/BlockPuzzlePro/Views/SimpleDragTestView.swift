import SwiftUI

// MARK: - Simple Drag Test View
// This is a minimal test to verify drag gestures work in iOS Simulator

struct SimpleDragTestView: View {
    @State private var position = CGSize.zero
    @State private var isDragging = false
    
    var body: some View {
        VStack {
            Text("🔥 DRAG TEST ZONE")
                .font(.title)
                .padding()
            
            Text("Drag the box below")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Rectangle()
                .fill(isDragging ? Color.red : Color.blue)
                .frame(width: 100, height: 100)
                .offset(position)
                .scaleEffect(isDragging ? 1.2 : 1.0)
                .overlay(
                    Text(isDragging ? "DRAGGING!" : "DRAG ME")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            position = value.translation
                            DebugLog.trace("📦 Simple drag: \(value.translation)")
                        }
                        .onEnded { value in
                            isDragging = false
                            DebugLog.trace("📦 Simple drag ended: \(value.translation)")
                            // Reset position with animation
                            withAnimation(.spring()) {
                                position = .zero
                            }
                        }
                )
                .animation(.easeInOut(duration: 0.2), value: isDragging)
            
            Spacer()
            
            Text("Position: \(position.width, specifier: "%.1f"), \(position.height, specifier: "%.1f")")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(isDragging ? "Status: 🟢 DRAGGING" : "Status: 🔵 IDLE")
                .font(.caption)
                .fontWeight(.bold)
        }
        .padding()
    }
}

#Preview {
    SimpleDragTestView()
}
