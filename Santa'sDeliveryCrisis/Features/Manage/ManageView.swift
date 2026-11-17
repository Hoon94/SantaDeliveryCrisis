import SwiftUI

/// 문제 관리 화면의 임시 자리. 작업 7에서 실제 화면으로 교체한다.
struct ManageView: View {
    var body: some View {
        ContentUnavailableView("문제 관리", systemImage: "hammer", description: Text("준비 중입니다."))
            .background(Color.appBackground)
    }
}

#Preview {
    NavigationStack { ManageView() }
}
