import SwiftUI

/// 출제 조건과 세션 보상 기준을 표시하는 설정 팝업.
struct SelectSetupPopup: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.services) private var services
    @AccessibilityFocusState private var isTitleFocused: Bool

    /// Task 12 규칙을 사용하는 편집 중 출제 설정.
    @Binding var filter: SelectFilter

    /// 추천기가 선택한 카테고리. nil이면 추천 배지를 표시하지 않는다.
    var recommendedCategory: QuizCategory? = nil

    /// 편집한 조건을 적용하고 팝업을 닫는 동작.
    let onApply: () -> Void

    /// 편집을 취소하고 팝업을 닫는 동작.
    let onCancel: () -> Void

    /// 가이드의 팝업 여백과 나이트 색을 사용해 설정 항목을 배치한다.
    var body: some View {
        let optionsLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 6))
            : AnyLayout(HStackLayout(spacing: 6))
        VStack(alignment: .leading, spacing: 7) {
            VStack(alignment: .leading, spacing: 2) {
                Text("오늘의 출제 설정")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Color.nightText)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)
                Text("설정을 마치고 켜진 장식을 눌러 시작해요")
                    .font(.caption)
                    .foregroundStyle(Color.nightSubText)
            }

            Text("난이도")
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color.nightSubText)
                .accessibilityAddTraits(.isHeader)

            optionsLayout {
                ForEach(Difficulty.allCases, id: \.self) { option in
                    difficultyButton(option)
                }
            }

            SelectCategoryCards(filter: $filter, recommendedCategory: recommendedCategory)

            SelectQuestionOptions(
                filter: $filter,
                passThresholdPercent: services.settings.passThresholdPercent
            )

            Button(action: onApply) {
                Text("장식 선택")
                    .font(.body.weight(.heavy))
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .foregroundStyle(Color.nightOnAccent)
                    .background(Color.nightAccent, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityHint("출제 조건을 적용하고 장식 선택 화면으로 이동합니다")
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 18)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color.nightCard, in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(Color.nightLine, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 30, x: 0, y: 20)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onCancel)
        .accessibilityAction(named: Text("출제 설정 취소하고 닫기"), onCancel)
        .task {
            await Task.yield()
            isTitleFocused = true
        }
    }

    private func difficultyButton(_ option: Difficulty) -> some View {
        let isSelected = filter.difficulty == option
        let color = difficultyColor(option)
        let labelLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(HStackLayout(spacing: 8))
            : AnyLayout(VStackLayout(spacing: 1))
        return Button {
            filter.difficulty = option
        } label: {
            labelLayout {
                Text(stars(option))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Text(option.displayName)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Color.nightText)
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(color)
                    .opacity(isSelected ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 7)
            .padding(.bottom, 6)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.nightSoft)
                if isSelected {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(color.opacity(0.12))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isSelected ? color : .nightLine, lineWidth: isSelected ? 3 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.displayName)
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func stars(_ option: Difficulty) -> String {
        switch option {
        case .easy: "★"
        case .normal: "★★"
        case .hard: "★★★"
        }
    }

    private func difficultyColor(_ option: Difficulty) -> Color {
        // 사용자 결정: 나이트 난이도 Asset을 추가하지 않고 SwiftUI 기본 색을 사용한다.
        switch option {
        case .easy: .green
        case .normal: .orange
        case .hard: .red
        }
    }
}
