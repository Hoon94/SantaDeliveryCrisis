import SwiftUI

/// 보상 작업의 장식 색 구성. 무지개 스타일은 연출 프리뷰용이다.
enum OrnamentStyle: Equatable {
    case task(WorkshopTask)
    case mixed

    /// 문제 카테고리와 무관하게 세션에 저장된 작업으로 장식 스타일을 정한다.
    init(task: WorkshopTask) {
        self = .task(task)
    }

    /// 장식을 대표하는 색. 버튼과 빛에 쓴다.
    var tint: Color {
        switch self {
        case .task(let task): task.themeColor
        case .mixed: .glowGold
        }
    }

    /// 장식 이름
    var title: String {
        switch self {
        case .task(let task): "\(task.displayName) 장식"
        case .mixed: "여러 작업 섞음 장식"
        }
    }

    fileprivate var bodyFill: AnyShapeStyle {
        switch self {
        case .task(let task):
            AnyShapeStyle(task.themeColor)
        case .mixed:
            AnyShapeStyle(AngularGradient(
                colors: [.categoryAiUsage, .categorySwiftSyntax, .categoryHig, .categorySwiftUIPractice, .categoryAiUsage],
                center: .center,
                angle: .degrees(-40)
            ))
        }
    }
}

/// 트리 장식 하나. `radiance`가 0이면 빛 없는 평범한 회색 장식, 1이면 색과 광택이 살아난 장식이다.
/// 모든 값은 호출하는 쪽이 시간의 함수로 넘기므로 이 뷰 자체는 상태가 없다.
// FIXME: [자산 교체] 도형으로 그린 장식을 실제 장식 이미지로 교체. `radiance`는 이미지 두 장의 교차 페이드로 대신할 수 있다.
struct OrnamentView: View {
    let style: OrnamentStyle
    /// 0(평범함)...1(빛남)
    var radiance: Double = 1
    /// 달아오른 정도 0...1. 충전 중에 중심부터 하얗게 달아오른다.
    var heat: Double = 0
    /// 광택이 지나가는 위치 0...1. 범위 밖이면 광택 없음
    var glint: Double = -1
    /// 장식 지름(포인트)
    var size: CGFloat = 150

    var body: some View {
        let d = size
        ZStack {
            hook(d)
            cap(d)
            bodyLayers(d)
        }
        .frame(width: d, height: d * 1.14, alignment: .bottom)
        .shadow(color: Color.inkShadow.opacity(0.22), radius: d * 0.05, y: d * 0.035)
        .accessibilityHidden(true)
    }

    // MARK: - 부품

    /// 매다는 고리
    private func hook(_ d: CGFloat) -> some View {
        Circle()
            .strokeBorder(
                LinearGradient(colors: [.decorationCap, .glowGold.opacity(0.7)], startPoint: .top, endPoint: .bottom),
                lineWidth: d * 0.028
            )
            .frame(width: d * 0.13, height: d * 0.13)
            .offset(y: -d * 0.545)
    }

