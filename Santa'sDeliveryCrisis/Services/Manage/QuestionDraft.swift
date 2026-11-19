import Foundation

/// 문제 편집 화면의 입력값. 저장하기 전의 임시 상태이며 `Question`과 따로 보관한다.
/// 사용자가 만들거나 고치는 문제는 항상 일반(`standard`) 문제다.
struct QuestionDraft: Equatable {
    /// 보기 개수. 항상 4개다.
    static let choiceCount = 4

    var text = ""
    /// 앱 내부 폴더에 복사한 이미지의 파일명
    var imageFileName: String?
    /// 앱 내부 폴더에 복사한 영상의 파일명
    var videoFileName: String?
    var choices = Array(repeating: "", count: QuestionDraft.choiceCount)
    /// 0...3
    var correctIndex = 0
    var explanation = ""
    var hint = ""
    var resourceTitle = ""
    var resourceURL = ""
    var category: QuizCategory = .swiftSyntax
    var difficulty: Difficulty = .normal
    /// 쉼표 또는 줄바꿈으로 구분한 태그 입력
    var tagsText = ""

    /// 새 문제용 빈 입력값
    init() {}

    /// 기존 문제의 값을 편집용 입력값으로 옮긴다.
    init(_ question: Question) {
        text = question.text
        imageFileName = question.imageFileName
        videoFileName = question.videoFileName
        var padded = Array(question.choices.prefix(Self.choiceCount))
        while padded.count < Self.choiceCount { padded.append("") }
        choices = padded
        correctIndex = min(max(question.correctIndex, 0), Self.choiceCount - 1)
        explanation = question.explanation
        hint = question.hint ?? ""
        resourceTitle = question.resourceTitle ?? ""
        resourceURL = question.resourceURL ?? ""
        category = question.category
        difficulty = question.difficulty
        tagsText = question.tags.joined(separator: ", ")
    }

    /// 저장을 막는 문제
    enum Issue: Hashable {
        /// 문제 내용이 비어 있음
        case textEmpty
        /// 보기 4개가 모두 채워지지 않음
        case choicesIncomplete
        /// 학습 자료 주소가 http/https 주소가 아님
        case resourceURLInvalid
        /// 같은 문제 안에서 같은 보기가 두 번 이상 있음
        case duplicateChoices
        /// 해설이 비어 있음. 비어 있으면 퀴즈 피드백 카드에 빈 칸이 보이므로 저장할 수 없다.
        case explanationEmpty
    }

    /// 지금 입력값에서 저장을 막는 문제들. 비어 있으면 저장할 수 있다.
    var issues: Set<Issue> {
        var result: Set<Issue> = []
        if Self.trimmed(text).isEmpty { result.insert(.textEmpty) }
        if choices.count != Self.choiceCount || choices.contains(where: { Self.trimmed($0).isEmpty }) {
            result.insert(.choicesIncomplete)
        }
        if !isResourceURLValid { result.insert(.resourceURLInvalid) }
        if !duplicateChoiceIndices.isEmpty { result.insert(.duplicateChoices) }
        if Self.trimmed(explanation).isEmpty { result.insert(.explanationEmpty) }
        return result
    }

    /// 같은 내용으로 취급되는 보기의 위치. 공백만 다른 보기도 같은 것으로 본다. 비어 있는 보기는 세지 않는다.
    var duplicateChoiceIndices: Set<Int> {
        var positions: [String: [Int]] = [:]
        for (index, choice) in choices.enumerated() {
            let key = Self.normalizedKey(choice)
            if !key.isEmpty { positions[key, default: []].append(index) }
        }
        return Set(positions.values.filter { $0.count > 1 }.flatMap { $0 })
    }

    /// 저장할 수 있는 입력값인지
    var isValid: Bool { issues.isEmpty }

    /// 학습 자료 주소가 비어 있거나 http/https 주소인지
    var isResourceURLValid: Bool {
        let value = Self.trimmed(resourceURL)
        if value.isEmpty { return true }
        guard let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host, !host.isEmpty
        else { return false }
        return true
    }

    /// 입력한 태그. 앞뒤 공백을 지우고 빈 값과 중복을 뺀다.
    var tags: [String] {
        var seen = Set<String>()
        return tagsText
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { Self.trimmed($0) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    /// 같은 문자열인지 비교할 때 쓰는 값. 공백, 탭, 줄바꿈을 모두 지우고, 영문 대소문자를 구분하지 않으며, 글자 조합 방식을 통일한다.
    /// 예: "아아아", "아아아  ", "아 아 아"는 모두 같은 값이고, "Swift", "SWIFT", "swift"도 모두 같은 값이다.
    static func normalizedKey(_ value: String) -> String {
        value.precomposedStringWithCanonicalMapping
            .lowercased()
            .filter { !$0.isWhitespace }
    }

    /// 앞뒤 공백과 줄바꿈을 지운 문자열
    static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 비어 있으면 nil, 아니면 앞뒤 공백을 지운 문자열
    static func nilIfEmpty(_ value: String) -> String? {
        let result = trimmed(value)
        return result.isEmpty ? nil : result
    }
}
