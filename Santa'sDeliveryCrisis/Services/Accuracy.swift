import Foundation

/// 정답률 계산 규칙. 화면에 보여 주는 값과 장식 지급 판정이 같은 규칙을 쓰도록 한 곳에 둔다.
///
/// 팀 합의: 정답률은 **내림**해서 정수 퍼센트로 보여 준다(7/9 = 77.8% → 77%).
/// 장식 지급 판정은 내림한 값이 아니라 정확한 비교이다. 내림한 값이 기준 이상이면 정확한 값도 기준 이상이므로
/// 화면에 기준 이상으로 보이는데 장식을 받지 못하는 경우는 생기지 않는다(79.5%는 79%로 보이고 80% 기준 미달).
///
/// 기록 화면의 평균 점수와 카테고리별 정답률도 이 함수를 쓴다.
nonisolated enum Accuracy {
    /// 정답률(%)을 내림한 정수. 문제 수가 0 이하면 0
    /// - Parameters:
    ///   - correct: 맞힌 수
    ///   - total: 전체 문제 수
    static func percent(correct: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return correct * 100 / total
    }

    /// 정답률이 기준 이상인지 정확하게 비교한다. 문제 수가 0 이하면 false
    /// - Parameters:
    ///   - correct: 맞힌 수
    ///   - total: 전체 문제 수
    ///   - thresholdPercent: 기준 정답률(%)
    static func meetsThreshold(correct: Int, total: Int, thresholdPercent: Int) -> Bool {
        guard total > 0 else { return false }
        return correct * 100 >= thresholdPercent * total
    }
}