    /// 윗부분 금속 뚜껑
    private func cap(_ d: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: d * 0.035, style: .continuous)
            .fill(LinearGradient(colors: [.glowGold, .decorationCap, .glowEmber.opacity(0.9)], startPoint: .leading, endPoint: .trailing))
            .overlay(alignment: .top) {
                Capsule().fill(Color.glowWhite.opacity(0.55)).frame(height: d * 0.012).padding(.horizontal, d * 0.02).padding(.top, d * 0.014)
            }
            .frame(width: d * 0.2, height: d * 0.12)
            .offset(y: -d * 0.46)
    }

    private func bodyLayers(_ d: CGFloat) -> some View {
        ZStack {
            plainBody(d).opacity(1 - radiance)
            radiantBody(d).opacity(radiance)
            heatOverlay(d)
        }
        .frame(width: d * 0.92, height: d * 0.92)
        .offset(y: d * 0.04)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(rimGradient, lineWidth: d * 0.012).opacity(0.5 + 0.5 * radiance))
    }

    private var rimGradient: LinearGradient {
        LinearGradient(colors: [.glowWhite.opacity(0.9), .clear, .inkShadow.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// 빛이 없는 평범한 장식: 무광 회색
    private func plainBody(_ d: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.plainOrnamentShade)
            Circle().fill(RadialGradient(
                colors: [.glowWhite.opacity(0.55), .plainOrnament, .plainOrnamentShade],
                center: UnitPoint(x: 0.35, y: 0.3),
                startRadius: 0,
                endRadius: d * 0.7
            ))
            Ellipse()
                .fill(Color.glowWhite.opacity(0.35))
                .frame(width: d * 0.26, height: d * 0.13)
                .rotationEffect(.degrees(-30))
                .offset(x: -d * 0.2, y: -d * 0.24)
                .blur(radius: d * 0.012)
        }
    }

    /// 빛나는 장식: 색, 광택, 띠 무늬, 반사광
    private func radiantBody(_ d: CGFloat) -> some View {
        ZStack {
            Circle().fill(style.bodyFill)
            // 입체감: 왼쪽 위는 밝게, 오른쪽 아래는 어둡게
            Circle().fill(RadialGradient(
                colors: [.glowWhite.opacity(0.55), .clear],
                center: UnitPoint(x: 0.32, y: 0.26),
                startRadius: 0,
                endRadius: d * 0.5
            ))
            Circle().fill(RadialGradient(
                colors: [.clear, .inkShadow.opacity(0.5)],
                center: UnitPoint(x: 0.36, y: 0.3),
                startRadius: d * 0.3,
                endRadius: d * 0.72
            ))
            // 바닥에서 올라오는 반사광
            Ellipse()
                .fill(RadialGradient(colors: [.glowGold.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: d * 0.3))
                .frame(width: d * 0.6, height: d * 0.3)
                .offset(y: d * 0.36)
            band(d)
            Ellipse()
                .fill(Color.glowWhite.opacity(0.85))
                .frame(width: d * 0.26, height: d * 0.12)
                .rotationEffect(.degrees(-32))
                .offset(x: -d * 0.22, y: -d * 0.26)
                .blur(radius: d * 0.008)
            Circle()
                .fill(Color.glowWhite)
                .frame(width: d * 0.05, height: d * 0.05)
                .offset(x: -d * 0.31, y: -d * 0.12)
            if (0...1).contains(glint) {
                glintSweep(d)
            }
        }
    }

    /// 장식 가운데를 비스듬히 두르는 띠와 점 무늬
    private func band(_ d: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.glowWhite.opacity(0.2))
                .frame(height: d * 0.17)
            Rectangle().fill(Color.glowWhite.opacity(0.55)).frame(height: d * 0.008).offset(y: -d * 0.085)
            Rectangle().fill(Color.glowWhite.opacity(0.55)).frame(height: d * 0.008).offset(y: d * 0.085)
            HStack(spacing: d * 0.07) {
                ForEach(0..<7, id: \.self) { _ in
                    Circle().fill(Color.glowWhite.opacity(0.7)).frame(width: d * 0.028, height: d * 0.028)
                }
            }
        }
        .rotationEffect(.degrees(-14))
        .offset(y: d * 0.05)
    }

    /// 비스듬한 빛줄기가 장식 위를 훑고 지나간다.
    private func glintSweep(_ d: CGFloat) -> some View {
        Rectangle()
            .fill(LinearGradient(colors: [.clear, .glowWhite.opacity(0.85), .clear], startPoint: .leading, endPoint: .trailing))
            .frame(width: d * 0.24, height: d * 1.4)
            .rotationEffect(.degrees(24))
            .offset(x: (glint * 1.7 - 0.85) * d)
            .blendMode(.plusLighter)
    }

    /// 충전 중 달아오른 중심
    private func heatOverlay(_ d: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(colors: [.glowCore, .glowGold.opacity(0.7), .clear], center: .center, startRadius: 0, endRadius: d * 0.52))
            .opacity(heat)
            .blendMode(.plusLighter)
    }
}

#Preview("평범함에서 빛남까지") {
    HStack(spacing: 20) {
        OrnamentView(style: .task(.wishReception), radiance: 0, size: 100)
        OrnamentView(style: .task(.wishReception), radiance: 0, heat: 0.7, size: 100)
        OrnamentView(style: .task(.wishReception), radiance: 1, glint: 0.5, size: 100)
        OrnamentView(style: .mixed, radiance: 1, size: 100)
    }
    .padding(30)
    .background(Color.revealScrim)
}

#Preview("네 작업 장식") {
    HStack(spacing: 14) {
        ForEach(WorkshopTask.allCases, id: \.self) { task in
            OrnamentView(style: .task(task), radiance: 1, size: 80)
        }
    }
    .padding(30)
    .background(Color.revealScrim)
}
