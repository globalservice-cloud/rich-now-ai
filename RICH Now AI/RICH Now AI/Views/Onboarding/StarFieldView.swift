//
//  StarFieldView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct StarFieldView: View {
    @State private var stars: [Star] = []
    @State private var animationOffset: CGFloat = 0
    @State private var viewSize: CGSize = .zero
    @State private var hasStartedTwinkling = false
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                ForEach(stars, id: \.id) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .position(
                            x: star.x + animationOffset,
                            y: star.y
                        )
                        .opacity(star.opacity)
                        .animation(
                            .easeInOut(duration: star.twinkleDuration)
                            .repeatForever(autoreverses: true),
                            value: star.opacity
                        )
                }
            }
            .onAppear {
                viewSize = size
                generateStars(in: size)
                startTwinkling()
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                guard newSize != oldSize else { return }
                viewSize = newSize
                generateStars(in: newSize)
            }
        }
    }
    private func generateStars(in size: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }
        let widthRange = 0...size.width
        let heightRange = 0...size.height
        
        stars = (0..<100).map { _ in
            Star(
                id: UUID(),
                x: CGFloat.random(in: widthRange),
                y: CGFloat.random(in: heightRange),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.3...1.0),
                twinkleDuration: Double.random(in: 1.0...3.0)
            )
        }
    }
    
    private func startTwinkling() {
        guard !hasStartedTwinkling else { return }
        hasStartedTwinkling = true
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for i in stars.indices {
                if Bool.random() {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        stars[i].opacity = Double.random(in: 0.3...1.0)
                    }
                }
            }
        }
    }
}

struct Star: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var twinkleDuration: Double
}

#Preview {
    StarFieldView()
        .background(Color.black)
}
