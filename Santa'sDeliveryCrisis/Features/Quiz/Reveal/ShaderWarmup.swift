import SwiftUI

/// 연출에 쓰는 셰이더를 미리 한 번씩 그려서 GPU가 컴파일을 끝내 두게 한다.
///
/// 셰이더는 처음 쓰이는 프레임에 컴파일되어 그 프레임이 한 번 멈출 수 있다.
/// 장식 연출은 번쩍이는 순간에 충격파와 후광이 처음 나타나므로, 앱이 켜진 직후에 보이지 않을 만큼 작게 그려 두면
/// 화면 모습은 그대로이고 첫 연출의 멈춤만 사라진다.
/// 약 1초 뒤에 스스로 치워지고, 점 하나 크기라 눈에 보이지 않는다.
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
