import Foundation
import SwiftUI

/// 장식 선택 화면의 눈과 조명을 가벼운 한 장의 캔버스로 그린다.
struct DecorationAmbientEffects: View {
    /// 화면이 공유하는 애니메이션 시각.
    let time: TimeInterval

    /// false이면 눈과 조명 모두 정적인 상태로 그린다.
    let isAnimated: Bool

    /// 입력 시각만으로 눈 14개와 트리 안의 조명을 표시한다.
    var body: some View {
        Canvas { context, size in
            for index in 0..<14 {
                let duration = Double(6 + index % 4)
                let phase = isAnimated
                    ? ((time + Double(index) * 0.55) / duration).truncatingRemainder(dividingBy: 1)
                    : Double(index + 1) / 15
                let radius = 1.6 + Double(index % 3) * 0.7
                let opacity = isAnimated
                    ? (phase < 0.15 ? 0.9 * phase / 0.15 : 0.9 * (1 - phase) / 0.85)
                    : 0.6
                let x = Double((index * 47 + 20) % 350) / 350 * size.width
                let y = (-10 + phase * 570) / 540 * size.height
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: x - radius, y: y - radius, width: radius * 2, height: radius * 2
                    )),
                    with: .color(Color.treeHighlight.opacity(opacity))
                )
            }

            let scale = min(size.width / 220, size.height / 214)
            let origin = CGPoint(x: (size.width - 220 * scale) / 2, y: (size.height - 214 * scale) / 2)
            let colors: [Color] = [.ornament3, .treeStar, .ornament4]
            let shifts = [1.4, 0.0, 0.7]
            var lightIndex = 0
            for row in 0..<6 {
                let y = Double(72 + row * 20)
                let top = y <= 98 ? (y - 34) * 34 / 64 : 0
                let middle = y >= 62 && y <= 140 ? (y - 62) * 50 / 78 : 0
                let bottom = y >= 96 ? (y - 96) * 64 / 88 : 0
                let halfWidth = max(top, max(middle, bottom)) * 0.8
                let count = row + 2
                for column in 0..<count {
                    let variant = lightIndex % 3
                    let opacity = isAnimated
                        ? 0.625 + 0.375 * cos(2 * .pi * (time + shifts[variant]) / 2.2)
                        : 1
                    let x = 110 - halfWidth + Double(column) * 2 * halfWidth / Double(count - 1)
                    let radius = 2.2 * scale
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: origin.x + x * scale - radius,
                            y: origin.y + y * scale - radius,
                            width: radius * 2, height: radius * 2
                        )),
                        with: .color(colors[variant].opacity(opacity))
                    )
                    lightIndex += 1
                }
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// 시안의 장식 흔들림 주기와 위상 차이를 계산한다.
enum DecorationAmbientMotion {
    /// 3.2초마다 원위치와 위쪽 4pt 사이를 왕복한다. 두 번째와 네 번째는 1.4초 앞선다.
    static func bobOffset(time: TimeInterval, category: QuizCategory) -> CGFloat {
        let shift: Double
        switch category {
        case .aiUsage, .hig: shift = 0
        case .swiftSyntax, .swiftUIPractice: shift = 1.4
        }
        return -2 * (1 - cos(2 * .pi * (time + shift) / 3.2))
    }
}
