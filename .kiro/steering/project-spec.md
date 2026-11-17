---
inclusion: always
---

# 산타의 작업실 탈출 (Santa's Delivery Crisis) 스펙 문서

- 상태: 초안 v0.3 (디자인 시안 기준으로 정리, 팀 리뷰 전)
- 마감: 2026-11-22
- 디자인 기준: [디자인 매뉴얼](../../docs/design/santa-workshop-main-manual.html) / [화면 설계서](../../docs/design/screen-spec.html). 화면 구성은 이 둘을 따르고, 규칙은 이 문서와 작업별 문서를 따릅니다. 서로 다르면 담당자가 임의로 정하지 말고 팀에 확인합니다.
- 관련 문서: [작업별 상세 스펙](../../docs/specs) / [통합 계약표](../../docs/integration-contracts.md) / [확정 내역과 질의응답](../../docs/project-understanding.md) / [추가 구현 목록](../../docs/future-work.md) / [원본 기획 자료](../../docs/references/planning)
- 표기
  - **[가정]**: 문서를 쓰면서 제안했지만 팀이 아직 확정하지 않은 내용입니다.
  - **미정**: 제안 없이 팀의 결정을 기다리는 내용입니다.
  - Kiro는 `[가정]`과 미정 항목을 확정된 규칙처럼 구현하지 않고, 구현 전에 사용자에게 먼저 확인합니다. 모아서 확인하는 곳은 16장입니다.

## 1. 개요

iOS 개발 학습용 퀴즈 앱입니다. 산타의 빈 크리스마스 트리를 꾸미는 게임 형식으로 진행합니다.
사용자는 "작업"(카테고리)을 고르고 세션(한 판)을 풀어서 트리 장식을 얻습니다. 장식 12칸이 모두 차면 트리가 완성되고, 산타가 루돌프를 타고 선물을 주러 떠납니다.

**목표 사용자:** iOS와 개발에 관심 있는 사람. 쉽게 풀 수 있고, 게임식 보상으로 오래 쓰게 만드는 것이 목표입니다.

## 2. 범위

### 2-1. 1차 구현 범위
- 퀴즈 CRUD(만들기·보기·고치기·지우기). 텍스트, 이미지, 영상 문제
- 4지선다 단일 선택 문제
- 코드 실행을 줄별 애니메이션으로 보여 주는 문제(3~5개 유형)
- 출제 탭에서 난이도, 카테고리(여러 개), 문제 수를 고른 뒤 트리의 장식을 눌러 시작하는 선택 출제. 정답률이 가장 낮은 카테고리에 [추천] 배지
- 세션 진행, 이어서 풀기, 결과 요약(점수, 오답 노트, 추천 학습 자료)
- 트리 장식 보상, 트리 완성, 완성한 트리 수 기록
- 주/월 성과 대시보드
- 설정(정답률 기준 등), 다크모드, iPhone(세로)과 iPad(가로·세로), 접근성

### 2-2. 범위 밖
- 1차에서 제외한 기능은 [future-work.md](../../docs/future-work.md)에 모두 있습니다.
- macOS, 다국어(한국어로 통일), 로그인, 서버 연동은 지원하지 않습니다.

## 3. 개발 환경과 기술 스택

| 항목 | 내용 |
| --- | --- |
| IDE | Xcode 27.2 (팀 전원 동일) |
| 최소 OS | iOS 17 |
| UI | SwiftUI (NavigationStack, TabView, List, Form 등 기본 컴포넌트 우선) |
| 저장 | 퀴즈, 세션, 트리 기록은 SwiftData. 간단한 설정값은 @AppStorage |
| 차트 | Swift Charts (Apple 기본 프레임워크, 외부 라이브러리 아님) |
| 외부 라이브러리 | 사용하지 않음 (추가가 필요하면 팀 합의 후 spec에 기록) |
| 언어 | 앱 UI와 문제는 한국어로 통일 |
| 지원 기기 | iPhone 세로 고정, iPad 가로·세로 |

## 4. 용어

| 용어 | 뜻 |
| --- | --- |
| 작업 | 문제 카테고리를 산타 테마로 부르는 이름 (아래 표). 기획서의 "방"을 대체 |
| 작업실 | 첫 번째 탭의 이름. 트리와 진행 상황을 보는 메인 화면 |
| 세션 | 문제 5/10/15개를 한 번에 푸는 한 판 |
| 장식 | 세션 보상. 트리에 쌓임 |
| 트리 | 장식 12칸짜리 한 그루. 완성하면 완성 기록을 남기고 새 트리를 시작 |
| 난이도 | 쉬움, 보통, 어려움 (이 세 단어로 통일) |

### 작업과 카테고리 대응

