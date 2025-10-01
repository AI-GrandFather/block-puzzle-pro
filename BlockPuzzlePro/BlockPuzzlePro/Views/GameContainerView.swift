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

struct GameViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GameViewController {
        let gameViewController = GameViewController()
        return gameViewController
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    GameContainerView()
}