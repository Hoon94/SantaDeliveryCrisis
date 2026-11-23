import Foundation
import SwiftData

/// 시드 JSON 한 문제의 모양. 필드 이름은 `Question` 모델과 같다.
nonisolated struct SeedQuestion: Codable, Sendable {
    let id: UUID
    let kind: QuestionKind
    let text: String
    let codeSnippet: String?
    let imageFileName: String?
    let videoFileName: String?
    let choices: [String]
    let correctIndex: Int
    let explanation: String
    let hint: String?
    let resourceTitle: String?
    let resourceURL: String?
    let category: QuizCategory
    let difficulty: Difficulty
    let tags: [String]
    let animationID: String?
    let createdAt: Date
}

/// 시드 데이터를 읽거나 넣는 중 생기는 오류
nonisolated enum SeedLoadError: Error, LocalizedError, Equatable {
    /// 번들에서 JSON 파일을 찾지 못함
    case fileNotFound(String)
    /// JSON 형식이 모델과 맞지 않음 (없는 필드, 알 수 없는 카테고리 등)
    case decodingFailed(String)
    /// 내용 검증 실패. 문제가 된 항목을 모두 모아서 담는다.
    case validationFailed([String])

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            "시드 파일을 찾지 못했습니다: \(name)"
        case .decodingFailed(let detail):
            "시드 JSON을 읽지 못했습니다: \(detail)"
        case .validationFailed(let issues):
            "시드 데이터 검증에 실패했습니다 (\(issues.count)건): " + issues.joined(separator: " / ")
        }
    }
}

/// 앱 번들의 시드 JSON(`Seed/questions.json`)을 읽고, 검증하고, SwiftData에 처음 넣는다.
///
/// 흐름: `load` → `validate` → `inject`. 한 번에 하려면 `seed(into:)`를 쓴다.
/// 같은 `id`의 문제가 이미 저장소에 있으면 건너뛰므로 여러 번 실행해도 결과가 같다(멱등).
enum SeedLoader {
    /// 문제의 보기 개수. 공통 계약에서 항상 4개다.
    nonisolated static let choiceCount = 4

    // MARK: - 읽기

