import SwiftUI

/// 출제 화면의 라이트·다크 색상을 사용하는 퀴즈 풀이 전용 팔레트.
struct QuizPalette {
    /// 현재 화면에 적용된 밝기 모드.
    let colorScheme: ColorScheme

    /// 문제와 본문 글자색.
    var primaryText: Color { .nightPrimaryText }
    /// 보조 설명과 미선택 표시의 글자색.
    var secondaryText: Color { .nightSecondaryText }
    /// 라이트 카드는 출제 화면의 연한 하늘색 바탕을 사용하고, 다크는 남색 카드를 유지한다.
    var cardBackground: Color { colorScheme == .light ? .nightSubtleBackground : .nightCardBackground }
    /// 코드와 태그 등 보조 영역의 바탕색.
    var subtleBackground: Color { .nightSubtleBackground }
    /// 카드 테두리와 비활성 버튼색.
    var border: Color { .nightBorder }
    /// 하단 고정 영역의 바탕색.
    var dockBackground: Color { .nightBackgroundBottom }
    /// 픽셀 배경 위에 덮는 색상막.
    var backdrop: Color { .nightBackgroundTop }
    /// 힌트의 강조색.
    var warning: Color { .nightAccent }
    /// 강조색 버튼 위의 글자색.
    var onAccentText: Color { .nightOnAccentText }

    /// 출제 화면과 동일하게 라이트는 주황색, 다크는 노란색을 사용한다.
    var accent: Color { .nightAccent }
}
