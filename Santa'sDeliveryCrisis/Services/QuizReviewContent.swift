import Foundation

/// 풀 당시 문제와 내 선택을 연결한 읽기 전용 오답 항목.
struct QuizReviewQuestion: Identifiable {
    /// 원래 세션에서의 문제 번호(1부터).
    let number: Int
    /// 문제·보기·해설·미디어의 풀 당시 내용.
    let snapshot: QuestionSnapshot
    /// 당시 제출한 보기 번호(0부터).
    let selectedIndex: Int

    var id: UUID { snapshot.questionID }
}

/// 오답에 저장된 외부 학습 자료. 같은 주소는 목록에서 한 번만 표시한다.
struct QuizReviewResource: Identifiable {
    /// 자료 제목. 제목이 없으면 주소의 도메인을 표시한다.
    let title: String
    /// 외부 브라우저로 열 유효한 주소.
    let url: URL

    var id: String { url.absoluteString }

    /// 앞뒤 공백을 제거하고 유효한 HTTP·HTTPS 주소에만 링크를 제공한다.
    static func from(_ snapshot: QuestionSnapshot) -> QuizReviewResource? {
        guard let address = snapshot.resourceURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              var components = URLComponents(string: address),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = components.host, !host.isEmpty else { return nil }
        components.scheme = scheme
        components.host = host.lowercased()
        guard let url = components.url else { return nil }
        let title = snapshot.resourceTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return QuizReviewResource(title: title.isEmpty ? host : title, url: url)
    }
}

/// 이번 세션의 오답과 추천 자료를 구성한다. 점수·보상·저장 데이터를 변경하지 않는다.
struct QuizReviewContent {
    /// 원본이 남아 있는 오답을 세션의 문항 순서로 나열한다.
    let questions: [QuizReviewQuestion]
    /// 위 오답의 유효한 학습 자료. 같은 주소는 먼저 나온 제목을 사용한다.
    let resources: [QuizReviewResource]
    /// 원본 문제 삭제로 복습 목록에서 제외한 오답 수.
    let deletedCount: Int

    /// 원본은 존재 여부만 확인하고, 표시 내용은 항상 세션의 복사본에서 읽는다.
    init(summary: QuizResultSummary, existingQuestionIDs: Set<UUID>) {
        let answers = Dictionary(
            summary.result.wrongAnswers.map { ($0.questionID, $0.selectedIndex) },
            uniquingKeysWith: { first, _ in first }
        )
        questions = summary.questionSnapshots.enumerated().compactMap { index, snapshot in
            guard existingQuestionIDs.contains(snapshot.questionID),
                  let selectedIndex = answers[snapshot.questionID] else { return nil }
            return QuizReviewQuestion(number: index + 1, snapshot: snapshot, selectedIndex: selectedIndex)
        }
        deletedCount = Set(answers.keys).subtracting(existingQuestionIDs).count
        var seen = Set<String>()
        resources = questions.compactMap { question in
            guard let resource = QuizReviewResource.from(question.snapshot), seen.insert(resource.id).inserted else {
                return nil
            }
            return resource
        }
    }
}
