import Foundation

/// 한 세션 안에서 제목(문제 텍스트)이 같은 문제를 구별하는 번호표를 만든다.
///
/// 이번 세션에 뽑힌 문제만 본다. 같은 제목의 문제가 세션에 둘 이상이면 `[1/2] `처럼
/// "이번 세션의 같은 제목 중 몇 번째"를 제목 앞에 붙인다. 번호는 세션에 나오는 순서대로 매긴다.
/// 제목이 하나뿐인 문제에는 번호표가 없고, 세션 밖에 같은 제목의 문제가 더 있어도 세지 않는다.
enum DuplicateTitleLabeler {
    /// 문제 id마다 붙일 번호표(끝에 공백 포함). 번호표가 필요 없는 문제는 들어 있지 않다.
    /// - Parameter sessionQuestions: 이번 세션에 나올 문제. 출제 순서대로 넘긴다.
    static func labels(for sessionQuestions: [Question]) -> [UUID: String] {
        let keys = sessionQuestions.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
        var totals: [String: Int] = [:]
        for key in keys { totals[key, default: 0] += 1 }

        var seen: [String: Int] = [:]
        var result: [UUID: String] = [:]
        for (question, key) in zip(sessionQuestions, keys) {
            guard let total = totals[key], total > 1 else { continue }
            seen[key, default: 0] += 1
            result[question.id] = "[\(seen[key] ?? 1)/\(total)] "
        }
        return result
    }
}