| 작업 (UI 표시 이름) | 카테고리 (코드 이름) |
| --- | --- |
| 소원 접수 | AI 활용 (`aiUsage`) |
| 선물 생산 | Swift 문법 (`swiftSyntax`) |
| 포장 | HIG (`hig`) |
| 썰매 적재 | SwiftUI 실전 (`swiftUIPractice`) |

기획서의 "KxCoding"은 강의 이름이라 "SwiftUI 실전"으로 바꿨습니다.

## 5. 게임 규칙

1. 세션은 출제 탭에서 시작합니다. 팝업에서 난이도, 카테고리(여러 개), 문제 수를 고르고 [장식 선택]을 누르면 트리에 카테고리 장식 4개가 나타납니다. 고른 카테고리의 장식만 켜지고, 켜진 장식을 누르면 그 카테고리 하나의 세션이 시작됩니다. 해금 조건은 없습니다. 작업실의 "오늘의 출제" 버튼은 출제 탭으로 이동합니다 `[가정]`.
2. 세션이 끝나면 정답률을 계산합니다.
   - 정답률이 **기준 이상**이면 장식 **1개**를 받습니다. 기본 기준은 80%이고, 설정에서 50~100%(10% 단위)로 바꿀 수 있습니다.
   - 난이도와 문제 수는 보상에 영향이 없습니다.
   - 기준 미만이면 장식을 받지 못하지만 벌칙은 없습니다.
3. 트리는 한 그루이고 4개 작업의 장식이 같은 트리에 쌓입니다. 장식은 12칸입니다.
4. 12칸이 모두 차면 트리가 완성됩니다. 산타가 출발하는 연출을 보여 주고, 완성한 트리는 완성 기록으로 저장하며(기록 화면에 완성한 트리 수 표시), 빈 트리를 새로 시작합니다. 퀴즈 기록, 통계, 설정은 유지됩니다.
5. 쉬운 세션을 반복해서 빨리 완성하는 것은 막지 않습니다.
6. 세션 중 앱을 종료하면 진행 상황이 저장되고, 다시 켜면 "이어서 풀기"로 계속합니다. 진행 중 세션은 동시에 1개만 허용합니다.

## 6. 화면 구조

### 6-1. 탭
하단 탭 4개: **작업실 / 출제 / 기록 / 관리**. 각 탭은 독립된 NavigationStack을 가집니다. 퀴즈 진행과 결과는 탭 바를 숨기는 전체 화면입니다.
- 작업실: 트리 진행도, "오늘의 출제" 버튼, 난이도별 아직 안 푼 문제, 이어서 풀기를 둔 단순한 메인 화면입니다.
- 출제: 난이도·카테고리·문제 수를 고르고 트리의 장식을 눌러 시작하는 선택 출제입니다.
- 기록: 통계(완성한 트리 수 포함)와 설정으로 들어가는 화면입니다.
- 관리: 문제 목록과 편집입니다.

### 6-2. 화면 목록

화면별 상세 설명은 담당 작업 문서에 있고, 모든 상태(시트, 알림, 빈 상태, 오류 포함)는 [화면 설계서](../../docs/design/screen-spec.html)에 있습니다.

| ID | 화면 | 위치 | 상세 |
| --- | --- | --- | --- |
| S1 | 작업실 | 작업실 탭 루트 | [04-task-and-select](../../docs/specs/04-task-and-select.md) |
| S2 | 출제(필터 팝업) | 출제 탭 루트 | [04-task-and-select](../../docs/specs/04-task-and-select.md) |
| S2-B | 장식 선택 | 출제 탭 루트(팝업 뒤) | [04-task-and-select](../../docs/specs/04-task-and-select.md) |
| S2-A1, S2-A2, S2-E1 | 진행 중 세션 선택, 새로 시작 확인, 시작 실패 | 시트, 알림 | [04-task-and-select](../../docs/specs/04-task-and-select.md) |
| S4 | 퀴즈 진행 | 전체 화면 | [03-quiz-flow](../../docs/specs/03-quiz-flow.md) |
| S5 | 정답/오답 피드백 | 시트 | [03-quiz-flow](../../docs/specs/03-quiz-flow.md) |
| S6 | 세션 결과 | 전체 화면 | [03-quiz-flow](../../docs/specs/03-quiz-flow.md) |
| S7 | 오답 노트 | 푸시 | [03-quiz-flow](../../docs/specs/03-quiz-flow.md) |
| S9 | 기록 대시보드 | 기록 탭 루트 | [06-records-settings](../../docs/specs/06-records-settings.md) |
| S12 | 설정 | 기록 탭에서 푸시 | [06-records-settings](../../docs/specs/06-records-settings.md) |
| S10 | 문제 관리 목록 | 관리 탭 루트 | [07-question-management](../../docs/specs/07-question-management.md) |
| S11 | 문제 편집 | 푸시 | [07-question-management](../../docs/specs/07-question-management.md) |

