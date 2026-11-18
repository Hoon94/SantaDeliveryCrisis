import SwiftUI

/// 흐려진 나이트 트리 위에서 출제 조건을 편집하는 화면.
struct SelectView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var filterState = SelectFilterState()

    /// 나이트 배경과 중앙 팝업을 표시하고 편집 중인 출제 조건을 연결한다.
    var body: some View {
        // FIXME: [가정 7] 출제 탭만 나이트 글로우 색 사용. 최종 색이 정해지면 정리
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: .nightBackgroundTop, location: 0),
                        .init(color: .nightBackgroundBottom, location: colorScheme == .dark ? 0.82 : 0.72)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                TreeView(filledCount: 0, skin: .night)
                    .padding(30)
                    .blur(radius: 5)
                    .opacity(0.5)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)

                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)

                ScrollView {
                    SelectSetupPopup(filter: $filterState.editing)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
                .scrollClipDisabled()
            }
        }
    }
}

#Preview("출제 설정 · 라이트") {
    NavigationStack { SelectView() }
        .preferredColorScheme(.light)
}

#Preview("출제 설정 · 다크") {
    NavigationStack { SelectView() }
        .preferredColorScheme(.dark)
}

#Preview("출제 설정 · 큰 글자") {
    NavigationStack { SelectView() }
        .dynamicTypeSize(.accessibility5)
}
