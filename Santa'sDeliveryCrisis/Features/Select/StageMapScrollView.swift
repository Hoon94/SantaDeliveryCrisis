import SwiftUI
import UIKit

/// 지도 한 곳에서만 끝을 넘는 바운스를 막고, 요청한 단계로 이동하는 스크롤 컨테이너.
struct StageMapScrollView<Content: View>: UIViewControllerRepresentable {
    let contentSize: CGSize
    let focusX: CGFloat
    let focusedStageID: Int
    let focusRequestID: UUID
    let content: Content

    /// 지도 좌표와 명시적인 이동 요청을 SwiftUI 콘텐츠와 함께 받는다.
    init(
        contentSize: CGSize, focusX: CGFloat, focusedStageID: Int, focusRequestID: UUID,
        @ViewBuilder content: () -> Content
    ) {
        self.contentSize = contentSize
        self.focusX = focusX
        self.focusedStageID = focusedStageID
        self.focusRequestID = focusRequestID
        self.content = content()
    }

    /// 지도 전용 스크롤 화면을 생성한다.
    func makeUIViewController(context: Context) -> StageMapScrollController<Content> {
        StageMapScrollController(content: content)
    }

    /// 콘텐츠 갱신과 단계 이동 요청을 지도 컨테이너에 전달한다.
    func updateUIViewController(_ controller: StageMapScrollController<Content>, context: Context) {
        controller.update(
            content: content, contentSize: contentSize, focusX: focusX,
            stageID: focusedStageID, requestID: focusRequestID
        )
    }
}

/// 전역 스크롤 설정을 건드리지 않고 지도에만 UIKit의 경계 제한을 적용한다.
final class StageMapScrollController<Content: View>: UIViewController {
    private let scrollView = UIScrollView()
    private let hostingController: UIHostingController<Content>
    private var widthConstraint: NSLayoutConstraint?
    private var previousSize = CGSize.zero
    private var previousStageID: Int?
    private var previousRequestID: UUID?
    private var pendingFocusX: CGFloat?

    /// SwiftUI 지도를 자식 화면으로 보관한다.
    init(content: Content) {
        hostingController = UIHostingController(rootView: content)
        super.init(nibName: nil, bundle: nil)
    }

    /// 코드로 생성하는 지도 컨테이너이므로 스토리보드 초기화는 지원하지 않는다.
    @available(*, unavailable)
    required init?(coder: NSCoder) { return nil }

    /// 가로 콘텐츠만 스크롤하고 두 끝에서는 바운스 없이 멈추도록 설정한다.
    override func loadView() {
        view = scrollView
        scrollView.backgroundColor = .clear
        scrollView.bounces = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.alwaysBounceVertical = false
        scrollView.isDirectionalLockEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delaysContentTouches = false

        addChild(hostingController)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hostingController.view)
        let width = hostingController.view.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint = width
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostingController.view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            width
        ])
        hostingController.didMove(toParent: self)
    }

    /// 명시적인 이동 요청과 화면 크기 변경에만 위치를 바꾸고, 일반 상태 갱신에서는 드래그 위치를 보존한다.
    func update(content: Content, contentSize: CGSize, focusX: CGFloat, stageID: Int, requestID: UUID) {
        loadViewIfNeeded()
        hostingController.rootView = content
        widthConstraint?.constant = contentSize.width
        if previousSize != contentSize || previousStageID != stageID || previousRequestID != requestID {
            pendingFocusX = focusX
            previousSize = contentSize
            previousStageID = stageID
            previousRequestID = requestID
            view.setNeedsLayout()
        }
    }

    /// 실제 화면 폭이 정해진 뒤 이동 위치를 유효한 좌우 경계 안으로 제한한다.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let focusX = pendingFocusX, scrollView.bounds.width > 0 else { return }
        pendingFocusX = nil
        let maximumX = max(0, previousSize.width - scrollView.bounds.width)
        let targetX = min(maximumX, max(0, focusX - scrollView.bounds.width / 2))
        scrollView.setContentOffset(CGPoint(x: targetX, y: 0), animated: false)
    }
}