보관함(S8)과 작업 선택(S2)·세션 설정(S3) 화면은 디자인 시안에서 없어졌거나 출제 탭 하나로 합쳐졌습니다.

### 6-3. iPad
- 가로·세로 모두 지원합니다. S10은 `NavigationSplitView`(좌측 목록, 우측 상세)로 확장합니다. 출제 화면(S2)의 트리는 화면 크기에 맞춰 늘어납니다.
- 별도 시안은 없고 SwiftUI 적응형 레이아웃으로 대응합니다. 퀴즈 진행 화면은 아이폰과 같은 한 컬럼 구성을 쓰고, 가로에서도 가운데에 폭을 제한해 보여 줍니다. 2단 구성 등 iPad 전용 배치는 1차에 하지 않습니다.

## 7. 기능 상세

기능 상세는 작업별 문서로 옮겼습니다. 자기 작업 문서만 읽으면 됩니다. 두 작업에 걸친 규칙은 주 담당 문서에 한 번만 적고 다른 문서에서는 링크합니다.

| 문서 | 내용 |
| --- | --- |
| [00-foundation](../../docs/specs/00-foundation.md) | 프로젝트 설정, 모델·프로토콜·mock, 색상 틀 |
| [01-seed-data](../../docs/specs/01-seed-data.md) | 시드 JSON, 로더, 60문제 |
| [02-session-engine](../../docs/specs/02-session-engine.md) | 출제 비율, 카테고리 추천, 이어서 풀기 로직, 보상·트리 |
| [03-quiz-flow](../../docs/specs/03-quiz-flow.md) | S4~S7, 문제 풀이, 결과, 피드백 |
| [04-task-and-select](../../docs/specs/04-task-and-select.md) | S1, S2, S2-B, 출제 탭 장식 트리, 장식 켜짐 조건 |
| [05-code-trace](../../docs/specs/05-code-trace.md) | 애니메이션 문제(코드 트레이스) |
| [06-records-settings](../../docs/specs/06-records-settings.md) | S9, S12, 통계, 설정 |
| [07-question-management](../../docs/specs/07-question-management.md) | S10, S11, 문제 관리, 미디어 |
| [08-assets](../../docs/specs/08-assets.md) | 캐릭터, 트리, 장식, 효과음 |
| [09-finish](../../docs/specs/09-finish.md) | README, 점검, 마감 |

## 8. 데이터 모델 (SwiftData)

팀원이 가장 먼저 합의해야 하는 부분입니다. 모델 파일은 작업 0(15장)에서 한 번에 만들고, 이후 변경은 PR 설명에 이유를 적습니다.

```swift
enum QuizCategory: String, Codable, CaseIterable {
    case aiUsage, swiftSyntax, hig, swiftUIPractice
}

enum Difficulty: String, Codable, CaseIterable {
    case easy, normal, hard
}

enum QuestionKind: String, Codable { case standard, animation }

@Model final class Question {
    @Attribute(.unique) var id: UUID
    var kind: QuestionKind
    var text: String
    var codeSnippet: String?          // 코드 문제의 코드
    var imageFileName: String?        // 앱 내부 폴더 상의 파일명
    var videoFileName: String?
    var choices: [String]             // 항상 4개
    var correctIndex: Int             // 0...3
    var explanation: String
    var hint: String?
    var resourceTitle: String?        // 추천 학습 자료
    var resourceURL: String?
    var category: QuizCategory
    var difficulty: Difficulty
    var tags: [String]
    var animationID: String?          // kind == .animation 일 때만 사용
    var isSeed: Bool
    var createdAt: Date
}

enum SessionStatus: String, Codable { case inProgress, completed, abandoned }

/// 세션 시작 시점의 문제 내용 복사본.
/// 원본 문제를 나중에 고치거나 지워도 진행 중 세션과 풀 당시의 문제 내용이 바뀌지 않게 한다.
/// 이미지·영상 파일은 복사하지 않고 파일명만 가진다(파일 보존 규칙은 아래 규칙 참고).
struct QuestionSnapshot: Codable {
    let questionID: UUID              // 통계 계산용 원본 id
    let category: QuizCategory        // 카테고리별 통계와 추천 배지용
    let kind: QuestionKind
    let tags: [String]                // 풀 당시의 태그. 1차에는 태그 선택 기능이 없음
    let animationID: String?
    let text: String
    let codeSnippet: String?
    let imageFileName: String?
    let videoFileName: String?
    let hint: String?
    let choices: [String]
    let correctIndex: Int
    let explanation: String
    let resourceTitle: String?
    let resourceURL: String?
}

@Model final class QuizSession {
    @Attribute(.unique) var id: UUID
    var category: QuizCategory?       // 1차에는 항상 값이 있음. nil은 4개 작업 혼합 세션용 자리(future-work)
    var difficulty: Difficulty
    var questionIDs: [UUID]           // 출제 순서 고정
    var questionSnapshots: [QuestionSnapshot]  // questionIDs와 같은 순서의 문제 복사본
    var currentIndex: Int
    var status: SessionStatus
    var passThresholdPercent: Int     // 시작 시점의 기준값을 저장
    var startedAt: Date
    var finishedAt: Date?
    var elapsedSeconds: TimeInterval  // 퀴즈 화면이 떠 있던 시간의 누적 (앱이 꺼져 있던 시간 제외)
    var earnedDecorations: Int        // 완료 시 확정
    var treeCompleted: Bool           // 완료 시 확정. 이 세션으로 트리가 완성되었는가
    @Relationship(deleteRule: .cascade) var answers: [SessionAnswer]
}

@Model final class SessionAnswer {
    var questionID: UUID
    var selectedIndex: Int
    var isCorrect: Bool
    var answeredAt: Date
}

@Model final class TreeRecord {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var completedAt: Date?            // nil이면 현재 꾸미는 중인 트리
    var decorationCount: Int          // 0...12
}
```

