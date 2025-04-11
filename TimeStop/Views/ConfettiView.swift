import SwiftUI

struct ConfettiView: View {
    @State private var particles: [(id: Int, position: CGPoint, color: Color)] = []
    @State private var timer: Timer?
    let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: 8, height: 8)
                        .position(particle.position)
                }
            }
            .onAppear {
                startConfetti(in: geometry.size)
            }
            .onDisappear {
                stopConfetti()
            }
        }
    }
    
    private func startConfetti(in size: CGSize) {
        // 初始化粒子
        particles = (0..<50).map { id in
            let x = CGFloat.random(in: 0...size.width)
            let y = -20.0 // 从屏幕顶部开始
            let color = colors.randomElement() ?? .red
            return (id: id, position: CGPoint(x: x, y: y), color: color)
        }
        
        // 设置动画定时器
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                updateParticles(in: size)
            }
        }
    }
    
    private func updateParticles(in size: CGSize) {
        particles = particles.map { particle in
            var newParticle = particle
            
            // 更新粒子位置
            let newY = particle.position.y + CGFloat.random(in: 2...5)
            let newX = particle.position.x + CGFloat.random(in: -2...2)
            
            // 如果粒子超出屏幕底部，重置到顶部
            if newY > size.height {
                newParticle.position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                )
            } else {
                newParticle.position = CGPoint(x: newX, y: newY)
            }
            
            return newParticle
        }
    }
    
    private func stopConfetti() {
        timer?.invalidate()
        timer = nil
        particles = []
    }
}

#Preview {
    ConfettiView()
} 