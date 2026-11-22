import SwiftData
import SwiftUI

/// 이번 세션의 오답 복습 시트. 삭제된 문제는 목록과 추천 자료에서 제외한다.
struct QuizReviewView: View {
    let summary: QuizResultSummary
    @Query private var questions: [Question]
    @Environment(\.dismiss) private var dismiss

    private var content: QuizReviewContent {
        QuizReviewContent(summary: summary, existingQuestionIDs: Set(questions.map(\.id)))
    }

    var body: some View {
        let review = content
        NavigationStack {
            Group {
                if review.questions.isEmpty {
                    ContentUnavailableView {
                        Label("복습할 오답이 없어요", systemImage: "checkmark.circle")
                    } description: {
                        Text(summary.result.wrongAnswers.isEmpty ? "이번 세션의 모든 문제를 맞혔어요." : "삭제된 문제는 복습 목록에서 제외해요.")
                    } actions: {
                        Button("닫기") { dismiss() }
                    }
                } else {
                    List {
                        Section {
                            ForEach(review.questions) { question in
                                NavigationLink(value: question.id) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("\(question.number)번 문제 · \(question.snapshot.category.categoryName)")
                                            .font(.caption)
                                            .foregroundStyle(Color.roomSecondaryText)
                                        Text(question.snapshot.text)
                                            .font(.body)
                                            .lineLimit(2)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .listRowBackground(Color.roomCardBackground)
                        } header: {
                            Text("오답 노트 · \(review.questions.count)개")
                        } footer: {
                            if review.deletedCount > 0 {
                                Text("삭제된 문제 \(review.deletedCount)개는 표시하지 않아요. 세션 점수와 오답 수는 그대로예요.")
                            }
                        }
                        Section("추천 학습 자료") {
                            if review.resources.isEmpty {
                                Text("등록된 학습 자료가 없어요")
                                    .foregroundStyle(Color.roomSecondaryText)
                            } else {
                                ForEach(review.resources) { resource in
                                    Link(destination: resource.url) {
                                        Label(resource.title, systemImage: "arrow.up.right.square")
                                            .fixedSize(horizontal: false, vertical: true)
                                            .foregroundStyle(Color.roomAccent)
                                    }
                                    .accessibilityHint("외부 브라우저에서 학습 자료를 엽니다")
                                }
                            }
                        }
                        .listRowBackground(Color.roomCardBackground)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .foregroundStyle(Color.roomPrimaryText)
            .background(Color.roomBackground)
            .navigationTitle("오답 복습")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let question = review.questions.first(where: { $0.id == id }) {
                    QuizReviewDetailView(question: question, difficulty: summary.difficulty, onClose: { dismiss() })
                } else {
                    ContentUnavailableView("문제를 찾을 수 없어요", systemImage: "doc.questionmark",
                                           description: Text("삭제된 문제는 복습 목록에서 제외해요."))
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("닫기") { dismiss() }
                            }
                        }
                }
            }
        }
        .tint(.primary)
    }
}

#if DEBUG
/// 실제 저장소와 분리해 삭제된 문제·중복 자료·첨부 이미지·결과 진입을 확인한다.
@ViewBuilder
private func quizReviewPreview(
    deletedCount: Int = 0, hasResources: Bool = true, includesMedia: Bool = false, showsResult: Bool = false
) -> some View {
    if let container = try? ModelContainerFactory.make(inMemory: true) {
        let preview = makeQuizReviewPreview(
            container: container, deletedCount: deletedCount, hasResources: hasResources, includesMedia: includesMedia
        )
        Group {
            if showsResult {
                QuizResultView(summary: preview.summary, services: preview.services, onClose: {})
            } else {
                QuizReviewView(summary: preview.summary)
            }
        }
        .modelContainer(container)
        .environment(\.services, preview.services)
    } else {
        ContentUnavailableView("복습 프리뷰를 준비하지 못했어요", systemImage: "doc.questionmark")
    }
}

/// 프리뷰 데이터 변경과 모델 삽입은 ViewBuilder 밖에서 준비한다.
private func makeQuizReviewPreview(
    container: ModelContainer, deletedCount: Int, hasResources: Bool, includesMedia: Bool
) -> (summary: QuizResultSummary, services: AppServices) {
    let questions = QuizResultSummary.previewQuestions()
    let imageURL = includesMedia ? quizImagePreviewURL() : nil
    if includesMedia {
        questions[1].imageFileName = imageURL?.lastPathComponent
        questions[3].videoFileName = "quiz-review-missing-video.mov"
    }
    if !hasResources {
        questions[1].resourceURL = nil
        questions[3].resourceURL = "ftp://example.com/unsupported"
    }
    questions[1].resourceTitle = nil
    let base = QuizResultSummary.previewFailure
    let summary = QuizResultSummary(
        result: base.result, task: base.task, category: base.category, difficulty: base.difficulty,
        thresholdPercent: base.thresholdPercent, treeRewardMask: base.treeRewardMask,
        questionSnapshots: questions.map { QuestionSnapshot($0) }
    )
    // 원본을 수정해도 복습에는 위에서 복사한 문제 내용이 그대로 보인다.
    questions[1].text = "수정된 원본 문제"
    let removed = Set(base.result.wrongAnswers.prefix(deletedCount).map(\.questionID))
    for question in questions where !removed.contains(question.id) {
        container.mainContext.insert(question)
    }
    let source = AppServices.preview
    let services = AppServices(
        settings: source.settings, selector: source.selector, recommender: source.recommender,
        sessions: source.sessions, trees: source.trees, feedback: source.feedback,
        media: MediaFileManager(
            context: container.mainContext,
            directory: imageURL?.deletingLastPathComponent() ?? FileManager.default.temporaryDirectory
        ),
        reminders: source.reminders
    )
    return (summary, services)
}

#Preview("오답 복습 · 결과에서 열기") { quizReviewPreview(showsResult: true) }
#Preview("오답 복습 · 중복 자료와 제목 없음 · 라이트") { quizReviewPreview().preferredColorScheme(.light) }
#Preview("오답 복습 · 자료 없음과 잘못된 주소 · 다크") { quizReviewPreview(hasResources: false).preferredColorScheme(.dark) }
#Preview("오답 복습 · 문제 한 개 삭제") { quizReviewPreview(deletedCount: 1) }
#Preview("오답 복습 · 모두 삭제됨") { quizReviewPreview(deletedCount: 2) }
#Preview("오답 복습 · 이미지와 영상 누락") { quizReviewPreview(includesMedia: true) }
#Preview("오답 복습 · 큰 글자") { quizReviewPreview().dynamicTypeSize(.accessibility3) }
#Preview("오답 복습 · 전부 정답") {
    if let container = try? ModelContainerFactory.make(inMemory: true) {
        QuizReviewView(summary: .previewTreeComplete).modelContainer(container)
    }
}
#endif