규칙
- 현재 트리는 `completedAt == nil`인 `TreeRecord` 한 개입니다. 앱 첫 실행 때 생성합니다.
- 문제별 정답률, 마지막 풀이 시각은 `SessionAnswer`에서 계산하고 별도 통계 모델은 두지 않습니다. 중복 저장으로 값이 어긋나는 것을 막기 위해서입니다.
- 정답률 기준은 세션을 시작할 때의 값을 세션에 저장합니다. 도중에 설정을 바꿔도 이번 세션은 영향받지 않습니다.
- 세션을 시작할 때 출제 문제를 `questionSnapshots`에 복사합니다. 세션 진행, 결과, 오답 노트의 문제 내용은 원본 `Question`을 읽지 않고 이 복사본으로 그립니다.
- 미디어 파일은 불변으로 다룹니다. 문제의 이미지·영상을 바꾸면 기존 파일을 덮어쓰지 않고 새 파일명으로 저장합니다.
- **진행 중(`inProgress`) 세션이 스냅샷으로 참조하는 미디어 파일은 문제를 삭제하거나 미디어를 교체해도 지우지 않습니다.** 다음 중 어느 것도 참조하지 않는 파일만 삭제합니다: ① 어떤 `Question` ② 진행 중 세션의 스냅샷 ③ 원본 `Question`이 아직 남아 있는 문제의 끝난 세션 스냅샷(오답 노트에 풀 당시 내용으로 보이기 때문입니다). 원본 문제를 삭제하면 ③은 보존 대상에서 빠집니다. 정리는 `MediaFileManaging.cleanUnreferencedFiles()` 한 곳에서 하며, 문제 삭제, 미디어 교체, 세션 종료 직후와 앱 시작 때 호출합니다. 문제 관리와 세션이 각자 정리 로직을 만들지 않습니다.
- 사용자가 문제를 삭제하면 그 문제는 오답 노트에서도 함께 사라집니다. 오답 노트는 원본 문제가 남아 있는 문제만 보여 주고, 세션의 점수와 정답률 같은 이미 확정된 기록은 바뀌지 않습니다. 문제를 수정한 경우에는 풀 당시의 내용(스냅샷)을 보여 줍니다. 진행 중 세션은 문제를 삭제해도 스냅샷으로 이어 풀 수 있습니다.
- 답(`SessionAnswer`)은 배열 순서가 아니라 `questionID`로 찾습니다. 한 세션에서 같은 `questionID`의 답은 하나만 존재합니다.
- 카테고리별 정답률(취약 카테고리 등 통계)은 답한 문제의 스냅샷 `category`로 계산하고, 문제별 정답률은 `questionID`로 계산합니다. 문제를 수정해도 같은 `questionID`의 기존 풀이 기록과 통계는 그대로 유지합니다.
- 세션 완료 시 확정되는 값(`earnedDecorations`, `treeCompleted`)은 결과 화면을 다시 열 때 재계산하지 않고 그대로 읽습니다.
- 모델의 옵셔널 필드는 모두 안전하게 처리합니다(11장).

### 8-1. 시드 데이터

시드 JSON 형식과 분량은 [01-seed-data](../../docs/specs/01-seed-data.md)에 있습니다. JSON 필드는 위 `Question` 모델과 이름을 같게 맞춥니다.

## 9. 모듈 인터페이스

각자 이 이름과 시그니처로 만들면 합칠 때 어긋나지 않습니다. 구현 안의 세부는 자유입니다.

