import ImageIO
import SwiftUI
import UIKit

/// 세션 스냅샷이 참조하는 로컬 이미지를 원본 비율과 색상으로 표시한다.
struct QuizQuestionImage: View {
    /// 미디어 저장소에서 구한 파일 위치. 조회할 수 없으면 안내를 표시한다.
    let url: URL?

    @Environment(\.colorScheme) private var colorScheme
    @State private var image: UIImage?
    @State private var isLoading = true

    private var palette: QuizPalette { QuizPalette(colorScheme: colorScheme) }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 420)
                    .accessibilityLabel("문제에 첨부된 이미지")
            } else if isLoading {
                ProgressView("이미지를 불러오고 있어요")
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
            } else {
                Label("이미지를 불러오지 못했어요", systemImage: "photo.badge.exclamationmark")
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            }
        }
        .foregroundStyle(palette.secondaryText)
        .task(id: url) { await loadImage() }
    }

    /// 큰 원본은 백그라운드에서 표시 크기로 줄여 읽고, 이전 문항의 결과는 반영하지 않는다.
    private func loadImage() async {
        image = nil
        isLoading = true
        guard let url else {
            isLoading = false
            return
        }
        let loaded = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let source = CGImageSourceCreateWithURL(
                url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary
            ) else { return nil }
            // 풀이 본문 최대 폭 640pt의 3배 해상도까지만 준비한다. 원본 파일은 변경하지 않는다.
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1920,
                kCGImageSourceShouldCacheImmediately: true
            ]
            guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                return nil
            }
            return UIImage(cgImage: thumbnail)
        }.value
        guard !Task.isCancelled else { return }
        image = loaded
        isLoading = false
    }
}

#if DEBUG
/// 기존 지도 자산을 프리뷰 전용 임시 파일로 만들어 실제 로컬 이미지 읽기를 확인한다.
func quizImagePreviewURL() -> URL? {
    guard let data = UIImage(named: "SantaVillageMap")?.pngData() else { return nil }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("quiz-question-image-preview.png")
    do {
        try data.write(to: url, options: .atomic)
        return url
    } catch {
        return nil
    }
}

#Preview("첨부 이미지 · 라이트") {
    QuizQuestionImage(url: quizImagePreviewURL())
        .padding()
        .background(Color.nightCardBackground)
        .preferredColorScheme(.light)
}

#Preview("첨부 이미지 · 다크") {
    QuizQuestionImage(url: quizImagePreviewURL())
        .padding()
        .background(Color.nightCardBackground)
        .preferredColorScheme(.dark)
}

#Preview("첨부 이미지 · 파일 없음 · 큰 글자") {
    QuizQuestionImage(url: FileManager.default.temporaryDirectory.appendingPathComponent("quiz-image-missing.png"))
        .padding()
        .background(Color.nightCardBackground)
        .dynamicTypeSize(.accessibility3)
}
#endif
