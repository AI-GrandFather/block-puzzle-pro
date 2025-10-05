// FILE: GameContainerView.swift
import SwiftUI
import SpriteKit

struct GameContainerView: View {
    var body: some View {
        GameViewControllerRepresentable()
            .ignoresSafeArea()
            .navigationBarHidden(true)
    }
}

// GameViewControllerRepresentable is defined in BlockPuzzleProApp.swift

#Preview {
    GameContainerView()
}