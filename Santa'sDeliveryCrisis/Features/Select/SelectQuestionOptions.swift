import SwiftUI

/// 문제 수 선택과 세션 보상 기준 안내 영역.
struct SelectQuestionOptions: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var countSelection

    /// 팝업에서 편집 중인 출제 설정.
    @Binding var filter: SelectFilter

    /// 설정 서비스에서 읽은 세션 보상 정답률 기준.
    let passThresholdPercent: Int

    /// 선택한 문제 수를 강조하고 설정된 정답률 기준을 안내한다.
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("문제 수")
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color.nightSecondaryText)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 6) {
                ForEach(SelectFilter.allowedCounts, id: \.self) { count in
                    countButton(count)
                }
            }
            .padding(4)
            .background(Color.nightSubtleBackground, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.nightBorder, lineWidth: 1)
            }
            .animation(
                reduceMotion ? .easeOut(duration: 0.15) : .easeInOut(duration: 0.25),
                value: filter.count
            )

            Text("정답률 \(passThresholdPercent)% 이상이면 장식 1개를 받아요")
                .font(.caption)
                .foregroundStyle(Color.nightPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.nightSubtleBackground, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private func countButton(_ count: Int) -> some View {
        let isSelected = filter.count == count
        return Button {
            filter.setCount(count)
        } label: {
            Text("\(count)")
                .font(.body.weight(isSelected ? .heavy : .semibold))
                .foregroundStyle(isSelected ? Color.nightOnAccentText : .nightSecondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background {
                    if isSelected {
                        selectionBackground
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(count)문제")
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var selectionBackground: some View {
        let highlight = RoundedRectangle(cornerRadius: 16).fill(Color.nightAccent)
        if reduceMotion {
            highlight.transition(.opacity)
        } else {
            highlight.matchedGeometryEffect(id: "questionCountSelection", in: countSelection)
        }
    }
}

#if DEBUG
private struct SelectQuestionOptionsPreview: View {
    @State private var filter: SelectFilter
    let threshold: Int

    init(count: Int, threshold: Int = 80) {
        _filter = State(initialValue: SelectFilter(count: count))
        self.threshold = threshold
    }

    var body: some View {
        ScrollView {
            SelectQuestionOptions(filter: $filter, passThresholdPercent: threshold)
                .padding(16)
        }
        .background(Color.nightCardBackground)
    }
}

#Preview("문제 수 · 5문제") {
    SelectQuestionOptionsPreview(count: 5)
}

#Preview("문제 수 · 10문제") {
    SelectQuestionOptionsPreview(count: 10)
}

#Preview("문제 수 · 15문제") {
    SelectQuestionOptionsPreview(count: 15)
}

#Preview("문제 수 · 기준 50%") {
    SelectQuestionOptionsPreview(count: 5, threshold: 50)
}

#Preview("문제 수 · 기준 100%") {
    SelectQuestionOptionsPreview(count: 15, threshold: 100)
}

#Preview("문제 수 · 큰 글자") {
    SelectQuestionOptionsPreview(count: 10)
        .dynamicTypeSize(.accessibility5)
}
#endif
