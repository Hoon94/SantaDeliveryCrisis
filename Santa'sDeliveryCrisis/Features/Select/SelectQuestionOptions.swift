import SwiftUI

/// 문제 수 선택과 출제 조건 요약, 세션 보상 기준 안내 영역.
struct SelectQuestionOptions: View {
    /// 팝업에서 편집 중인 출제 설정.
    @Binding var filter: SelectFilter

    /// 설정 서비스에서 읽은 세션 보상 정답률 기준.
    let passThresholdPercent: Int

    /// 잠금 없는 문제 수 선택과 현재 편집값의 요약을 표시한다.
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

            summary
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.nightSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

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

    private var summary: Text {
        let names = filter.orderedCategories.map(\.categoryName).joined(separator: " · ")
        return Text("\(names)에서 총 ")
            + Text("\(filter.count)문제")
                .bold()
                .foregroundColor(.nightPrimaryText)
            + Text(" · 선택 안 한 장식은 흐려져요")
    }

    private func countButton(_ count: Int) -> some View {
        let isSelected = filter.count == count
        return Button {
            filter.setCount(count)
        } label: {
            VStack(spacing: 1) {
                Text("\(count)")
                    .font(.body.weight(.heavy))
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .opacity(isSelected ? 1 : 0)
            }
            .foregroundStyle(isSelected ? Color.nightOnAccentText : .nightSecondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.nightAccent)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(count)문제")
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

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
