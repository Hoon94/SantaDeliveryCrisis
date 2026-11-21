import SwiftUI

/// 연출에 쓰는 셰이더를 미리 한 번씩 그려 첫 사용 시 준비 비용을 줄이려는 뷰.
///
/// 셰이더는 처음 쓰이는 프레임에 컴파일되어 그 프레임이 한 번 멈출 수 있다.
/// 장식 연출은 번쩍이는 순간에 충격파와 후광이 처음 나타나므로, 앱이 켜진 직후에 보이지 않을 만큼 작게 그려 두면
/// 첫 연출의 멈춤을 줄이는 효과를 기대한다. 실제 개선 여부는 기기에서 확인해야 한다.
/// 약 1초 뒤에 스스로 치워지며, 4×4pt와 낮은 불투명도로 표시한다.
struct ShaderWarmup: View {
    @State private var isDone = false

    var body: some View {
        if !isDone {
            ZStack {
                Rectangle().fill(Color.glowWhite)
                    .colorEffect(ShaderLibrary.godRays(
                        .float2(CGPoint(x: 1, y: 1)), .float(0), .float(0.5), .float(2), .color(.glowGold)
                    ))
                Rectangle().fill(Color.glowWhite)
                    .colorEffect(ShaderLibrary.chargeOrb(
                        .float2(CGPoint(x: 1, y: 1)), .float(2), .float(0.5), .float(0.5), .color(.glowGold), .color(.glowCore)
                    ))
                Rectangle().fill(Color.glowWhite)
                    .colorEffect(ShaderLibrary.absorbFlare(
                        .float2(CGPoint(x: 1, y: 1)), .float(0.2), .float(2), .color(.glowGold), .color(.glowCore)
                    ))
                Rectangle().fill(Color.glowWhite)
                    .layerEffect(
                        ShaderLibrary.shockwave(
                            .float2(CGPoint(x: 1, y: 1)), .float(2), .float(2), .float(1), .float(1)
                        ),
                        maxSampleOffset: CGSize(width: 4, height: 4)
                    )
            }
            .frame(width: 4, height: 4)
            .opacity(0.02)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task {
                try? await Task.sleep(for: .seconds(1))
                isDone = true
            }
        }
    }
}
