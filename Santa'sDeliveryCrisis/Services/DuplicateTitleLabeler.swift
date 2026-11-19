import Foundation

/// 제목(문제 텍스트)이 같은 문제를 구별하는 번호표를 만든다.
///
/// 같은 제목의 문제가 둘 이상이면 `[3/5] `처럼 "전체 중 몇 번째"를 앞에 붙인다.
/// 번호는 같은 제목을 가진 **모든 문제**(난이도와 카테고리 무관) 안에서 매기고, 순서는 만든 시각, 같으면 id 문자열 순이다.
/// 제목이 하나뿐인 문제에는 번호표가 없다.
enum DuplicateTitleLabeler {
    /// 문제 id마다 붙일 번호표(끝에 공백 포함). 번호표가 필요 없는 문제는 들어 있지 않다.
    /// - Parameter questions: 전체 문제. 같은 제목끼리 묶는 기준 범위다.
    static func labels(for questions: [Question]) -> [UUID: String] {
        let groups = Dictionary(grouping: questions) { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
        var result: [UUID: String] = [:]
        for group in groups.values where group.count > 1 {
            let ordered = group.sorted {
                $0.createdAt == $1.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.createdAt < $1.createdAt
            }
            for (offset, question) in ordered.enumerated() {
                result[question.id] = "[\(offset + 1)/\(ordered.count)] "
            }
        }
        return result
    }
}