    /// JSON 데이터를 시드 문제 목록으로 바꾼다. `createdAt`은 ISO 8601 날짜 문자열이다.
    nonisolated static func decode(_ data: Data) throws -> [SeedQuestion] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode([SeedQuestion].self, from: data)
        } catch {
            throw SeedLoadError.decodingFailed(String(describing: error))
        }
    }

    /// 번들에서 시드 JSON을 찾아 읽는다.
    /// Xcode가 폴더 구조를 유지하든 평평하게 복사하든 찾을 수 있게 몇 가지 위치를 차례로 확인한다.
    /// - Parameters:
    ///   - bundle: 파일이 들어 있는 번들. 테스트에서는 테스트 번들을 넘긴다.
    ///   - name: 확장자를 뺀 파일 이름
    nonisolated static func load(from bundle: Bundle = .main, name: String = "questions") throws -> [SeedQuestion] {
        let candidates: [String?] = [nil, "Seed", "Resources/Seed"]
        for subdirectory in candidates {
            if let url = bundle.url(forResource: name, withExtension: "json", subdirectory: subdirectory) {
                do {
                    return try decode(Data(contentsOf: url))
                } catch let error as SeedLoadError {
                    throw error
                } catch {
                    throw SeedLoadError.decodingFailed(error.localizedDescription)
                }
            }
        }
        throw SeedLoadError.fileNotFound("\(name).json")
    }

    // MARK: - 검증

    /// 시드 문제 목록의 문제점을 모두 찾아 돌려준다. 문제가 없으면 빈 배열이다.
    /// 검사 항목: id 중복, 빈 문제·해설, 보기 개수(4개)와 빈 보기·같은 보기, 정답 번호 범위(0...3),
    /// 빈 태그, 자료 URL 형식(http/https), 애니메이션 문제의 `animationID` 누락
    nonisolated static func validate(_ items: [SeedQuestion]) -> [String] {
        var issues: [String] = []
        var seenIDs = Set<UUID>()

        for (offset, item) in items.enumerated() {
            let label = "#\(offset + 1) (\(item.id.uuidString))"

            if !seenIDs.insert(item.id).inserted {
                issues.append("\(label): id가 중복됩니다")
            }
            if item.text.isBlank {
                issues.append("\(label): 문제 내용이 비어 있습니다")
            }
            if item.explanation.isBlank {
                issues.append("\(label): 해설이 비어 있습니다")
            }
            if item.choices.count != choiceCount {
                issues.append("\(label): 보기가 \(item.choices.count)개입니다 (\(choiceCount)개여야 함)")
            } else if item.choices.contains(where: \.isBlank) {
                issues.append("\(label): 비어 있는 보기가 있습니다")
            } else if Set(item.choices.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }).count != choiceCount {
                issues.append("\(label): 같은 내용의 보기가 있습니다")
            }
            if item.tags.contains(where: \.isBlank) {
                issues.append("\(label): 비어 있는 태그가 있습니다")
            }
            if let urlString = item.resourceURL, !urlString.isBlank, !urlString.isWebURL {
                issues.append("\(label): 자료 URL이 http/https 형식이 아닙니다 (\(urlString))")
            }
            if !(0..<choiceCount).contains(item.correctIndex) {
                issues.append("\(label): 정답 번호 \(item.correctIndex)이(가) 범위(0...\(choiceCount - 1))를 벗어났습니다")
            }
            if item.kind == .animation, item.animationID?.isBlank ?? true {
                issues.append("\(label): 애니메이션 문제인데 animationID가 없습니다")
            }
        }
        return issues
    }

    // MARK: - 분량 점검

    /// 카테고리와 난이도 조합마다 문제가 최소 `minimum`개인지 점검한다. 부족한 조합을 설명하는 문장 목록을 돌려준다.
    /// 앱 실행을 막는 검증이 아니라 시드 통합 때 팀이 분량을 확인하는 용도이다(스펙 기준: 조합당 5문제 이상).
    nonisolated static func coverageShortfalls(_ items: [SeedQuestion], minimum: Int = 5) -> [String] {
        var shortfalls: [String] = []
        for category in QuizCategory.allCases {
            for difficulty in Difficulty.allCases {
                let count = items.filter { $0.category == category && $0.difficulty == difficulty }.count
                if count < minimum {
                    shortfalls.append("\(category.categoryName) / \(difficulty.displayName): \(count)개 (최소 \(minimum)개)")
                }
            }
        }
        return shortfalls
    }

    // MARK: - 주입

    /// 시드 문제를 저장소에 넣는다. 같은 `id`가 이미 있으면 건너뛴다.
    /// 검증을 통과하지 못하면 아무것도 넣지 않고 `SeedLoadError.validationFailed`를 던진다.
    /// 넣을 문제가 있을 때만 저장(save)을 한 번 호출한다.
    /// - Returns: 새로 넣은 문제 수
    @MainActor
    @discardableResult
    static func inject(_ items: [SeedQuestion], into context: ModelContext) throws -> Int {
        let issues = validate(items)
        guard issues.isEmpty else { throw SeedLoadError.validationFailed(issues) }

        let existingIDs = Set(try context.fetch(FetchDescriptor<Question>()).map(\.id))
        var inserted = 0
        for item in items where !existingIDs.contains(item.id) {
            context.insert(makeQuestion(from: item))
            inserted += 1
        }
        if inserted > 0 {
            try context.save()
        }
        return inserted
    }

    /// 번들에서 읽고 검증한 뒤 저장소에 넣는다. 앱 시작 때 호출하는 진입점이다.
    /// - Returns: 새로 넣은 문제 수 (이미 다 들어 있으면 0)
    @MainActor
    @discardableResult
    static func seed(into context: ModelContext, from bundle: Bundle = .main) throws -> Int {
        try inject(try load(from: bundle), into: context)
    }

    // MARK: - 변환

    /// 시드 문제를 `Question` 모델로 바꾼다. 시드에서 온 문제이므로 `isSeed`는 항상 true다.
    @MainActor
    static func makeQuestion(from item: SeedQuestion) -> Question {
        Question(
            id: item.id,
            kind: item.kind,
            text: item.text,
            codeSnippet: item.codeSnippet,
            imageFileName: item.imageFileName,
            videoFileName: item.videoFileName,
            choices: item.choices,
            correctIndex: item.correctIndex,
            explanation: item.explanation,
            hint: item.hint,
            resourceTitle: item.resourceTitle,
            resourceURL: item.resourceURL,
            category: item.category,
            difficulty: item.difficulty,
            tags: item.tags,
            animationID: item.animationID,
            isSeed: true,
            createdAt: item.createdAt
        )
    }
}

private extension String {
    /// http 또는 https 주소로 읽히는가
    nonisolated var isWebURL: Bool {
        guard let url = URL(string: trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(), url.host != nil else { return false }
        return scheme == "http" || scheme == "https"
    }

    /// 공백과 줄바꿈만 있거나 비어 있는가
    nonisolated var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
