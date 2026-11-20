import SwiftUI
import UIKit

/// 주입된 서비스의 상태를 표시하고 사용자 조작을 전달하는 학습 알림 설정 카드.
struct DailyQuizReminderSettingsCard: View {
    /// 부모 설정 화면이 Environment에서 받은 실제 또는 프리뷰용 알림 서비스.
    let reminders: any DailyQuizReminderManaging
    @State private var isHandlingAction = false

    private var isBusy: Bool { isHandlingAction || reminders.isUpdating }

    private var selection: Binding<Bool> {
        Binding(
            get: { reminders.isEnabled },
            set: { enabled in
                performAction { await reminders.setEnabled(enabled) }
            }
        )
    }

    /// 알림 사용 여부와 권한·처리·오류 안내를 기존 설정 카드 스타일로 표시한다.
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("학습 알림", isOn: selection)
                .tint(Color.roomAccent)
                .accessibilityHint("오늘 완료한 퀴즈가 없는 경우 학습 알림을 받아요.")

            Text("오늘 완료한 퀴즈가 없으면 오후 8시에 알려드려요.")
                .font(.caption)
                .foregroundStyle(Color.roomSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

            #if DEBUG
            if DailyQuizReminderConfiguration.debugOneMinuteEnabled {
                Text("개발용: 알림을 켜거나 앱을 새로 실행한 뒤 1분 후에 테스트해요. 오늘 완료 기록이 있으면 알림이 오지 않아요.")
                    .font(.caption)
                    .foregroundStyle(Color.roomSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            #endif

            if isBusy {
                ProgressView("알림 설정을 확인하고 있어요")
                    .font(.caption)
                    .tint(Color.roomAccent)
            }

            if reminders.authorization == .denied {
                Label("기기 설정에서 이 앱의 알림이 차단되어 있어요.", systemImage: "bell.slash")
                    .font(.caption)
                    .foregroundStyle(Color.roomSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    Link("알림 설정 열기", destination: url)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.roomAccent)
                        .accessibilityHint("설정 앱에서 이 앱의 알림 권한을 변경해요.")
                }
            } else if let message = reminders.errorMessage {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(Color.roomNegative)
                    .fixedSize(horizontal: false, vertical: true)
                Button("다시 시도") {
                    performAction {
                        if reminders.isEnabled {
                            await reminders.refresh()
                        } else {
                            await reminders.setEnabled(true)
                        }
                    }
                }
                .font(.subheadline.bold())
                .foregroundStyle(Color.roomAccent)
            }
        }
        .disabled(isBusy)
        .foregroundStyle(Color.roomPrimaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .roomCardBackground()
        .task { await reminders.refresh() }
    }

    private func performAction(_ action: @escaping @MainActor () async -> Void) {
        guard !isBusy else { return }
        isHandlingAction = true
        Task {
            await action()
            isHandlingAction = false
        }
    }
}

#if DEBUG
/// 프리뷰에서는 시스템 설정 링크도 외부 앱을 열지 않게 처리한다.
private func reminderCardPreview(_ reminders: MockDailyQuizReminderManager) -> some View {
    DailyQuizReminderSettingsCard(reminders: reminders)
        .padding()
        .background(Color.roomBackground)
        .environment(\.openURL, OpenURLAction { _ in .handled })
}

#Preview("학습 알림 · 꺼짐") {
    reminderCardPreview(MockDailyQuizReminderManager())
}

#Preview("학습 알림 · 켜짐") {
    reminderCardPreview(MockDailyQuizReminderManager(isEnabled: true, authorization: .allowed))
}

#Preview("학습 알림 · 권한 차단") {
    reminderCardPreview(MockDailyQuizReminderManager(isEnabled: true, authorization: .denied))
}

#Preview("학습 알림 · 권한 거절 후 꺼짐") {
    reminderCardPreview(MockDailyQuizReminderManager(authorization: .denied))
}

#Preview("학습 알림 · 처리 중") {
    reminderCardPreview(MockDailyQuizReminderManager(
        isEnabled: true, authorization: .allowed, isUpdating: true
    ))
}

#Preview("학습 알림 · 예약 오류") {
    reminderCardPreview(MockDailyQuizReminderManager(
        isEnabled: true, authorization: .allowed,
        errorMessage: "학습 알림을 설정하지 못했어요. 잠시 후 다시 시도해 주세요."
    ))
}

#Preview("학습 알림 · 다크") {
    reminderCardPreview(MockDailyQuizReminderManager(isEnabled: true, authorization: .allowed))
        .preferredColorScheme(.dark)
}

#Preview("학습 알림 · 큰 글자") {
    ScrollView {
        reminderCardPreview(MockDailyQuizReminderManager(isEnabled: true, authorization: .denied))
    }
    .background(Color.roomBackground)
    .dynamicTypeSize(.accessibility3)
}
#endif
