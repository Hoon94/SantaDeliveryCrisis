import SwiftUI

/// 알림 시각을 임시로 선택하고 완료할 때만 서비스에 저장하는 시트.
struct DailyQuizReminderTimeSheet: View {
    let reminders: any DailyQuizReminderManaging
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date
    @State private var isSaving = false
    @State private var saveError: String?

    /// 저장된 시각으로 선택기를 열고, 취소할 때까지 변경을 화면 안에만 보관한다.
    init(reminders: any DailyQuizReminderManaging) {
        self.reminders = reminders
        let time = reminders.reminderTime
        let date = Calendar.current.date(from: DateComponents(hour: time.hour, minute: time.minute)) ?? .now
        _selectedDate = State(initialValue: date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DatePicker("알림 시간", selection: $selectedDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .disabled(isSaving)

                    Text("오늘 완료한 퀴즈가 없으면 선택한 시간에 알려드려요. 이미 지난 시간은 내일부터 적용돼요.")
                        .font(.subheadline)
                        .foregroundStyle(Color.roomSecondaryText)

                    if let saveError {
                        Label(saveError, systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(Color.roomNegative)
                    }
                }
                .padding()
            }
            .foregroundStyle(Color.roomPrimaryText)
            .background { Color.roomBackground.ignoresSafeArea() }
            .navigationTitle("알림 시간")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.roomBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { saveTime() }
                        .disabled(isSaving || reminders.isUpdating)
                }
            }
        }
        .tint(Color.roomAccent)
        .presentationBackground(Color.roomBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isSaving)
    }

    /// 시스템 권한을 다시 확인한 뒤 시·분만 저장한다. 예약 실패 안내는 부모 카드에 남는다.
    private func saveTime() {
        guard !isSaving, !reminders.isUpdating else { return }
        isSaving = true
        saveError = nil
        let calendar = Calendar.current
        let time = DailyQuizReminderTime(
            hour: calendar.component(.hour, from: selectedDate),
            minute: calendar.component(.minute, from: selectedDate)
        )
        Task {
            let accepted = await reminders.updateTime(time)
            isSaving = false
            if accepted {
                dismiss()
            } else {
                saveError = reminders.errorMessage ?? "시간을 저장하지 못했어요. 다시 시도해 주세요."
            }
        }
    }
}

#Preview("알림 시간 선택") {
    DailyQuizReminderTimeSheet(reminders: MockDailyQuizReminderManager(
        isEnabled: true, authorization: .allowed
    ))
}

#Preview("알림 시간 선택 · 다크 · 큰 글자") {
    DailyQuizReminderTimeSheet(reminders: MockDailyQuizReminderManager(
        isEnabled: true, reminderTime: DailyQuizReminderTime(hour: 21, minute: 30), authorization: .allowed
    ))
    .preferredColorScheme(.dark)
    .dynamicTypeSize(.accessibility3)
}
