import SwiftUI

/// Asset 카탈로그의 라이트/다크 색상 세트. 화면 코드에서 색상 값을 직접 쓰지 않고 이 이름만 쓴다.
extension Color {
    /// 화면 기본 배경
    static let appBackground = Color("AppBackground")
    /// 카드와 시트 배경
    static let appSurface = Color("AppSurface")
    /// 주요 강조 (산타 레드)
    static let appPrimary = Color("AppPrimary")
    /// 보조 강조 (트리 그린)
    static let appSecondary = Color("AppSecondary")
    /// 정답 표시
    static let appCorrect = Color("AppCorrect")
    /// 오답 표시
    static let appWrong = Color("AppWrong")
}
