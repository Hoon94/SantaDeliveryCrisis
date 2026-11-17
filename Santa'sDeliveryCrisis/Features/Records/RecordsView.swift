import SwiftUI

/// 기록 화면의 임시 자리. 작업 6에서 실제 화면으로 교체한다.
struct RecordsView: View {
    var body: some View {
        ContentUnavailableView("기록", systemImage: "hammer", description: Text("준비 중입니다."))
            .background(Color.appBackground)
    }
}

#Preview {
    NavigationStack { RecordsView() }
}
