import SwiftUI

/// 세션 결과 팝업. 정답률 링, 작업과 난이도, 소요 시간, 트리 진행도, 오답 수, [돌아가기] 버튼.
///
/// 등장 연출은 `shownFor`(카드가 나타난 뒤 흐른 시간)만으로 정해진다. 그래서 어느 시각의 모습이든 바로 그릴 수 있고,
/// 연출이 끝난 뒤에는 `shownFor`를 크게 주면 최종 모습 그대로다.
struct ResultPopupCard: View {
    let summary: QuizResultSummary
    /// 장식 색. 링과 버튼에 쓴다.
    let tint: Color
    /// 카드가 나타난 뒤 흐른 시간(초)
    let shownFor: Double
    let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isCompact: Bool { dynamicTypeSize >= .accessibility1 }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header.stagger(0, t: shownFor)

                Group {
                    if isCompact {
                        VStack(spacing: 16) { ring; details }
                    } else {
                        HStack(alignment: .center, spacing: 18) { ring; details }
                    }
                }
                .stagger(1, t: shownFor)

                passBanner.stagger(2, t: shownFor)
                treeProgress.stagger(3, t: shownFor)
                wrongSummary.stagger(4, t: shownFor)

                Button(action: onClose) {
                    Text("돌아가기")
                }
                .buttonStyle(GlowButtonStyle(tint: tint))
                .stagger(5, t: shownFor)
                .padding(.top, 2)
            }
            .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.nightCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [tint.opacity(0.9), Color.nightBorder, tint.opacity(0.3)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: tint.opacity(0.35), radius: 28, y: -4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .allowsHitTesting(shownFor > 0.5)
    }

    // MARK: - 조각

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: summary.isSuccess ? "gift.fill" : "gift")
                .foregroundStyle(summary.isSuccess ? tint : Color.nightSecondaryText)
            Text("세션 결과")
                .font(.headline)
                .foregroundStyle(Color.nightPrimaryText)
            Spacer(minLength: 0)
            Text(summary.taskTitle)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.glowWhite)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(tint))
        }
    }

    private var ring: some View {
        AccuracyRing(
            percent: summary.result.accuracyPercent,
            threshold: summary.thresholdPercent,
            correct: summary.result.correctCount,
            total: summary.result.totalCount,
            isSuccess: summary.isSuccess,
            tint: tint,
            t: shownFor
        )
        .frame(width: 128, height: 128)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 10) {
            detailRow(icon: "square.grid.2x2.fill", title: "카테고리", value: summary.categoryTitle)
            detailRow(icon: "speedometer", title: "난이도", value: summary.difficulty.displayName)
            detailRow(icon: "clock.fill", title: "소요 시간", value: summary.elapsedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(tint)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.nightSecondaryText)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.nightPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// 통과 여부. 색 외에 아이콘과 문구로도 구분한다.
    private var passBanner: some View {
        let isSuccess = summary.isSuccess
        return HStack(spacing: 10) {
            Image(systemName: isSuccess ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.title3)
                .foregroundStyle(isSuccess ? Color.roomPositive : Color.roomNegative)
            VStack(alignment: .leading, spacing: 2) {
                Text(isSuccess ? "기준 \(summary.thresholdPercent)% 통과" : "기준 \(summary.thresholdPercent)%에 못 미쳤어요")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.nightPrimaryText)
                Text(isSuccess ? "장식을 1개 받았어요" : "벌칙은 없어요. 다시 도전해 보세요")
                    .font(.caption)
                    .foregroundStyle(Color.nightSecondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill((isSuccess ? Color.roomPositive : Color.roomNegative).opacity(0.13))
        )
        .accessibilityElement(children: .combine)
    }

    private var treeProgress: some View {
        let count = summary.treeDecorationCount
        let slots = TreeRecord.slotCount
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("트리", systemImage: "tree.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.nightPrimaryText)
                Spacer()
                Text(summary.result.treeCompleted ? "완성! \(slots) / \(slots)" : "\(count) / \(slots)")
                    .font(.subheadline.weight(.heavy).monospacedDigit())
                    .foregroundStyle(summary.result.treeCompleted ? tint : Color.nightPrimaryText)
            }
            TreePips(
                filled: count,
                total: slots,
                newest: summary.isSuccess ? count - 1 : nil,
                tint: tint,
                t: shownFor
            )
            if summary.result.treeCompleted {
                Text("트리가 완성됐어요. 새 트리를 시작해요")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            } else {
                Text("\(slots - count)칸 남았어요")
                    .font(.caption)
                    .foregroundStyle(Color.nightSecondaryText)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.nightSubtleBackground))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("트리 장식 \(slots)칸 중 \(count)칸")
    }

    private var wrongSummary: some View {
        let wrong = summary.result.wrongAnswers.count
        return HStack(spacing: 10) {
            Image(systemName: wrong == 0 ? "party.popper.fill" : "xmark.circle.fill")
                .foregroundStyle(wrong == 0 ? Color.ornamentGold : Color.roomNegative)
            Text(wrong == 0 ? "틀린 문제가 없어요. 모두 맞혔어요!" : "오답 \(wrong)개")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.nightPrimaryText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 정답률 링

/// 정답률을 채워 보여 주는 링. 기준선 눈금이 있고, 가운데 숫자가 올라간다.
private struct AccuracyRing: View {
    let percent: Int
    let threshold: Int
    let correct: Int
    let total: Int
    let isSuccess: Bool
    let tint: Color
    let t: Double

    var body: some View {
        let fill = RevealMath.easeOut((t - 0.25) / 1.25)
        let shown = Int((Double(percent) * fill).rounded(.down))
        let ringColor: Color = isSuccess ? tint : .roomNegative

        ZStack {
            Circle().stroke(Color.nightSubtleBackground, lineWidth: 12)
            Circle()
                .trim(from: 0, to: Double(percent) / 100 * fill)
                .stroke(
                    AngularGradient(colors: [ringColor.opacity(0.55), ringColor], center: .center, startAngle: .degrees(0), endAngle: .degrees(360 * max(Double(percent) / 100, 0.01))),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: ringColor.opacity(0.6), radius: 8)

            // 기준 눈금
            Capsule()
                .fill(Color.nightPrimaryText.opacity(0.8))
                .frame(width: 3, height: 18)
                .offset(y: -64)
                .rotationEffect(.degrees(Double(threshold) / 100 * 360))
                .opacity(RevealMath.smooth((t - 0.1) / 0.3))

            VStack(spacing: 0) {
                Text("\(shown)%")
                    .font(.system(.title, design: .rounded).weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(Color.nightPrimaryText)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("\(correct) / \(total) 정답")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.nightSecondaryText)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .padding(.horizontal, 18)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("정답률 \(percent)퍼센트, \(total)문제 중 \(correct)문제 정답. 기준은 \(threshold)퍼센트")
    }
}

// MARK: - 트리 칸

/// 트리 장식 칸 12개. 방금 받은 칸은 톡 튀며 빛난다.
private struct TreePips: View {
    let filled: Int
    let total: Int
    let newest: Int?
    let tint: Color
    let t: Double

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { i in
                pip(i)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func pip(_ i: Int) -> some View {
        let isFilled = i < filled
        let isNewest = newest == i
        // 새 칸은 카드가 나타나고 조금 뒤 튀어 오른다.
        let pop = isNewest ? RevealMath.spring(t - 1.1, damping: 8, frequency: 12) : 1
        let appear = isNewest ? RevealMath.smooth((t - 1.05) / 0.12) : 1
        return ZStack {
            Circle()
                .strokeBorder(Color.nightBorder, lineWidth: 1.5)
            if isFilled && (!isNewest || appear > 0) {
                Circle()
                    .fill(RadialGradient(colors: [.glowWhite.opacity(0.8), isNewest ? tint : .ornamentGold, .decorationCap], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: 14))
                    .scaleEffect(isNewest ? pop : 1)
                    .shadow(color: isNewest ? tint.opacity(0.9) : .clear, radius: isNewest ? 8 * appear : 0)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 24)
    }
}

// MARK: - 등장 효과

private extension View {
    /// `index`번째 항목이 차례로 떠오른다. `t`는 카드가 나타난 뒤 흐른 시간.
    func stagger(_ index: Int, t: Double) -> some View {
        let p = RevealMath.smooth((t - 0.12 - Double(index) * 0.1) / 0.4)
        return self
            .opacity(p)
            .offset(y: (1 - p) * 18)
    }
}

#Preview("성공 · 최종 모습") {
    ResultPopupCard(summary: .previewSuccess, tint: .categoryAiUsage, shownFor: 9) {}
        .frame(maxHeight: 560)
        .padding()
        .background(Color.revealScrim)
}

#Preview("미달 · 최종 모습") {
    ResultPopupCard(summary: .previewFailure, tint: .categorySwiftSyntax, shownFor: 9) {}
        .frame(maxHeight: 560)
        .padding()
        .background(Color.revealScrim)
}

#Preview("트리 완성 · 큰 글자") {
    ResultPopupCard(summary: .previewTreeComplete, tint: .categoryHig, shownFor: 9) {}
        .dynamicTypeSize(.accessibility3)
        .frame(maxHeight: 700)
        .padding()
        .background(Color.revealScrim)
}
