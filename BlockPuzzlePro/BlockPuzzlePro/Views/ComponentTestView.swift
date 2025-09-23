import SwiftUI

// MARK: - Component Test View

/// Test view to validate all components work together
struct ComponentTestView: View {
    
    @StateObject private var gameEngine = GameEngine()
    @StateObject private var blockFactory = BlockFactory()
    @StateObject private var dragController = DragController()
    @StateObject private var deviceManager = DeviceManager()
    
    @State private var testResults: [String: Bool] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Component Integration Test")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Test Results
                ForEach(Array(testResults.keys.sorted()), id: \.self) { key in
                    HStack {
                        Image(systemName: testResults[key] == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(testResults[key] == true ? .green : .red)
                        Text(key)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                Button("Run All Tests") {
                    runAllTests()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .onAppear {
            runAllTests()
        }
    }
    
    private func runAllTests() {
        testResults.removeAll()
        
        // Test 1: GameEngine initialization
        testResults["GameEngine Initialization"] = gameEngine.score == 0
        
        // Test 2: BlockFactory creation
        blockFactory.resetTray()
        let traySlots = blockFactory.getTraySlots()
        testResults["BlockFactory Creates Blocks"] = traySlots.count == 3 && traySlots.allSatisfy { $0 != nil }
        
        // Test 3: Grid operations
        let testPosition = GridPosition(unsafeRow: 0, unsafeColumn: 0)
        let canPlace = gameEngine.canPlaceAt(position: testPosition)
        testResults["Grid Can Place Blocks"] = canPlace
        
        // Test 4: Block patterns
        testResults["Unique Tray Types"] = Set(blockFactory.availableBlocks.map { $0.type }).count == blockFactory.availableBlocks.count
        
        // Test 5: DeviceManager configuration
        testResults["DeviceManager Configuration"] = deviceManager.preferredCellSize > 0
        
        // Test 6: DragController initialization
        testResults["DragController Ready"] = !dragController.isDragging
        
        // Test 7: Color system
        let redColor = BlockColor.red
        testResults["Color System"] = redColor.uiColor != nil
        
        // Test 8: Grid position validation
        let validPos = GridPosition(row: 5, column: 5)
        let invalidPos = GridPosition(row: -1, column: -1)
        testResults["Grid Position Validation"] = validPos != nil && invalidPos == nil
        
        print("✅ All tests completed!")
        
        // Print detailed results
        for (test, result) in testResults {
            print("\(result ? "✅" : "❌") \(test)")
        }
    }
}

#Preview {
    ComponentTestView()
}
