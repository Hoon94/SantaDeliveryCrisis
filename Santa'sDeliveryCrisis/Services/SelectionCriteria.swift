import Foundation

/// 출제에서 "약한 문제"와 "오래 안 푼 문제"를 가르는 기준값과 판정 함수.
/// 기준을 바꿀 때는 이 파일의 상수만 고친다.
///
/// - 약한 문제: 풀이 기록이 있고 정답률이 `weakAccuracyPercent`% **미만**인 문제
/// - 오래 안 푼 문제: 마지막으로 푼 지 `staleDays`일 **이상** 지난 문제
/// - 한 번도 안 푼 문제는 둘 다 아니다. 출제 범주에서는 "오래 안 푼 문제"와 같은 묶음으로 따로 다룬다.
nonisolated enum SelectionCriteria {
    /// 이 값 미만이면 약한 문제 (정답률 %)
    static let weakAccuracyPercent = 60

    /// 이 값 이상 지났으면 오래 안 푼 문제 (일)
    static let staleDays = 5

    /// 오래 안 푼 기준을 초로 환산한 값 (하루 = 24시간으로 계산)
    static var staleInterval: TimeInterval {
        TimeInterval(staleDays) * 24 * 60 * 60
    }

    /// 정답률이 기준 미만인 약한 문제인가. 풀이 기록이 없으면 false.
    /// 소수점 오차를 피하려고 정수끼리 비교한다 (`correct / total < 60%` 와 같은 뜻).
    /// - Parameters:
    ///   - correctCount: 맞힌 횟수
    ///   - totalCount: 푼 횟수
    static func isWeak(correctCount: Int, totalCount: Int) -> Bool {
        guard totalCount > 0 else { return false }
        return correctCount * 100 < weakAccuracyPercent * totalCount
    }

    /// 마지막으로 푼 지 기준일 이상 지났는가. 한 번도 안 풀었으면(`lastSolvedAt == nil`) false.
    /// - Parameters:
    ///   - lastSolvedAt: 마지막으로 푼 시각
    ///   - now: 현재 시각. 테스트에서 고정값을 넘길 수 있게 주입받는다.
    static func isStale(lastSolvedAt: Date?, now: Date) -> Bool {
        guard let lastSolvedAt else { return false }
        return now.timeIntervalSince(lastSolvedAt) >= staleInterval
    }
}
