import SwiftUI

/// 오답의 풀 당시 내용과 내 선택·정답·해설을 보여 주는 읽기 전용 화면.
struct QuizReviewDetailView: View {
    let question: QuizReviewQuestion
    let difficulty: Difficulty
    /// 목록으로 돌아가는 동작과 별도로 복습 시트 전체를 닫는다.
    let onClose: () -> Void
    @Environment(\.services) private var services

    private var snapshot: QuestionSnapshot { question.snapshot }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("\(snapshot.category.categoryName) · \(difficulty.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(Color.roomSecondaryText)
                Text(snapshot.text)
                    .font(.headline)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .roomCardBackground()

                if let fileName = nonEmpty(snapshot.imageFileName) {
                    QuizQuestionImage(url: mediaURL(fileName)).roomCardBackground()
                }
                if let fileName = nonEmpty(snapshot.videoFileName) {
                    QuizQuestionVideo(url: mediaURL(fileName), isActive: true).roomCardBackground()
                }
                if let code = nonEmpty(snapshot.codeSnippet) { QuizCodeView(code: code) }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(snapshot.choices.enumerated()), id: \.offset) { index, choice in
                        choiceRow(index: index, text: choice)
                    }
                    if !snapshot.choices.indices.contains(question.selectedIndex) {
                        Text("선택한 보기를 확인할 수 없어요")
                            .font(.callout)
                            .foregroundStyle(Color.roomSecondaryText)
                    }
                }
                .roomCardBackground()

                textCard(title: "해설", text: snapshot.explanation)
                if let hint = nonEmpty(snapshot.hint) { textCard(title: "힌트", text: hint) }
                if let resource = QuizReviewResource.from(snapshot) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("학습 자료").font(.subheadline.bold())
                        Link(destination: resource.url) {
                            Label(resource.title, systemImage: "arrow.up.right.square")
                                .foregroundStyle(Color.roomAccent)
                        }
                        .accessibilityHint("외부 브라우저에서 학습 자료를 엽니다")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .roomCardBackground()
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.roomPrimaryText)
        .background(Color.roomBackground)
        .navigationTitle("\(question.number)번 문제")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("닫기", action: onClose)
            }
        }
    }

    private func choiceRow(index: Int, text: String) -> some View {
        let isCorrect = index == snapshot.correctIndex
        let isSelected = index == question.selectedIndex
        let label = ["A", "B", "C", "D"][safe: index] ?? String(index + 1)
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : isSelected ? "xmark.circle.fill" : "circle")
                .foregroundStyle(isCorrect ? Color.roomPositive : isSelected ? Color.roomNegative : Color.roomSecondaryText)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(label). \(text)")
                if isSelected { Text("내 선택").font(.caption.bold()).foregroundStyle(Color.roomNegative) }
                if isCorrect { Text("정답").font(.caption.bold()).foregroundStyle(Color.roomPositive) }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private func textCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.bold())
            Text(text).textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .roomCardBackground()
    }

    private func nonEmpty(_ value: String?) -> String? {
        value.flatMap { QuestionDraft.nilIfEmpty($0) }
    }

    private func mediaURL(_ fileName: String) -> URL? {
        (services.media as? MediaURLProviding)?.url(for: fileName)
    }
}