```swift
/// 카테고리 추천 (S2 팝업의 [추천] 배지)
protocol TaskRecommending {
    /// 답한 기록이 있는 카테고리 중 정답률이 가장 낮은 카테고리. 동률이면 작업 순서가 앞선 쪽, 기록이 없으면 nil
    func recommendedCategory(sessions: [QuizSession]) -> QuizCategory?
}

/// 세션용 문제 선택 (비율은 docs/specs/02-session-engine.md). 1차에는 category를 항상 하나 넘긴다
protocol QuestionSelecting {
    func select(
        category: QuizCategory?,    // 1차에는 항상 값이 있음. nil(4개 작업 혼합)은 future-work
        difficulty: Difficulty,
        tags: Set<String>,          // 1차 UI에는 태그 선택이 없어 항상 빈 집합. 비어 있으면 전체 태그, 여러 개면 하나라도 가진 문제
        count: Int,
        questions: [Question],
        history: [QuizSession]      // 답(정오답, 시각)과 풀 당시 스냅샷(카테고리, 태그)을 함께 읽음
    ) -> [Question]
    /// 조건에 맞는 문제 수 (S2-B의 장식 켜짐 판단용: 1 이상이면 켜짐. 카테고리별로 호출한다)
    func availableCount(category: QuizCategory?, difficulty: Difficulty, tags: Set<String>, questions: [Question]) -> Int
}

/// 세션 생성·진행·종료. SwiftData 저장을 담당
protocol SessionManaging {
    func startSession(category: QuizCategory?, difficulty: Difficulty, tags: Set<String>, count: Int) throws -> QuizSession   // 1차에는 category 항상 지정
    /// `questionIndex`번째 문제(0부터)에 답을 저장한다. 문제는 순서대로만 제출할 수 있다.
    /// 이미 답이 있는 문제에 다시 호출하면 처음 저장된 답을 돌려주고 새로 저장하지 않는다(값이 달라도 유지).
    /// 아직 답하지 않은 앞선 문제가 있는 순서로 호출하면 오류를 던진다.
    /// 답 저장과 `currentIndex` 갱신(`answers.count`와 같은 값)은 한 번의 저장으로 처리한다
    func submit(answerIndex: Int, forQuestionAt questionIndex: Int, in session: QuizSession) throws -> SessionAnswer
    /// 이미 `completed`인 세션에 다시 호출하면 저장된 결과를 돌려주고 장식을 다시 지급하지 않는다.
    /// 세션 완료, 장식 지급, 트리 갱신은 한 번의 저장으로 처리한다. 실패하면 전부 취소하고 세션은 `inProgress`로 남아 재시도할 수 있다
    func finish(_ session: QuizSession) throws -> SessionResult
    func resumableSession() -> QuizSession?
    func abandon(_ session: QuizSession) throws
}

/// 세션 결과 요약
struct SessionResult {
    let correctCount: Int
    let totalCount: Int
    let accuracyPercent: Int
    let elapsed: TimeInterval
    let earnedDecorations: Int         // 기준 미만이면 0, 아니면 1
    let treeCompleted: Bool            // 이번 세션으로 트리가 완성되었는가
    let wrongAnswers: [SessionAnswer]
}

/// 장식 지급과 트리 완성 처리
protocol TreeManaging {
    func currentTree() -> TreeRecord
    /// 장식을 지급한다. 12칸이 차면 완성 처리 후 빈 트리를 새로 시작한다. 보상이 항상 1개라 이월은 없다.
    /// 같은 ModelContext에서 값만 바꾸고, 저장(save)은 `SessionManaging.finish`가 한 번만 호출한다
    func grant(decorations: Int) throws -> TreeGrantResult
    func completedTrees() -> [TreeRecord]
}

/// 효과음과 햅틱
protocol FeedbackPlaying {
    func playCorrect()
    func playWrong()
    func playTreeComplete()
}

/// 사용자 미디어 파일 저장과 정리. 정리 로직을 한 곳에 두고 문제 관리와 세션이 같이 호출한다
protocol MediaFileManaging {
    /// 선택한 이미지·영상을 앱 내부 폴더에 새 파일명으로 복사하고 그 파일명을 돌려준다(기존 파일을 덮어쓰지 않음)
    func store(from url: URL) throws -> String
    /// 어떤 `Question`, 진행 중 세션 스냅샷, 원본이 남은 문제의 끝난 세션 스냅샷도 참조하지 않는 파일을 삭제한다
    func cleanUnreferencedFiles() throws
}

/// 장식 지급 결과
struct TreeGrantResult {
    let completedTree: TreeRecord?     // 이번 지급으로 완성된 트리 (없으면 nil)
    let currentDecorationCount: Int    // 지급 후 현재 트리의 장식 수
}

/// 애니메이션 문제 한 단계
struct TraceStep {
    let line: Int                       // 하이라이트할 코드 줄 (1부터)
    let narration: String               // 말풍선과 VoiceOver 설명
    let variables: [String: String]     // 이 단계 이후의 변수 값
    let sceneAction: TraceSceneAction   // 캐릭터와 배경의 동작
}

/// 캐릭터와 배경의 동작. 작업 5(애니메이션 문제)가 값을 정의한다.
/// 작업 0에서는 다른 작업이 컴파일되도록 빈 자리(`.none`)만 둔다
enum TraceSceneAction { case none }

/// animationID로 장면과 실행 순서를 찾는 저장소
protocol TraceSceneRegistry {
    func scene(for animationID: String) -> (steps: [TraceStep], view: AnyView)?
}
```

