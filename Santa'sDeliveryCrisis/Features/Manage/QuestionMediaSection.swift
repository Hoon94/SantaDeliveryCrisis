import PhotosUI
import SwiftUI

/// 사진 보관함에서 고른 파일. 앱이 받은 임시 복사본의 경로를 담는다.
private struct PickedMediaFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .item) { received in
            // 받은 파일은 이 클로저가 끝나면 사라지므로 임시 폴더로 옮겨 둔다.
            let ext = received.file.pathExtension
            let name = ext.isEmpty ? UUID().uuidString : "\(UUID().uuidString).\(ext)"
            let copy = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            try FileManager.default.copyItem(at: received.file, to: copy)
            return PickedMediaFile(url: copy)
        }
    }
}

/// 문제 편집 화면의 이미지·영상 추가 영역(S11).
/// 사진 보관함에서 고른 파일을 앱 내부 폴더에 복사해 파일명만 입력값에 저장한다. 용량 제한은 없다.
struct QuestionMediaSection: View {
    @Binding var draft: QuestionDraft
    @Environment(\.services) private var services

    @State private var imageItem: PhotosPickerItem?
    @State private var videoItem: PhotosPickerItem?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { pickers }
                VStack(spacing: 8) { pickers }
            }
            if let imageFileName = draft.imageFileName {
                mediaPreview(title: "선택한 이미지", systemImage: "photo") {
                    imageThumbnail(for: imageFileName)
                } onRemove: {
                    draft.imageFileName = nil
                }
            }
            if draft.videoFileName != nil {
                // 큰 영상은 미리 불러오지 않는다. 선택했다는 표시만 한다.
                mediaPreview(title: "선택한 영상", systemImage: "film") {
                    Image(systemName: "film")
                        .font(.title)
                        .foregroundStyle(Color.roomSub)
                } onRemove: {
                    draft.videoFileName = nil
                }
            }
        }
        .onChange(of: imageItem) { _, item in load(item, kind: .image) }
        .onChange(of: videoItem) { _, item in load(item, kind: .video) }
        .alert("파일을 가져오지 못했어요", isPresented: isErrorPresented) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - 선택 버튼

    @ViewBuilder
    private var pickers: some View {
        PhotosPicker(selection: $imageItem, matching: .images) {
            pickerLabel("🖼 이미지 추가")
        }
        .accessibilityLabel("이미지 추가")
        PhotosPicker(selection: $videoItem, matching: .videos) {
            pickerLabel("🎞 영상 추가")
        }
        .accessibilityLabel("영상 추가")
    }

    private func pickerLabel(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(Color.roomText)
            .frame(maxWidth: .infinity, minHeight: 44)
            .roomCard(padding: EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
    }

    // MARK: - 미리보기

    private func mediaPreview<Thumbnail: View>(
        title: String,
        systemImage: String,
        @ViewBuilder thumbnail: () -> Thumbnail,
        onRemove: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            thumbnail()
                .frame(width: 64, height: 64)
                .background(Color.roomSoft, in: RoundedRectangle(cornerRadius: 10))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            Text(title)
                .font(.footnote)
                .foregroundStyle(Color.roomSub)
            Spacer()
            Button(action: onRemove) {
                Label("삭제", systemImage: "xmark")
                    .font(.footnote.bold())
                    .foregroundStyle(Color.roomBad)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title) 삭제")
        }
        .roomCard()
    }

    @ViewBuilder
    private func imageThumbnail(for fileName: String) -> some View {
        if let provider = services.media as? MediaURLProviding {
            AsyncImage(url: provider.url(for: fileName)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "photo").foregroundStyle(Color.roomSub)
            }
        } else {
            Image(systemName: "photo").font(.title).foregroundStyle(Color.roomSub)
        }
    }

    // MARK: - 불러오기

    private enum Kind { case image, video }

    private func load(_ item: PhotosPickerItem?, kind: Kind) {
        guard let item else { return }
        Task {
            do {
                guard let picked = try await item.loadTransferable(type: PickedMediaFile.self) else {
                    throw CocoaError(.fileReadUnknown)
                }
                defer { try? FileManager.default.removeItem(at: picked.url) }
                let fileName = try services.media.store(from: picked.url)
                switch kind {
                case .image: draft.imageFileName = fileName
                case .video: draft.videoFileName = fileName
                }
            } catch {
                errorMessage = "다른 파일을 선택하거나 잠시 후 다시 시도해 주세요."
            }
            // 같은 파일을 다시 고를 수 있도록 선택 상태를 비운다.
            switch kind {
            case .image: imageItem = nil
            case .video: videoItem = nil
            }
        }
    }

    private var isErrorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }
}
