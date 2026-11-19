import SwiftUI

/// 설정 화면(S12). 정답률 기준, 효과음, 진동을 바꾼다.
/// 값은 `SettingsStore`와 같은 키의 `@AppStorage`로 저장한다. 테마와 글자 크기는 시스템 설정을 따른다.
struct SettingsView: View {
    @AppStorage(SettingsStore.Key.passThresholdPercent)
    private var passThresholdPercent = SettingsStore.Default.passThresholdPercent
    @AppStorage(SettingsStore.Key.soundEnabled)
    private var soundEnabled = SettingsStore.Default.soundEnabled
    @AppStorage(SettingsStore.Key.hapticsEnabled)
    private var hapticsEnabled = SettingsStore.Default.hapticsEnabled

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isToastVisible = false
    @State private var toastTask: Task<Void, Never>?

    /// 선택 가능한 정답률 기준 (50, 60, ..., 100)
    private static let thresholdOptions = Array(
        stride(
            from: SettingsStore.passThresholdRange.lowerBound,
            through: SettingsStore.passThresholdRange.upperBound,
            by: SettingsStore.passThresholdStep
        )
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("보상")
                thresholdCard
                sectionLabel("피드백")
                feedbackCard
                sectionLabel("화면")
                systemCard
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.roomPrimaryText)
        .background(Color.roomBackground)
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.roomBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .overlay(alignment: .bottom) { toast }
        .onChange(of: passThresholdPercent) { _, _ in showToast() }
        .onDisappear { toastTask?.cancel() }
    }

    // MARK: - 카드

    private var thresholdCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("장식을 받는 정답률")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(thresholdSelection.wrappedValue)%")
                    .font(.headline)
                    .foregroundStyle(Color.roomAccent)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("장식을 받는 정답률")
            .accessibilityValue("\(thresholdSelection.wrappedValue)퍼센트")
            thresholdPicker
            Text("이 정답률 이상으로 세션을 마치면 장식을 받아요")
                .font(.caption)
                .foregroundStyle(Color.roomSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .roomCardBackground()
    }

    private var feedbackCard: some View {
        VStack(spacing: 0) {
            toggleRow("효과음", isOn: $soundEnabled)
            Divider().overlay(Color.roomBorder)
            toggleRow("진동", isOn: $hapticsEnabled)
        }
        .roomCardBackground(padding: EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
    }

    private var systemCard: some View {
        VStack(spacing: 0) {
            infoRow("테마", detail: "시스템 설정을 따라요")
            Divider().overlay(Color.roomBorder)
            infoRow("글자 크기", detail: "시스템 설정을 따라요")
        }
        .roomCardBackground(padding: EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(Color.roomSecondaryText)
            .accessibilityAddTraits(.isHeader)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .padding(.vertical, 8)
    }

    private func infoRow(_ title: String, detail: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text(title)
                Spacer()
                Text(detail).font(.caption).foregroundStyle(Color.roomSecondaryText)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail).font(.caption).foregroundStyle(Color.roomSecondaryText)
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    // MARK: - 정답률 기준

    /// 저장된 값이 허용 범위를 벗어났으면 기본값으로 보여 준다. `SettingsStore`의 읽기 규칙과 같다.
    private var thresholdSelection: Binding<Int> {
        Binding(
            get: {
                Self.thresholdOptions.contains(passThresholdPercent)
                    ? passThresholdPercent
                    : SettingsStore.Default.passThresholdPercent
            },
            set: { passThresholdPercent = $0 }
        )
    }

    /// 접근성 글자 크기에서는 세그먼트가 좁아 깨지므로 메뉴로 바꾼다.
    @ViewBuilder
    private var thresholdPicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("장식을 받는 정답률", selection: thresholdSelection) {
                ForEach(Self.thresholdOptions, id: \.self) { value in
                    Text("\(value)%").tag(value)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.roomAccent)
        } else {
            RoomSegmentedControl(
                options: Self.thresholdOptions.map { ($0, "\($0)", "\($0)퍼센트") },
                selection: thresholdSelection
            )
        }
    }

    // MARK: - 토스트

    @ViewBuilder
    private var toast: some View {
        if isToastVisible {
            Text("다음 세션부터 적용돼요")
                .font(.callout.bold())
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.horizontal, 18)
                .background(Color.roomToastBackground, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                .padding(.bottom, 56)
                .transition(.opacity)
        }
    }

    private func showToast() {
        toastTask?.cancel()
        withAnimation { isToastVisible = true }
        UIAccessibility.post(notification: .announcement, argument: "다음 세션부터 적용돼요")
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation { isToastVisible = false }
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