- 조회 결과가 없을 수 있는 값(`resumableSession`, `scene`)은 옵셔널로 반환하고 호출하는 쪽에서 안전하게 처리합니다.
- 설정값은 서비스가 직접 `@AppStorage`를 읽지 않고, 호출하는 쪽에서 값을 넘기거나 `SettingsStore`(UserDefaults 래퍼)를 주입합니다. 테스트하기 쉽게 하기 위해서입니다. 설정 키와 기본값은 작업 0(foundation)이 정의하고, 작업 6(기록·설정)은 설정 화면과 편집만 맡습니다.

## 10. 폴더 구조 (제안)

```
Santa'sDeliveryCrisis/
  App/                  앱 진입점, 탭 구성
  Models/               SwiftData 모델, enum
  Services/             세션, 출제, 트리, 피드백
  Features/
    Task/               S1 (작업실)
    Select/             S2, S2-B (출제 탭: 필터 팝업, 장식 트리)
    Quiz/               S4, S5, S6, S7
    Trace/              애니메이션 문제 컴포넌트와 장면
    Records/            S9
    Manage/             S10, S11
    Settings/           S12
  Resources/
    Seed/               questions.json
    Sounds/             효과음 파일
    Assets.xcassets     색상(라이트/다크), 이미지
  Extensions/           공통 확장
```

## 11. 공통 규칙

### 11-1. 코드
- 강제 언래핑(`!`)과 `try!`는 쓰지 않습니다. 옵셔널은 `guard let`, `if let`, `??`로 처리합니다.
- 공개 타입과 함수에는 문서화 주석(`///`)을 답니다. 이것이 API 문서 요구사항입니다.
- 색상은 Asset 카탈로그의 라이트/다크 색상 세트로만 정의합니다. 화면 코드에서 색상 값을 직접 쓰지 않습니다.
- 문자열은 한국어로 통일합니다.
- 뷰는 작게 나누고, 데이터 처리 로직은 Services에 둡니다. 뷰 안에서 SwiftData 조회를 직접 쓰는 경우는 `@Query`로 제한합니다.

### 11-2. 접근성
- 모든 텍스트는 Dynamic Type을 따르고, 가장 큰 글자 크기에서도 레이아웃이 망가지지 않아야 합니다(고정 높이 금지, 필요하면 스크롤).
- 중요한 이미지와 버튼에는 VoiceOver 라벨을 붙입니다.
- 모션 줄이기(`accessibilityReduceMotion`)가 켜져 있으면 이동·확대 연출을 페이드로 바꿉니다.
- 정답/오답은 색 외에 아이콘과 문구로 구분합니다.

### 11-3. 빈 상태
- 문제가 없는 경우(S10), 필터 결과가 0개인 경우, 오답이 없는 경우에는 안내 문구와 다음 행동 버튼을 보여 줍니다.

### 11-4. Git
- 브랜치: `main`(최종), `develop`(통합), `feature/*`(기능), `docs/*`(문서). feature와 docs는 develop에서 분기해 develop으로 병합합니다.
- 브랜치 이름: 기능은 `feature/<영역>-<내용>` (예: `feature/quiz-result-screen`), 문서만 바꾸는 작업은 `docs/<내용>` (예: `docs/project-spec`)
- `develop`과 `main`에는 직접 커밋하지 않고 PR로만 병합합니다.
- 커밋: Conventional Commits. `<type>(<scope>): <subject>`
  - 제목은 영어, 본문은 한글 목록(`-`)으로 작성합니다.
  - 커밋에 AI 관련 문구를 넣지 않습니다.
- PR은 최소 1명의 리뷰를 받고 병합합니다. 팀 규칙에 따라 AI가 짠 코드도 작성자가 설명할 수 있어야 합니다.
- 모델(`Models/`)을 바꾸는 PR은 팀원 모두에게 알립니다.

## 12. 에셋

