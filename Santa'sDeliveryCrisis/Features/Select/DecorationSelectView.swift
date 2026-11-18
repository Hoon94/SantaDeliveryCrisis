import SwiftUI

/// 트리 이미지 위에 네 카테고리 장식과 적용된 출제 조건을 표시하는 화면.
struct DecorationSelectView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    /// 마지막으로 적용한 출제 설정.
    let filter: SelectFilter

    /// 카테고리별로 계산한 장식 활성 상태와 후보 부족 정보.
    let availability: [DecorationAvailability]

    /// 설정 팝업을 다시 여는 동작.
    let onEdit: () -> Void

    /// 활성 장식의 카테고리로 세션 시작을 요청하는 동작.
    let onSelect: (QuizCategory) -> Void

    /// 프리뷰에서 정적 연출을 강제한다. 시스템의 모션 줄이기는 항상 우선한다.
    var forceReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || forceReduceMotion }

    /// 조건 칩과 안내, 화면 너비에 맞춰 늘어나는 트리 및 장식을 배치한다.
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            content(time: reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate)
        }
    }

    private func content(time: TimeInterval) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                header

                Text("장식을 눌러 퀴즈를 시작하세요")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.nightSecondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if dynamicTypeSize.isAccessibilitySize {
                    accessibleDecorations(time: time)
                } else {
                    DecorationSelectTree(
                        availability: availability, onSelect: onSelect,
                        time: time, reduceMotion: reduceMotion
                    )
                }
                // FIXME: [가정 8] 초기화·n/4 알약·범례·문 열림·통과 점·체크 배지는 표시하지 않음
            }
            .padding(14)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .scrollClipDisabled()
    }

    private var header: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            Text("출제")
                .font(.title2.weight(.heavy))
                .foregroundStyle(Color.nightPrimaryText)
                .accessibilityAddTraits(.isHeader)
            conditionChip
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func accessibleDecorations(time: TimeInterval) -> some View {
        VStack(spacing: 32) {
            ForEach(availability, id: \.category) { result in
                SelectableDecoration(availability: result) {
                    onSelect(result.category)
                }
                .offset(y: reduceMotion ? 0 : DecorationAmbientMotion.bobOffset(
                    time: time, category: result.category
                ))
                .containerRelativeFrame(.horizontal) { width, _ in width * 0.6 }
                .frame(maxWidth: .infinity)
            }
        }
        .background {
            ChristmasTreeImage(imageScale: 2.5)
                .overlay {
                    DecorationAmbientEffects(time: time, isAnimated: reduceMotion == false)
                }
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        }
    }

    private var conditionChip: some View {
        Button(action: onEdit) {
            Label(
                "\(filter.difficulty.displayName) · 카테고리 \(filter.categories.count)개 · \(filter.count)문제",
                systemImage: "gearshape"
            )
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.nightPrimaryText)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Color.nightCardBackground, in: Capsule())
            .overlay { Capsule().strokeBorder(Color.nightBorder, lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("출제 설정, \(filter.difficulty.displayName), 카테고리 \(filter.categories.count)개, \(filter.count)문제")
        .accessibilityHint("출제 설정 팝업을 다시 엽니다")
    }
}

private struct DecorationSelectTree: View {
    let availability: [DecorationAvailability]
    let onSelect: (QuizCategory) -> Void
    let time: TimeInterval
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / TreeSlots.designSize.width
            let treeHeight = TreeSlots.designSize.height * scale
            let top = (geometry.size.height - treeHeight) / 2
            let ornamentWidth = 44 * scale
            let ornamentHeight = ornamentWidth * DecorationView.designSize.height / DecorationView.designSize.width

            ZStack(alignment: .topLeading) {
                ChristmasTreeImage(imageScale: 1.8)
                    .frame(width: geometry.size.width, height: treeHeight)
                    .overlay {
                        DecorationAmbientEffects(time: time, isAnimated: reduceMotion == false)
                    }
                    .offset(y: top)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)

                ForEach(availability, id: \.category) { result in
                    let point = position(result.category)
                    SelectableDecoration(availability: result) {
                        onSelect(result.category)
                    }
                    .offset(y: reduceMotion ? 0 : DecorationAmbientMotion.bobOffset(
                        time: time, category: result.category
                    ))
                    .frame(width: ornamentWidth)
                    .offset(
                        x: point.x * scale - ornamentWidth / 2,
                        y: top + point.y * scale - ornamentHeight / 2
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .aspectRatio(TreeSlots.designSize.width / 380, contentMode: .fit)
    }

    private func position(_ category: QuizCategory) -> CGPoint {
        // 트리 이미지를 맞춘 220×214 좌표계에 카테고리 장식을 배치한다.
        switch category {
        case .aiUsage: CGPoint(x: 110, y: 70)
        case .swiftSyntax: CGPoint(x: 65, y: 128)
        case .hig: CGPoint(x: 155, y: 128)
        case .swiftUIPractice: CGPoint(x: 110, y: 174)
        }
    }
}

#if DEBUG
private struct DecorationSelectPreview: View {
    let filter: SelectFilter
    var forceReduceMotion = false

    var body: some View {
        let questions = zip(QuizCategory.allCases, [5, 3, 0, 7]).flatMap { category, count in
            Difficulty.allCases.flatMap { difficulty in
                TaskSelectPreviewData.questions(
                    category: category, difficulty: difficulty,
                    count: difficulty == .normal ? count : 5
                )
            }
        }
        let results = DecorationAvailability.calculate(
            filter: filter, questions: questions, selector: QuestionSelector()
        )
        DecorationSelectView(
            filter: filter, availability: results, onEdit: {}, onSelect: { _ in },
            forceReduceMotion: forceReduceMotion
        )
            .background {
                LinearGradient(
                    colors: [.nightBackgroundTop, .nightBackgroundBottom],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            }
    }
}

#Preview("장식 선택 · 모두 켜짐") {
    DecorationSelectPreview(filter: SelectFilter(difficulty: .easy))
}

#Preview("장식 선택 · 일부 켜짐과 후보 부족") {
    DecorationSelectPreview(filter: SelectFilter())
}

#Preview("장식 선택 · 다크") {
    DecorationSelectPreview(filter: SelectFilter())
        .preferredColorScheme(.dark)
}

#Preview("장식 선택 · 큰 글자") {
    DecorationSelectPreview(filter: SelectFilter())
        .dynamicTypeSize(.accessibility5)
}

#Preview("장식 선택 · iPad 폭", traits: .fixedLayout(width: 1024, height: 768)) {
    DecorationSelectPreview(filter: SelectFilter(difficulty: .easy))
}

#Preview("장식 선택 · 연출과 시스템 모션 설정") {
    DecorationSelectPreview(filter: SelectFilter(difficulty: .easy))
}

#Preview("장식 선택 · 모션 줄이기") {
    DecorationSelectPreview(filter: SelectFilter(difficulty: .easy), forceReduceMotion: true)
}
#endif
