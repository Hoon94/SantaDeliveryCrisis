#if DEBUG
import Foundation
import SwiftData

/// 문제 관리 화면 미리보기용 샘플 문제. 내 문제, 기본(시드) 문제, 애니메이션 문제를 함께 넣는다.
enum ManagePreviewData {
    /// 메모리 전용 컨테이너를 만든다. `withQuestions`가 true면 샘플 문제를 넣는다.
    static func container(withQuestions: Bool) -> ModelContainer {
        let container = RecordsPreviewData.container(withSessions: false)
        guard withQuestions else { return container }
        let context = container.mainContext
        let day: TimeInterval = 86_400
        let samples: [Question] = [
            sample("Optional 체이닝이 nil인 경우", .swiftSyntax, .normal, isSeed: false, age: 0),
            sample("지난주에 만든 내 문제", .hig, .easy, isSeed: false, age: 7 * day),
            sample("guard의 else 실행 조건", .swiftSyntax, .normal, isSeed: true, age: 20 * day),
            sample("HIG 최소 터치 영역은?", .hig, .easy, isSeed: true, age: 21 * day),
            sample("코드 실행 순서 애니메이션", .swiftSyntax, .easy, isSeed: true, age: 22 * day, kind: .animation),
        ]
        samples.forEach(context.insert)
        return container
    }

    /// 편집 화면 미리보기에 쓸 내 문제
    static func sampleUserQuestion() -> Question {
        sample("Optional 체이닝이 nil을 반환하는 경우는?", .swiftSyntax, .normal, isSeed: false, age: 0)
    }

    /// 상세 화면 미리보기에 쓸 기본 문제. 코드, 힌트, 학습 자료, 태그가 모두 들어 있다.
    static func sampleSeedQuestion() -> Question {
        let question = sample("다음 코드가 출력하는 값은?", .swiftSyntax, .normal, isSeed: true, age: 0)
        question.codeSnippet = "let value: Int? = nil\nprint(value?.description ?? \"nil\")"
        question.hint = "옵셔널이 nil이면 오른쪽 기본값이 쓰여요."
        question.resourceTitle = "The Swift Programming Language: Optional Chaining"
        question.resourceURL = "https://docs.swift.org/swift-book/documentation/the-swift-programming-language/optionalchaining/"
        question.tags = ["Optional", "nil 병합"]
        return question
    }

    private static func sample(
        _ text: String,
        _ category: QuizCategory,
        _ difficulty: Difficulty,
        isSeed: Bool,
        age: TimeInterval,
        kind: QuestionKind = .standard
    ) -> Question {
        Question(
            kind: kind,
            text: text,
            choices: ["값이 없을 때", "값이 있을 때", "항상", "컴파일 오류가 날 때"],
            correctIndex: 0,
            explanation: "옵셔널이 nil이면 체이닝 전체가 nil이 돼요.",
            category: category,
            difficulty: difficulty,
            animationID: kind == .animation ? "sample" : nil,
            isSeed: isSeed,
            createdAt: Date().addingTimeInterval(-age)
        )
    }
}
#endif