에셋 목록은 [08-assets](../../docs/specs/08-assets.md)에 있습니다. 색상은 라이트/다크 모두 Asset 카탈로그에 정의합니다.

## 13. 비기능 요구사항

- **크래시 방지:** 11-1의 규칙을 지킵니다. 빈 배열 접근, 범위 밖 인덱스를 조심합니다. `choices.count != 4`인 문제는 편집 단계에서 저장할 수 없게 하고, 시드 로드 단계에서 건너뛰며 로그를 남깁니다.
- **성능:** 목록은 `List`나 `LazyVStack`을 씁니다. 큰 영상은 미리 로드하지 않고 해당 문제 화면에서만 로드합니다.
- **오프라인:** 네트워크 없이 모든 기능이 동작해야 합니다. 학습 자료 링크는 Safari로 여는 외부 링크이며, 오프라인이면 열리지 않습니다.
- **테스트:** 순수 로직(`QuestionSelector`, `TaskRecommending`, 보상 계산, 트리 완성)은 단위 테스트를 만듭니다.

## 14. 완료 기준 (마감 2026-11-22)

- [ ] iPhone과 iPad에서 시뮬레이터로 실행해 아래 흐름이 처음부터 끝까지 동작합니다.
  1. 작업실에서 "오늘의 출제"로 출제 탭 이동 → 필터 팝업에서 설정 → 장식 선택 → 켜진 장식 누르기 → 퀴즈 진행 → 결과 → 장식 지급
  2. 장식 12칸을 채워 트리 완성 → 기록 화면의 완성한 트리 수가 늘어남
  3. 문제 생성/수정/삭제 (사용자가 만든 문제 기준. 시드 문제의 수정·삭제 버튼은 비활성화 상태로 표시)
  4. 기록 대시보드에서 통계와 완성 기록 확인
- [ ] 앱을 세션 도중 종료해도 "이어서 풀기"로 복구됩니다.
- [ ] 애니메이션 문제가 3개 이상 유형으로 동작합니다.
- [ ] [통합 계약표](../../docs/integration-contracts.md)의 통합 시나리오 5개가 통과합니다.
- [ ] 아래 계약은 단위 테스트로 확인합니다: 후보가 고른 문제 수보다 적을 때 가능한 만큼만 출제함, 카테고리 추천 배지 계산(동률, 기록 없음), 앱을 다시 켜고 `finish`를 다시 호출해도 장식이 중복 지급되지 않음, 원본 문제를 수정하거나 삭제한 뒤에도 진행 중 세션을 이어 풀 수 있음.
- [ ] 라이트/다크 모드가 모두 자연스럽게 표시됩니다.
- [ ] 가장 큰 Dynamic Type에서 주요 화면이 깨지지 않습니다.
- [ ] 시드 문제가 60문제 이상 들어 있습니다.
- [ ] README(기능, 설치 방법, 의존 라이브러리, 폴더 구조), 주요 흐름(작성-조회-통계) 스크린샷·GIF, 공개 API 문서화 주석이 완성되었습니다.
- [ ] 크래시가 없고, 강제 언래핑이 코드에 없습니다.

## 15. 작업 분리

작업 0이 끝나기 전에는 다른 작업이 서로 의존합니다. 작업 0만 먼저 진행하고, 나머지는 병렬로 진행합니다.

