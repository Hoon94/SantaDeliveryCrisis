import SwiftUI

/// 출제 설정 팝업의 머리말과 난이도·카테고리 선택 영역.
struct SelectSetupPopup: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Task 12 규칙을 사용하는 편집 중 출제 설정.
    @Binding var filter: SelectFilter

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

            SelectCategoryCards(filter: $filter)
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
