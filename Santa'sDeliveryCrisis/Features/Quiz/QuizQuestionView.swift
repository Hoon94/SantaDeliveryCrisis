import SwiftUI

/// 문제 풀이 화면(S4). 상단 진행 줄, 문제와 코드, 보기 4개, 하단의 캐릭터와 [확인] 버튼.
struct QuizQuestionView: View {
    @Bindable var model: QuizFlowModel
    let services: AppServices
    let onExit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
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

    private func chips(_ snapshot: QuestionSnapshot) -> some View {
        HStack(spacing: 8) {
            chip(model.theme.title, tint: model.theme.accent, filled: true)
            chip(model.session.difficulty.displayName, tint: .nightSecondaryText, filled: false)
            if let tag = snapshot.tags.first {
                chip("#\(tag)", tint: .nightSecondaryText, filled: false)
            }
        }
        .lineLimit(1)
    }

    private func chip(_ text: String, tint: Color, filled: Bool) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(filled ? Color.glowWhite : tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(filled ? tint : Color.nightSubtleBackground.opacity(0.9)))
    }

    private func codeBlock(_ code: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(Color.nightPrimaryText)
                .padding(16)
                .textSelection(.enabled)
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
        .accessibilityLabel("코드")
        .accessibilityValue(code)
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
                mood: model.mood,
                reactionToken: model.reactionToken,
                bubble: model.bubble
            )
            .frame(width: 64, height: 72)

            Button {
                model.confirm()
            } label: {
                Text("확인")
            }
            .buttonStyle(GlowButtonStyle(tint: model.theme.accent))
            .disabled(!model.canConfirm)
            .accessibilityHint(model.canConfirm ? "고른 답을 채점해요" : "먼저 보기를 하나 골라 주세요")
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