| 번호 | 작업 | 포함 | 의존 | 병렬 가능 |
| --- | --- | --- | --- | --- |
| 0 | [기반](../../docs/specs/00-foundation.md) | Xcode 프로젝트 설정(iOS 17, iPad 방향), 폴더 구조, 8장 모델, enum, 9장 프로토콜과 결과 타입(`SessionResult`, `TreeGrantResult`, `QuestionSnapshot`, `TraceSceneAction` 빈 자리), 화면 미리보기용 가짜(mock) 구현, `MediaFileManaging`, `SettingsStore`(설정 키와 기본값), 테스트 타깃, iOS 17 배포 설정 확인, 색상 Asset 기본 틀, 탭 뼈대 | 없음 | 가장 먼저, 가능한 한 빨리 develop에 병합 |
| 1 | [시드 데이터](../../docs/specs/01-seed-data.md) | 시드 JSON 스키마, 로더, 첫 실행 주입, 문제 작성(60문제 이상) | 0 | 문제 작성은 작업 0 중에도 시작 가능 |
| 2 | [세션 로직](../../docs/specs/02-session-engine.md) | `QuestionSelector`, `TaskRecommending`, `SessionManager`, 보상 계산, `TreeManager`, 단위 테스트 | 0 | 1, 3, 4와 병렬 |
| 3 | [퀴즈 화면](../../docs/specs/03-quiz-flow.md) | S4, S5, S6, S7, 피드백(햅틱, 효과음), 이어서 풀기 UI | 0, 2의 프로토콜 | 작업 0의 가짜(mock) 구현으로 개발하고, 작업 2의 실제 구현이 준비되면 교체 |
| 4 | [작업실·출제 화면](../../docs/specs/04-task-and-select.md) | S1, S2(필터 팝업), S2-B(장식 선택), 진행 중 세션 시트·알림, 트리 렌더링, 장식 켜짐/꺼짐, 완성 연출 | 0, 2의 프로토콜 | |
| 5 | [애니메이션 문제](../../docs/specs/05-code-trace.md) | `TraceStep`, 코드 하이라이트·변수 표시·말풍선 컴포넌트, 장면 3~5개, 접근성(모션 줄이기, VoiceOver) | 0, 에셋 | 3의 S4와 연결하는 시점만 조율 |
| 6 | [기록·설정](../../docs/specs/06-records-settings.md) | S9(차트, 완성 트리 수), S12, @AppStorage 키 | 0 | |
| 7 | [문제 관리](../../docs/specs/07-question-management.md) | S10, S11, 사진 보관함 선택, 파일 복사 저장 | 0 | |
| 8 | [에셋·사운드](../../docs/specs/08-assets.md) | 캐릭터, 트리, 장식, 배경, 효과음, 앱 아이콘 | 없음 | 처음부터 병렬 |
| 9 | [마감](../../docs/specs/09-finish.md) | README(글꼴 크기를 시스템 설정에 맡긴 해석 설명 포함), 스크린샷·GIF, 문서화 주석 점검, 접근성·iPad 점검, 크래시 점검 | 전체 | 마지막 |

연결 지점 (여기가 어긋나기 쉽습니다)
- 작업 3, 4는 작업 2의 프로토콜(9장)만 보고 개발하고, 실제 구현이 준비되면 교체합니다.
- 작업 5는 작업 3의 S4가 문제 종류에 따라 애니메이션 뷰를 끼워 넣을 자리(`kind == .animation`)를 만들어 둡니다.
- 작업 1의 시드 JSON과 작업 7의 편집 화면은 같은 `Question` 모델 필드를 씁니다. 필드를 바꾸면 양쪽에 알립니다.
- 각 작업의 "통합 완료 조건"과 확인 담당, 통합 시나리오 5개는 [통합 계약표](../../docs/integration-contracts.md)를 따릅니다. mock으로 화면만 만든 상태는 완료가 아닙니다.

## 16. 확인이 필요한 가정

아래는 팀이 아직 확정하지 않은 항목입니다. 구현 전에 사용자에게 먼저 확인합니다. 디자인 시안과 화면 설계서(8장)에도 같은 성격의 항목이 있습니다.

1. 작업실의 "오늘의 출제" 버튼은 출제 탭으로 이동만 하고, 4개 작업을 섞는 세션은 1차에 없음 ([04-task-and-select](../../docs/specs/04-task-and-select.md))
2. 카테고리 [추천] 배지 규칙: 기록이 있는 카테고리 중 정답률 최저, 동률은 작업 순서, 기록 없으면 배지 없음 ([02-session-engine](../../docs/specs/02-session-engine.md))
3. 후보가 고른 문제 수보다 적을 때 가능한 만큼만 출제하고 안내 문구를 보임 ([04-task-and-select](../../docs/specs/04-task-and-select.md))
4. 출제 필터 팝업 상태 정리(카테고리 최소 1개, 취소 시 이전 설정 유지) ([04-task-and-select](../../docs/specs/04-task-and-select.md))
5. 단일 카테고리 선택 출제의 문제 선택 비율 50% 약한 문제 / 50% 오래 안 푼 문제 ([02-session-engine](../../docs/specs/02-session-engine.md))
6. 장식을 누르면 퀴즈 화면이 커지며 열리는 연출. 1차는 페이드, iOS 17에서 확대 연출은 직접 구현 필요 ([04-task-and-select](../../docs/specs/04-task-and-select.md))
7. 출제 탭만 나이트 글로우 팔레트를 쓰고 나머지는 작업실 색을 씀. 최종 색을 하나로 할지 미정 ([04-task-and-select](../../docs/specs/04-task-and-select.md), [08-assets](../../docs/specs/08-assets.md))
8. 시안 v3의 장식별 난이도 통과 점, 문 열림, 초기화 버튼은 1차에서 제외 ([04-task-and-select](../../docs/specs/04-task-and-select.md))
9. 태그 선택, 보관함 화면, 문제 수 잠금을 뺌(디자인 시안 기준). 되돌리기 쉬운 항목이며 [future-work](../../docs/future-work.md)에 있음
10. 보상을 난이도와 상관없이 항상 1개로 통일하면서 이월 규칙과 관련 필드를 삭제함. 팀 확인이 필요합니다 (5장, 8장)
