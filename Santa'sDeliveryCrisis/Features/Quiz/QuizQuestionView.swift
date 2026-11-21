import SwiftUI

/// 문제 풀이 화면(S4). 상단 진행 줄, 문제와 코드, 보기 4개, 하단의 캐릭터와 [확인] 버튼.
struct QuizQuestionView: View {
    @Bindable var model: QuizFlowModel
    let services: AppServices
    let onExit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// 코드를 크게 보는 창이 열려 있는 문제의 번호. nil이면 닫힘
    @State private var codePreviewIndex: Int?
    /// 코드 상자의 화면 좌표. 창이 이 자리에서 펼쳐진다. 스크롤마다 바뀌므로 화면을 다시 그리지 않는 상자에 담아 둔다.
    @State private var codeFrame = FrameBox()

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                if let snapshot = model.currentSnapshot {
                    questionContent(snapshot)
                        .id(model.index)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                        )
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .animation(.spring(response: 0.5, dampingFraction: 0.86), value: model.index)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomDock }
        .overlay { codePreview }
        .onChange(of: model.index) { codePreviewIndex = nil }
    }

    /// 코드를 누르면 열리는 큰 창. 테두리와 닫기 버튼 없이 창 안이나 바깥을 한 번 누르면 닫힌다.
    /// 열고 닫는 움직임은 창이 스스로 맡으므로 여기서는 따로 전환을 주지 않는다.
    @ViewBuilder private var codePreview: some View {
        if codePreviewIndex != nil, let code = model.currentSnapshot?.codeSnippet, !code.isEmpty {
            CodePreviewPopup(code: code, sourceFrame: codeFrame.rect) {
                codePreviewIndex = nil
            }
            .zIndex(1)
        }
    }

    private func openCodePreview() {
        services.feedback.play(.select)
        codePreviewIndex = model.index
    }

    // MARK: - 머리

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    services.feedback.play(.button)
                    onExit()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color.nightPrimaryText)
                }
                .buttonStyle(RoundIconButtonStyle())
                .accessibilityLabel("퀴즈 나가기")

                Spacer()

                Text("\(min(model.index + 1, max(model.totalCount, 1))) / \(model.totalCount)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.nightPrimaryText)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: model.index)
                    .accessibilityLabel("\(model.index + 1)번째 문제, 총 \(model.totalCount)문제")

                Spacer()

                hintButton
            }
            ProgressTrack(progress: model.progress, tint: model.theme.accent)
            processProgress
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
    }

    /// 문항 진행률과 별개로 현재 작업 과정과 앞뒤 과정을 표시한다.
    private var processProgress: some View {
        let current = QuizTheme.allCases.firstIndex(of: model.theme) ?? 0
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: dynamicTypeSize.isAccessibilitySize ? 2 : 4),
            spacing: 6
        ) {
            ForEach(Array(QuizTheme.allCases.enumerated()), id: \.element) { offset, theme in
                VStack(spacing: 4) {
                    Image(systemName: offset < current ? "checkmark.circle.fill" : offset == current ? "play.circle.fill" : "circle")
                        .accessibilityHidden(true)
                    Text(theme.title)
                        .font(.caption2.weight(offset == current ? .bold : .regular))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(offset == current ? theme.accent : Color.nightSecondaryText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 8)
                .background(Color.nightCardBackground.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    if offset == current {
                        RoundedRectangle(cornerRadius: 10).strokeBorder(theme.accent, lineWidth: 1.5)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(theme.title), \(offset < current ? "완료" : offset == current ? "진행 중" : "예정")")
            }
        }
    }

    /// 힌트가 있는 문제에만 보인다. 자리는 항상 차지해서 숫자가 가운데에 고정된다.
    @ViewBuilder private var hintButton: some View {
        if model.currentSnapshot?.hint != nil, model.phase == .answering {
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { model.toggleHint() }
            } label: {
                Image(systemName: model.isHintVisible ? "lightbulb.fill" : "lightbulb")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(model.isHintVisible ? Color.ornamentGold : Color.nightPrimaryText)
                    .symbolEffect(.bounce, value: model.isHintVisible)
            }
            .buttonStyle(RoundIconButtonStyle())
            .accessibilityLabel(model.isHintVisible ? "힌트 닫기" : "힌트 보기")
            .accessibilityHint("힌트를 봐도 점수와 보상은 달라지지 않아요")
        } else {
            Color.clear.frame(width: 44, height: 44)
        }
    }

    // MARK: - 본문

    private func questionContent(_ snapshot: QuestionSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            chips(snapshot)

            Text(snapshot.text)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.nightPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(card)

            if let code = snapshot.codeSnippet, !code.isEmpty {
                codeBlock(code)
            }

            if model.isHintVisible, let hint = snapshot.hint {
                hintBox(hint)
                    .transition(.scale(scale: 0.92, anchor: .top).combined(with: .opacity))
            }

            if snapshot.kind == .animation {
                // 애니메이션 문제는 장면이 아직 없다. 장면이 없으면 판정과 해설만 보여 주는 규칙을 따른다.
                Label("이 문제의 애니메이션은 준비 중이에요", systemImage: "sparkles")
                    .font(.footnote)
                    .foregroundStyle(Color.nightSecondaryText)
            }

            VStack(spacing: 10) {
                ForEach(Array(snapshot.choices.enumerated()), id: \.offset) { offset, choice in
                    QuizChoiceButton(
                        index: offset,
                        text: choice,
                        state: model.choiceState(at: offset),
                        theme: model.theme
                    ) {
                        model.select(offset)
                    }
                    .disabled(model.phase != .answering)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
    }

    /// 스테이지, 난이도, 태그 칩. 태그에는 그 문제의 카테고리 이름이 맨 앞에 들어간다.
    /// 칩이 한 줄에 다 들어가지 않으면(큰 글자 등) 카테고리 태그만 남기고 나머지 태그를 줄인다.
    private func chips(_ snapshot: QuestionSnapshot) -> some View {
        let categoryTag = snapshot.category.categoryName
        let extraTag = snapshot.tags.first { $0 != categoryTag }
        return ViewThatFits(in: .horizontal) {
            chipRow(categoryTag: categoryTag, extraTag: extraTag)
            chipRow(categoryTag: categoryTag, extraTag: nil)
        }
    }

    private func chipRow(categoryTag: String, extraTag: String?) -> some View {
        HStack(spacing: 8) {
            chip(
                QuizStage(task: model.session.task, difficulty: model.session.difficulty).title,
                tint: model.session.task.themeColor,
                filled: true
            )
            chip(model.session.difficulty.displayName, tint: .nightSecondaryText, filled: false)
            chip("#\(categoryTag)", tint: .nightSecondaryText, filled: false)
            if let extraTag {
                chip("#\(extraTag)", tint: .nightSecondaryText, filled: false)
            }
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ text: String, tint: Color, filled: Bool) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(filled ? Color.glowWhite : tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(filled ? tint : Color.nightSubtleBackground.opacity(0.9)))
    }

    /// 짧게 훑어보는 코드 상자. 좌우로 스크롤하거나, 눌러서 전체를 큰 창으로 볼 수 있다.
    private func codeBlock(_ code: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(Color.nightPrimaryText)
                .padding(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.nightSubtleBackground.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.nightBorder, lineWidth: 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.nightSecondaryText)
                .padding(6)
                .background(Circle().fill(Color.nightSubtleBackground))
                .padding(6)
                .allowsHitTesting(false)
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { codeFrame.rect = $0 }
        .onTapGesture { openCodePreview() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("코드")
        .accessibilityValue(code)
        .accessibilityHint("누르면 전체 코드를 크게 봐요")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { openCodePreview() }
    }

    private func hintBox(_ hint: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("힌트", systemImage: "lightbulb.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.ornamentGold)
            Text(hint)
                .font(.callout)
                .foregroundStyle(Color.nightPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text("힌트를 봐도 점수와 보상은 달라지지 않아요")
                .font(.caption)
                .foregroundStyle(Color.nightSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.ornamentGold.opacity(0.14))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.ornamentGold.opacity(0.6), lineWidth: 1.2))
        )
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.nightCardBackground.opacity(0.9))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.nightBorder, lineWidth: 1))
            .shadow(color: Color.inkShadow.opacity(0.18), radius: 12, y: 6)
    }

    // MARK: - 아래

    /// 캐릭터는 왼쪽 아래에 작게 서 있고, 오른쪽에 [확인] 버튼이 있다.
    private var bottomDock: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ThemeCharacterView(
                theme: model.theme,
                isSpeaking: model.selectedIndex != nil
            )
            .frame(width: 72, height: 96)

            VStack(alignment: .leading, spacing: 12) {
                SpeechBubble(text: model.bubble ?? model.theme.idleLine, tint: model.theme.accent)
                    .accessibilityLabel("\(model.theme.characterName): \(model.bubble ?? model.theme.idleLine)")

                Button {
                    model.confirm()
                } label: {
                    Text("확인")
                }
                .buttonStyle(GlowButtonStyle(tint: model.theme.accent))
                .disabled(!model.canConfirm)
                .accessibilityHint(model.canConfirm ? "고른 답을 채점해요" : "먼저 보기를 하나 골라 주세요")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [.clear, Color.nightBackgroundBottom.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

/// 문제 진행 줄. 채워질 때 스프링으로 늘어나고 끝에 빛나는 점이 있다.
private struct ProgressTrack: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * progress
            ZStack(alignment: .leading) {
                Capsule().fill(Color.nightSubtleBackground)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.7), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(width, progress > 0 ? 8 : 0))
                    .overlay(alignment: .trailing) {
                        if progress > 0 {
                            Circle()
                                .fill(Color.glowWhite)
                                .frame(width: 7, height: 7)
                                .shadow(color: tint, radius: 6)
                                .padding(.trailing, 1)
                        }
                    }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.78), value: progress)
        }
        .frame(height: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("진행률")
        .accessibilityValue("\(Int(progress * 100))퍼센트")
    }
}

/// 값이 바뀌어도 화면을 다시 그리지 않는 작은 상자. 스크롤 중 계속 바뀌는 좌표를 담아 둘 때 쓴다.
private final class FrameBox {
    var rect: CGRect?
}
