import Foundation
import SwiftData

/// 사용자 미디어 파일을 앱 내부 폴더에 저장하고, 참조되지 않는 파일을 정리한다.
/// 파일은 불변으로 다룬다. 항상 새 파일명으로 저장하고 기존 파일을 덮어쓰지 않는다.
final class MediaFileManager: MediaFileManaging {
    private let context: ModelContext
    private let fileManager: FileManager
    private let directory: URL

    /// - Parameters:
    ///   - context: 참조 여부를 조회할 ModelContext
    ///   - directory: 미디어 저장 폴더. nil이면 Application Support 아래 `Media`
    init(context: ModelContext, fileManager: FileManager = .default, directory: URL? = nil) {
        self.context = context
        self.fileManager = fileManager
        self.directory = directory ?? fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Media", isDirectory: true)
            ?? fileManager.temporaryDirectory.appendingPathComponent("Media", isDirectory: true)
    }

    /// 파일명으로 저장된 미디어의 전체 경로
    func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    func store(from url: URL) throws -> String {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let ext = url.pathExtension
        let name = ext.isEmpty ? UUID().uuidString : "\(UUID().uuidString).\(ext)"
        try fileManager.copyItem(at: url, to: directory.appendingPathComponent(name))
        return name
    }

    func cleanUnreferencedFiles() throws {
        guard fileManager.fileExists(atPath: directory.path) else { return }

        let questions = try context.fetch(FetchDescriptor<Question>())
        let sessions = try context.fetch(FetchDescriptor<QuizSession>())
        let existingQuestionIDs = Set(questions.map(\.id))

        var referenced = Set<String>()
        for question in questions {
            referenced.formUnion([question.imageFileName, question.videoFileName].compactMap { $0 })
        }
        for session in sessions {
            // 진행 중 세션은 항상 보존. 끝난 세션은 원본 문제가 남아 있을 때만 보존
            for snapshot in session.questionSnapshots {
                let keep = session.status == .inProgress || existingQuestionIDs.contains(snapshot.questionID)
                if keep {
                    referenced.formUnion([snapshot.imageFileName, snapshot.videoFileName].compactMap { $0 })
                }
            }
        }

        let files = try fileManager.contentsOfDirectory(atPath: directory.path)
        for file in files where !referenced.contains(file) {
            try fileManager.removeItem(at: directory.appendingPathComponent(file))
        }
    }
}
