import SwiftUI

/// 작업실 화면의 임시 자리. 작업 4에서 실제 화면으로 교체한다.
struct TaskHomeView: View {
    var body: some View {
        ContentUnavailableView("작업실", systemImage: "hammer", description: Text("준비 중입니다."))
            .background(Color.appBackground)
    }
}

#Preview {
    NavigationStack { TaskHomeView() }
}
