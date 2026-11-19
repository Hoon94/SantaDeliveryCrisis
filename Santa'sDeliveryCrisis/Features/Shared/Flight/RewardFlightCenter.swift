import Observation
import SwiftUI

/// 결과 화면의 장식이 작업실 트리로 날아가는 연출의 상태를 한곳에 모은다.
///
/// 퀴즈 화면(전체 화면 덮개), 앱의 탭 구성, 작업실 트리가 서로 다른 화면 계층에 있어서
/// 셋이 이 객체 하나를 환경으로 공유한다.
/// - 퀴즈 결과: [돌아가기]를 누르면 `start(_:)`로 출발 위치와 받을 칸을 알린다.
/// - 앱의 탭 구성: 출발 신호를 보고 작업실 탭으로 옮기고, 가장 위에 비행 연출을 그린다.
/// - 작업실 트리: 칸 위치를 `treeSceneFrame`으로 알리고, 아직 도착하지 않은 장식은 `pendingCount`만큼 숨긴다.
@MainActor
@Observable
final class RewardFlightCenter {
    /// 앱 전체가 함께 쓰는 하나의 상태 객체.
    static let shared = RewardFlightCenter()

    /// 날아갈 장식 한 묶음의 정보.
    struct Flight: Identifiable {
        let id = UUID()
        /// 장식의 색 구성
        let style: OrnamentStyle
        /// 출발 위치. 화면 전체 좌표계(global)
        let origin: CGPoint
        /// 출발할 때 장식 지름
        let size: CGFloat
        /// 트리에서 새로 채워질 칸의 번호 범위(0부터)
        let slots: Range<Int>

        /// 날아가는 장식 수
        var count: Int { slots.count }
    }

    /// 작업실 트리 장면(칸 좌표의 기준 영역)의 화면 좌표. 작업실이 보일 때마다 갱신된다.
    var treeSceneFrame: CGRect = .zero

    /// 지금 진행 중인 비행. 없으면 nil
    private(set) var flight: Flight?

    /// 아직 트리에 도착하지 않아 트리에서 숨겨야 하는 장식 수
    private(set) var pendingCount = 0

    /// 트리 위치를 알 수 있는가
    var hasTreeFrame: Bool {
        treeSceneFrame.width > 20 && treeSceneFrame.height > 20
    }

    /// 새 비행을 시작한다. 이미 진행 중이면 이전 비행의 숨김을 풀고 새 비행으로 바꾼다.
    /// - Parameter flight: 출발 위치와 받을 칸 정보. 칸이 비어 있으면 아무것도 하지 않는다.
    func start(_ flight: Flight) {
        guard flight.count > 0 else { return }
        self.flight = flight
        pendingCount = flight.count
    }

    /// 장식 하나가 트리에 도착했다. 그 칸을 트리에 보여 준다.
    func landOne() {
        pendingCount = max(pendingCount - 1, 0)
    }

    /// 비행을 끝낸다. 남은 숨김이 있으면 모두 푼다.
    func finish() {
        pendingCount = 0
        flight = nil
    }

    /// 트리 칸의 화면 좌표.
    /// - Parameter slot: 칸 번호(0부터). 범위를 벗어나면 가장 가까운 칸을 쓴다.
    /// - Returns: 트리 위치를 아직 모르면 nil
    func slotCenter(_ slot: Int) -> CGPoint? {
        guard hasTreeFrame, !TreeSlots.positions.isEmpty else { return nil }
        let index = min(max(slot, 0), TreeSlots.positions.count - 1)
        let point = TreeSlots.positions[index]
        return CGPoint(
            x: treeSceneFrame.minX + point.x * treeSceneFrame.width,
            y: treeSceneFrame.minY + point.y * treeSceneFrame.height
        )
    }

    /// 트리 칸에 그려지는 장식의 지름(화면 좌표)
    var slotDiameter: CGFloat {
        guard hasTreeFrame else { return 14 }
        return 14 * treeSceneFrame.width / TreeSlots.designSize.width
    }
}

private struct RewardFlightCenterKey: EnvironmentKey {
    @MainActor static let defaultValue = RewardFlightCenter.shared
}

extension EnvironmentValues {
    /// 장식 비행 연출 상태. 앱 전체가 `RewardFlightCenter.shared` 하나를 함께 쓴다.
    /// 퀴즈 덮개, 탭 안의 작업실 트리, 가장 위 연출 층은 서로 다른 화면 계층에 있어서
    /// 환경 주입에 기대면 일부가 다른 객체를 받을 수 있다. 그래서 기본값을 공유 객체로 두고 따로 주입하지 않는다.
    var rewardFlight: RewardFlightCenter {
        get { self[RewardFlightCenterKey.self] }
        set { self[RewardFlightCenterKey.self] = newValue }
    }
}
