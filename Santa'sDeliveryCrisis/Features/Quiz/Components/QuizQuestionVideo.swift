import AVFoundation
import AVKit
import Combine
import Foundation
import SwiftUI

/// 첨부 영상은 재생 버튼을 누른 뒤에만 불러오고, 풀이를 멈추면 함께 일시 정지한다.
struct QuizQuestionVideo: View {
    /// 세션 스냅샷의 파일명으로 조회한 로컬 영상 위치.
    let url: URL?
    /// 채점 전 문제를 풀고 있을 때만 재생 조작을 허용한다.
    let isActive: Bool

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var player: AVPlayer?
    @State private var loadTask: Task<Void, Never>?
    @State private var isLoading = false
    @State private var hasFailed = false

    private var palette: QuizPalette { QuizPalette(colorScheme: colorScheme) }

    var body: some View {
        VStack(spacing: 10) {
            if let player, let item = player.currentItem {
                VideoPlayer(player: player)
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("문제에 첨부된 영상")
                    .onReceive(item.publisher(for: \.status).receive(on: RunLoop.main)) { status in
                        if status == .failed, self.player?.currentItem === item { showFailure() }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: item).receive(on: RunLoop.main)) { _ in
                        if self.player?.currentItem === item { showFailure() }
                    }
            } else if isLoading {
                ProgressView("영상을 불러오고 있어요")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Button(action: startPlayback) {
                    Label(hasFailed ? "다시 재생" : "영상 재생", systemImage: "play.circle.fill")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .background(palette.subtleBackground, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityHint("이 문제에 첨부된 영상을 불러와 재생합니다")
            }

            if hasFailed {
                Label("영상을 재생하지 못했어요", systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(palette.primaryText)
        .disabled(!isActive)
        .allowsHitTesting(isActive)
        .onChange(of: isActive) { _, active in
            if !active { pausePlayback() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { pausePlayback() }
        }
        .onChange(of: url) { _, _ in resetPlayback() }
        .onDisappear { resetPlayback() }
    }

    /// 버튼을 누른 시점에만 재생 가능 여부를 비동기로 확인하고 플레이어를 만든다.
    private func startPlayback() {
        guard isActive, !isLoading else { return }
        guard let url else {
            showFailure()
            return
        }
        hasFailed = false
        isLoading = true
        loadTask = Task {
            do {
                let asset = AVURLAsset(url: url)
                let playable = try await asset.load(.isPlayable)
                guard !Task.isCancelled else { return }
                guard playable else {
                    showFailure()
                    return
                }
                let item = AVPlayerItem(asset: asset)
                player = AVPlayer(playerItem: item)
                isLoading = false
                loadTask = nil
                player?.play()
            } catch {
                guard !Task.isCancelled else { return }
                showFailure()
            }
        }
    }

    /// 준비 중인 작업도 취소하며, 풀이로 복귀해도 자동으로 재생하지 않는다.
    private func pausePlayback() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
        player?.pause()
    }

    /// 문항 이동과 화면 종료 시 재생 자원을 해제한다.
    private func resetPlayback() {
        pausePlayback()
        player?.replaceCurrentItem(with: nil)
        player = nil
        hasFailed = false
    }

    /// 파일 누락·손상·재생 중 오류를 같은 안내와 재시도 버튼으로 표시한다.
    private func showFailure() {
        resetPlayback()
        hasFailed = true
    }
}

#if DEBUG
#Preview("첨부 영상 · 재생 전 · 라이트") {
    QuizQuestionVideo(url: nil, isActive: true)
        .padding()
        .background(Color.nightCardBackground)
        .preferredColorScheme(.light)
}

#Preview("첨부 영상 · 파일 누락 확인 · 다크") {
    QuizQuestionVideo(
        url: FileManager.default.temporaryDirectory.appendingPathComponent("quiz-video-missing.mov"),
        isActive: true
    )
    .padding()
    .background(Color.nightCardBackground)
    .preferredColorScheme(.dark)
}
#endif
