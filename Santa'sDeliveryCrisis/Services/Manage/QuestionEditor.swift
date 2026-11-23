import Foundation
import SwiftData

/// 문제 편집기에서 생길 수 있는 오류
enum QuestionEditorError: Error {
    /// 저장할 수 없는 입력값(필수 항목 누락 등)
    case invalidDraft
    /// 기본(시드) 문제는 고치거나 지울 수 없다.
    case seedQuestion
    /// 애니메이션 문제는 고치거나 지울 수 없다.
    case animationQuestion
    /// 같은 문제가 이미 있다. 공백만 다른 문제도 같은 문제로 본다.
    case duplicateText
}

/// 사용자가 만드는 문제의 저장, 수정, 삭제를 맡는다.
/// 수정은 기존 `Question` 객체의 값만 바꾸므로 `id`가 유지되어 풀이 기록과 오답 노트가 끊기지 않는다.
/// 저장이나 삭제 뒤에는 쓰이지 않는 이미지·영상 파일을 `MediaFileManaging.cleanUnreferencedFiles()`로 정리한다.
final class QuestionEditor {
    private let context: ModelContext
    private let media: MediaFileManaging

    /// - Parameters:
    ///   - context: 문제를 저장할 ModelContext
    ///   - media: 미디어 파일 저장과 정리를 맡는 서비스
    init(context: ModelContext, media: MediaFileManaging) {
        self.context = context
        self.media = media
    }

    /// 입력값으로 새 문제를 만들어 저장한다.
    /// - Throws: 입력값이 올바르지 않으면 `invalidDraft`, 같은 문제가 이미 있으면 `duplicateText`, 저장에 실패하면 저장 오류
    @discardableResult
    func create(_ draft: QuestionDraft) throws -> Question {
        guard draft.isValid else { throw QuestionEditorError.invalidDraft }
        if try hasDuplicateText(draft.text, excluding: nil) { throw QuestionEditorError.duplicateText }
        let question = Question(
            text: QuestionDraft.trimmed(draft.text),
            imageFileName: draft.imageFileName,
            videoFileName: draft.videoFileName,
            choices: draft.choices.map { QuestionDraft.trimmed($0) },
            correctIndex: draft.correctIndex,
            explanation: QuestionDraft.trimmed(draft.explanation),
            hint: QuestionDraft.nilIfEmpty(draft.hint),
            resourceTitle: QuestionDraft.nilIfEmpty(draft.resourceTitle),
            resourceURL: QuestionDraft.nilIfEmpty(draft.resourceURL),
            category: draft.category,
            difficulty: draft.difficulty,
            tags: draft.tags,
            isSeed: false
        )
        context.insert(question)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        cleanUpFiles()
        return question
    }

    /// 기존 문제를 입력값으로 고친다. `id`는 그대로 둔다.
    /// - Throws: 기본(시드)·애니메이션 문제이면 `seedQuestion`·`animationQuestion`, 입력값이 올바르지 않으면 `invalidDraft`,
    ///   바꾼 문제 내용이 다른 문제와 같으면 `duplicateText`, 저장에 실패하면 저장 오류
    func update(_ question: Question, with draft: QuestionDraft) throws {
        try ensureEditable(question)
        guard draft.isValid else { throw QuestionEditorError.invalidDraft }
        // 문제 내용을 바꾸지 않았다면 다른 항목만 고치는 것이므로 중복을 따지지 않는다.
        let isTextChanged = QuestionDraft.normalizedKey(draft.text) != QuestionDraft.normalizedKey(question.text)
        if isTextChanged, try hasDuplicateText(draft.text, excluding: question.id) {
            throw QuestionEditorError.duplicateText
        }
        question.text = QuestionDraft.trimmed(draft.text)
        question.imageFileName = draft.imageFileName
        question.videoFileName = draft.videoFileName
        question.choices = draft.choices.map { QuestionDraft.trimmed($0) }
        question.correctIndex = draft.correctIndex
        question.explanation = QuestionDraft.trimmed(draft.explanation)
        question.hint = QuestionDraft.nilIfEmpty(draft.hint)
        question.resourceTitle = QuestionDraft.nilIfEmpty(draft.resourceTitle)
        question.resourceURL = QuestionDraft.nilIfEmpty(draft.resourceURL)
        question.category = draft.category
        question.difficulty = draft.difficulty
        question.tags = draft.tags
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        cleanUpFiles()
    }

    /// 문제를 지운다. 새 출제 대상과 오답 노트에서 빠진다.
    /// 진행 중 세션은 시작할 때 복사해 둔 내용으로 이어 풀 수 있고, 이미 확정된 점수는 바뀌지 않는다.
    /// - Throws: 기본(시드)·애니메이션 문제이면 지우지 않고 `seedQuestion`·`animationQuestion`, 저장에 실패하면 저장 오류
    func delete(_ question: Question) throws {
        try ensureEditable(question)
        context.delete(question)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        cleanUpFiles()
    }

    /// 편집을 저장하지 않고 닫을 때, 그 사이 새로 복사한 이미지·영상 파일을 정리한다.
    func discardUnsavedMedia() {
        cleanUpFiles()
    }

    /// 같은 문제가 이미 있는지. 공백만 다른 문제도 같은 것으로 본다. 기본 문제와 애니메이션 문제도 비교 대상이다.
    /// - Parameters:
    ///   - text: 비교할 문제 내용
    ///   - id: 비교에서 뺄 문제의 id(고치는 중인 문제 자신)
    private func hasDuplicateText(_ text: String, excluding id: UUID?) throws -> Bool {
        let key = QuestionDraft.normalizedKey(text)
        let questions = try context.fetch(FetchDescriptor<Question>())
        return questions.contains { $0.id != id && QuestionDraft.normalizedKey($0.text) == key }
    }

    /// 화면에서 버튼을 막는 것과 별개로, 시드·애니메이션 문제를 건드리지 못하게 한 번 더 막는다.
    /// 조용히 무시하지 않고 오류를 던져 호출한 쪽이 알 수 있게 한다.
    private func ensureEditable(_ question: Question) throws {
        if question.isSeed { throw QuestionEditorError.seedQuestion }
        if question.kind == .animation { throw QuestionEditorError.animationQuestion }
    }

    /// 파일 정리에 실패해도 문제 데이터는 이미 저장된 상태라 오류를 던지지 않는다.
    /// 남은 파일은 다음 정리 때(문제 삭제, 미디어 교체, 세션 종료, 앱 시작) 지워진다.
    private func cleanUpFiles() {
        try? media.cleanUnreferencedFiles()
    }
}

/// 파일명으로 저장된 미디어의 전체 경로를 알려 주는 능력. 편집 화면의 미리보기에 쓴다.
protocol MediaURLProviding {
    /// 파일명에 해당하는 전체 경로
    func url(for fileName: String) -> URL
}

/// `MediaFileManager`는 이미 `url(for:)`를 가지고 있어서 선언만 덧붙인다. 공통 프로토콜은 바꾸지 않는다.
extension MediaFileManager: MediaURLProviding {}
