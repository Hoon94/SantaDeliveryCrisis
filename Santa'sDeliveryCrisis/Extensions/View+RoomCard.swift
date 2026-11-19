import SwiftUI

/// 기록·설정 화면이 공유하는 시안(작업실 팔레트) 스타일.
/// 색은 모두 Asset 카탈로그의 `Room*` 색 세트(라이트/다크)를 쓴다.
extension View {
    /// 시안의 카드: 카드 배경, 1pt 테두리, 둥근 모서리
    func roomCardBackground(padding: EdgeInsets = EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)) -> some View {
        self
            .padding(padding)
            .background(Color.roomCardBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.roomBorder, lineWidth: 1))
    }
}
