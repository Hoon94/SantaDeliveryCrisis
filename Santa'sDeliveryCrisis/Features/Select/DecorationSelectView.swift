import SwiftUI

/// 트리 이미지 위에 네 카테고리 장식과 적용된 출제 조건을 표시하는 화면.
struct DecorationSelectView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    /// 마지막으로 적용한 출제 설정.
    let filter: SelectFilter

    /// 카테고리별로 계산한 장식 활성 상태와 후보 부족 정보.
    let availability: [DecorationAvailability]

    /// 현재 트리에서 획득한 장식 수. 표시만 하며 트리 기록은 변경하지 않는다.
    let filledCount: Int

    /// 적용한 조건으로 설정 팝업을 다시 여는 동작.
    let onEdit: () -> Void

    /// 출제 설정만 기본값으로 되돌리는 동작.
    let onResetSettings: () -> Void

    /// 활성 장식의 카테고리로 세션 시작을 요청하는 동작.
    let onSelect: (QuizCategory) -> Void

    /// 프리뷰에서 정적 연출을 강제한다. 시스템의 모션 줄이기는 항상 우선한다.
    var forceReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || forceReduceMotion }

    /// 상단에 제목·조건 칩·설정 초기화·장식 진행도를 표시하고 아래에 트리와 장식을 배치한다.
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
                // FIXME: [가정 8] 범례·문 열림·통과 점·체크 배지는 별도 작업에서 반영
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

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("출제")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Color.nightPrimaryText)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: onResetSettings) {
                    Label("초기화", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.nightPrimaryText)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color.nightCardBackground, in: Capsule())
                        .overlay { Capsule().strokeBorder(Color.nightBorder, lineWidth: 1) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("출제 설정 초기화")
                .accessibilityHint("난이도, 카테고리와 문제 수를 기본값으로 되돌립니다")
            }

            layout {
                conditionChip
                if dynamicTypeSize.isAccessibilitySize == false {
                    Spacer(minLength: 0)
                }
                decorationProgress
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityHint("문제 유형 선택 팝업을 다시 엽니다")
    }

    private var decorationProgress: some View {
        Text("\(TreeSlots.clampedCount(filledCount)) / \(TreeSlots.count) 장식")
            .font(.caption.weight(.heavy))
            .foregroundStyle(Color.nightOnAccentText)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Color.nightAccent, in: Capsule())
            .accessibilityLabel("장식 \(TreeSlots.count)개 중 \(TreeSlots.clampedCount(filledCount))개 획득")
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
                    .offset(y: top)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                
                DecorationAmbientEffects(time: time, isAnimated: reduceMotion == false)

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
    var filledCount = 6
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
            filter: filter, availability: results, filledCount: filledCount,
            onEdit: {}, onResetSettings: {}, onSelect: { _ in },
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

#Preview("장식 선택 · 획득 장식 없음") {
    DecorationSelectPreview(filter: SelectFilter(), filledCount: 0)
}

#Preview("장식 선택 · 장식 12개") {
    DecorationSelectPreview(filter: SelectFilter(), filledCount: TreeSlots.count)
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
