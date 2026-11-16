---
inclusion: always
---

# 산타의 작업실 탈출 (Santa's Delivery Crisis) 스펙 문서

- 상태: 초안 v0.1 (팀 리뷰 전)
- 마감: 2026-11-22
- 관련 문서: [확정 내역과 질의응답](../../docs/project-understanding.md) / [추가 구현 목록](../../docs/future-work.md) / [원본 기획 자료](../../docs/references/planning)
- 표기: **[가정]** 은 팀이 명시적으로 확정하지 않았고 기존 답변에서 제가 이어 붙인 내용입니다. 16장에서 한꺼번에 확인합니다.

## 1. 개요

iOS 개발 학습용 퀴즈 앱입니다. 산타의 빈 크리스마스 트리를 꾸미는 게임 형식으로 진행합니다.
사용자는 "작업"(카테고리)을 고르고 세션(한 판)을 풀어서 트리 장식을 얻습니다. 장식 12칸이 모두 차면 트리가 완성되고, 산타가 루돌프를 타고 선물을 주러 떠납니다.

**목표 사용자:** iOS와 개발에 관심 있는 사람. 쉽게 풀 수 있고, 게임식 보상으로 오래 쓰게 만드는 것이 목표입니다.

## 2. 범위

### 2-1. 1차 구현 범위
- 퀴즈 CRUD(만들기·보기·고치기·지우기). 텍스트, 이미지, 영상 문제
- 4지선다 단일 선택 문제
- 코드 실행을 줄별 애니메이션으로 보여 주는 문제(3~5개 유형)
- 반응형 출제와 작업 추천
- 세션 진행, 이어서 풀기, 결과 요약(점수, 오답 노트, 추천 학습 자료)
- 트리 장식 보상, 트리 완성, 완성 기록 보관
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
| 세션 | 문제 5/10/15개를 한 번에 푸는 한 판 |
| 장식 | 세션 보상. 트리에 쌓임 |
| 트리 | 장식 12칸짜리 한 그루. 완성하면 보관함에 저장하고 새 트리를 시작 |
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

1. 사용자는 4개 작업 중 자유롭게 하나를 고릅니다. 해금 조건은 없습니다.
2. 앱은 사용자의 취약점과 선호도를 조합해 한 작업에 "추천" 배지를 붙입니다(7-3).
3. 난이도(쉬움/보통/어려움)와 문제 수(5/10/15)를 고르고 세션을 시작합니다.
4. 세션이 끝나면 정답률을 계산합니다.
   - 정답률이 **기준 이상**이면 장식을 받습니다. 기본 기준은 80%이고, 설정에서 50~100%(10% 단위)로 바꿀 수 있습니다.
   - 장식 수는 난이도로 정해집니다. 쉬움 1개, 보통 2개, 어려움 3개. 문제 수는 보상에 영향이 없습니다.
   - 기준 미만이면 장식을 받지 못하지만 벌칙은 없습니다.
5. 트리는 한 그루이고 4개 작업의 장식이 같은 트리에 쌓입니다. 장식은 12칸입니다.
6. 12칸이 모두 차면 트리가 완성됩니다. 산타가 출발하는 연출을 보여 주고, 완성한 트리는 보관함에 저장하며, 빈 트리를 새로 시작합니다. 퀴즈 기록, 통계, 설정은 유지됩니다.
7. 받을 장식이 남은 칸보다 많으면 남은 칸을 채워 트리를 완성하고, 초과분은 새로 시작하는 트리로 이월합니다. 예: 11칸이 찬 트리에서 3개를 받으면 1개로 완성하고 2개는 새 트리에 채웁니다.
8. 쉬운 세션을 반복해서 빨리 완성하는 것은 막지 않습니다.
9. 세션 중 앱을 종료하면 진행 상황이 저장되고, 다시 켜면 "이어서 풀기"로 계속합니다. 진행 중 세션은 동시에 1개만 허용합니다. **[가정]**

## 6. 화면 구조

### 6-1. 탭
하단 탭 3개: **작업 / 기록 / 관리**. 각 탭은 독립된 NavigationStack을 가집니다. 퀴즈 진행과 결과는 탭 바를 숨기는 전체 화면(`fullScreenCover`)입니다.
기획서의 "출제" 탭은 "오늘의 출제" 단축 버튼으로 줄여서 작업 탭 안에 넣었습니다. **[가정]**

### 6-2. 화면 목록

| ID | 화면 | 위치 | 설명 |
| --- | --- | --- | --- |
| S1 | 작업 메인 | 작업 탭 루트 | 트리와 장식 진행도, "이어서 풀기"(진행 중 세션이 있을 때), "오늘의 출제" 버튼(추천 작업으로 바로 시작) |
| S2 | 작업 선택 | 작업 탭 | 4개 작업 카드, 추천 배지, 작업별 정답률 |
| S3 | 세션 설정 | 시트 | 난이도와 문제 수(5/10/15) 선택. 선택한 작업과 난이도에 풀 수 있는 문제 수가 선택한 문제 수보다 적으면 그 문제 수는 비활성화하고 "문제가 더 추가되면 열려요" 안내를 표시 (7-9 참고) |
| S4 | 퀴즈 진행 | 전체 화면 | 진행 번호, 문제(텍스트/이미지/영상/코드), 보기 4개, [확인] 버튼, [힌트] 버튼 **[가정]** |
| S5 | 정답/오답 피드백 | 시트 | 정답 여부, 해설. 애니메이션 문제는 재생이 끝난 뒤 표시 |
| S6 | 세션 결과 | 전체 화면 | 점수, 정답률, 소요 시간, 보상 장식 연출, 오답 요약, 추천 학습 자료 |
| S7 | 오답 노트 | 푸시 | 이번 세션 오답 목록과 상세 |
| S8 | 보관함 | 작업 탭에서 푸시 | 완성한 트리 목록(완성 날짜, 걸린 세션 수) |
| S9 | 기록 대시보드 | 기록 탭 루트 | 주/월 전환, 시도 횟수, 평균 점수, 풀이 문제 수 차트, 취약 카테고리, 완성한 트리 기록 |
| S10 | 문제 관리 목록 | 관리 탭 루트 | 검색, 카테고리/난이도 필터, 삭제. 시드 문제의 삭제 버튼은 비활성화 (7-7) |
| S11 | 문제 편집 | 푸시 | 문제 생성과 수정(일반 문제만) |
| S12 | 설정 | 기록 탭에서 푸시 | 정답률 기준, 소리, 진동 |

### 6-3. iPad
- 가로·세로 모두 지원합니다. S2, S10은 `NavigationSplitView`(좌측 목록, 우측 상세)로 확장합니다.
- 별도 시안은 없고 SwiftUI 적응형 레이아웃으로 대응합니다. 퀴즈 진행 화면은 가로에서도 중앙 컬럼 폭을 제한합니다. **[가정]**

## 7. 기능 상세

### 7-1. 문제 풀이 (S4, S5)
- 보기 하나를 선택하고 **[확인]** 버튼을 눌러 채점합니다. 확인 전에는 선택을 바꿀 수 있습니다.
- 일반 문제: 확인 즉시 피드백을 표시합니다.
- 애니메이션 문제: 확인 후 애니메이션을 재생하고, 끝나면 정답 여부와 해설을 표시합니다. 건너뛰기와 다시 보기는 1차에 없습니다.
- 피드백
  - 정답: 초록색, ✓ 아이콘과 문구, 햅틱 `.success`, 효과음
  - 오답: 빨간색, ✕ 아이콘과 문구, 햅틱 `.error`, 보기 좌우 흔들림, 효과음
  - 색만으로 구분하지 않습니다.
- 답은 문제마다 저장됩니다(7-5 이어서 풀기).

### 7-2. 세션 결과 (S6)
- 보상 장식이 트리로 날아가는 연출은 이 화면에서 재생합니다. 문제별 연출에는 쓰지 않습니다.
- 오답이 있으면 오답 노트로 이동할 수 있고, 오답 문제의 학습 자료 링크를 "추천 학습 자료"로 모아서 보여 줍니다.
- 트리가 완성되면 완성 연출(산타 출발)을 이 화면에서 이어서 재생합니다.

### 7-3. 반응형 출제와 추천

**작업 추천 (`TaskRecommender`)**
- 입력: 최근 세션 기록(최근 30일 **[가정]**)
- 점수 = 취약도 70% + 선호도 30% **[가정]**
  - 취약도 = 1 - 해당 카테고리 정답률 (기록이 없으면 0.5)
  - 선호도 = 해당 카테고리 세션 수 / 전체 세션 수
- 점수가 가장 높은 작업에 "추천" 배지를 붙입니다. 기록이 전혀 없으면 첫 작업(소원 접수)을 추천합니다.

**문제 선택 (`QuestionSelector`)**
선택한 작업의 카테고리와 난이도에 해당하는 문제 중에서 다음 비율로 고릅니다.

| 비율 | 대상 |
| --- | --- |
| 50% | 약한 문제: 최근 오답이거나 정답률이 낮은 문제 |
| 30% | 선호 태그 문제: 사용자가 자주 푼 태그의 문제 **[가정]** |
| 20% | 오래 안 푼 문제 또는 한 번도 안 푼 문제 |

- 한 범주에서 모자라면 나머지 범주에서 채웁니다. 중복 출제는 없습니다.
- 정해진 문제 수에서 순서는 무작위로 섞습니다.
- 기획서의 "선호 카테고리"는 작업 안에서는 의미가 없어서 "선호 태그"로 바꿨습니다. **[가정]**

### 7-4. 애니메이션 문제 (코드 트레이스)
참고 구현: [rabbit-quiz-v3.html](../../docs/references/planning/rabbit-quiz-v3.html)

- 문제는 코드 조각, 보기, 장면(캐릭터와 배경), 실행 순서로 구성됩니다.
- 확인 후 코드를 한 줄씩 하이라이트하면서 캐릭터가 그 줄을 실행하고, 말풍선에 조건 결과와 변수 값을 표시합니다.
- 공통 컴포넌트(코드 줄 하이라이트, 변수 표시, 말풍선)는 재사용하고, 장면은 유형별로 만듭니다. 1차 유형은 3~5개(예: 조건문, 반복문, 옵셔널, guard)입니다.
- 캐릭터와 배경은 이미지 에셋을 SwiftUI 애니메이션으로 움직입니다. 코드로 도형을 그리지 않습니다.
- 애니메이션 문제는 앱 내장 시드 데이터로만 제공합니다. 문제 관리(S10)에서는 목록 조회와 삭제만 가능하고 편집은 막습니다.
- 접근성
  - 모션 줄이기가 켜져 있으면 캐릭터 이동을 생략하고 코드 줄 하이라이트와 텍스트 설명만 보여 줍니다.
  - VoiceOver에는 "1번째 줄: apples는 3으로 설정됩니다"처럼 줄별 실행 설명을 텍스트로 제공합니다.
- 코드 토큰 탭 설명은 1차에 없고 해설 텍스트로 대신합니다.

### 7-5. 이어서 풀기
- 문제 하나에 답하고 [확인]을 누를 때마다 세션 상태를 SwiftData에 저장합니다.
- 앱을 시작할 때 `inProgress` 상태 세션이 있으면 S1에 "이어서 풀기"를 보여 줍니다.
- 이어서 푸는 중 사용자가 "새로 시작"을 고르면 기존 세션을 `abandoned`로 바꿉니다. **[가정]**

### 7-6. 기록 대시보드 (S9)
- 주/월 전환 세그먼트
- 표시: 퀴즈 시도 횟수, 평균 점수, 풀이 문제 수 막대 차트, 평균 점수 추이 선 차트, 취약 카테고리 (정답률 낮은 순)
- 완성한 트리 기록: 완성 횟수와 최근 완성일. 상세는 보관함(S8)에서 봅니다.

### 7-7. 문제 관리 (S10, S11)
- 목록 검색, 카테고리/난이도 필터, 스와이프 삭제
- 편집 항목: 문제 텍스트, 이미지(사진 보관함에서 선택), 영상(사진 보관함에서 선택), 보기 4개, 정답, 해설, 힌트, 학습 자료(제목과 URL), 카테고리, 난이도, 태그
- 선택한 이미지와 영상은 앱 내부 폴더에 복사해서 저장합니다. 용량 제한은 두지 않습니다.
- 시드 문제(`isSeed == true`)의 수정과 삭제 버튼은 화면에 표시하되 **비활성화**합니다. UI 확인용이며 동작은 1차에서 연결하지 않습니다. 사용자가 직접 만든 문제만 수정·삭제할 수 있습니다.
- 시드 문제 행에는 "기본 문제는 수정할 수 없어요" 같은 안내를 보여 줍니다.

### 7-8. 설정 (S12)

| 키 (@AppStorage) | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `hasLaunchedBefore` | Bool | false | 첫 실행 여부 (시드 주입과 온보딩 판단) |
| `passThresholdPercent` | Int | 80 | 보상 받는 정답률 기준 (50~100, 10 단위) |
| `soundEnabled` | Bool | true | 효과음 |
| `hapticsEnabled` | Bool | true | 진동 |

- 테마는 시스템 설정(라이트/다크)을 따릅니다. 앱 안에 테마 선택 설정은 없습니다.
- 글자 크기는 Dynamic Type을 따르고 앱 안에 별도 글꼴 크기 설정은 없습니다. **[가정]** 요구사항의 "글꼴 크기"는 Dynamic Type으로 충족합니다.

### 7-9. 문제 수 선택 활성화 조건
- 문제 수 선택지(5, 10, 15)는 선택한 작업과 난이도에 해당하는 문제 수 이상일 때만 활성화합니다. 조건은 `사용 가능한 문제 수 >= 선택지`입니다.
- 1차에는 구간(작업 × 난이도)당 시드가 5문제라서 **5문제 세션만 활성화**됩니다. 테스트용으로 충분합니다.
- 문제가 추가되면(시드를 늘리거나 사용자가 만들면) 코드를 바꾸지 않아도 10, 15가 자동으로 활성화됩니다.

## 8. 데이터 모델 (SwiftData)

팀원이 가장 먼저 합의해야 하는 부분입니다. 모델 파일은 작업 0(15장)에서 한 번에 만들고, 이후 변경은 PR 설명에 이유를 적습니다.

```swift
enum QuizCategory: String, Codable, CaseIterable {
    case aiUsage, swiftSyntax, hig, swiftUIPractice
}

enum Difficulty: String, Codable, CaseIterable {
    case easy, normal, hard
    /// 세션 성공 시 지급하는 장식 수 (쉬움 1, 보통 2, 어려움 3)
    var rewardDecorations: Int { /* 1, 2, 3 */ }
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

@Model final class QuizSession {
    @Attribute(.unique) var id: UUID
    var category: QuizCategory
    var difficulty: Difficulty
    var questionIDs: [UUID]           // 출제 순서 고정
    var currentIndex: Int
    var status: SessionStatus
    var passThresholdPercent: Int     // 시작 시점의 기준값을 저장
    var startedAt: Date
    var finishedAt: Date?
    var earnedDecorations: Int        // 완료 시 확정
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
    var decorationCount: Int          // 0...12 (이월된 장식 포함)
    var sessionCount: Int             // 이 트리를 만드는 데 쓴 성공 세션 수
}
```

규칙
- 현재 트리는 `completedAt == nil`인 `TreeRecord` 한 개입니다. 앱 첫 실행 때 생성합니다.
- 문제별 정답률, 마지막 풀이 시각은 `SessionAnswer`에서 계산하고 별도 통계 모델은 두지 않습니다. 중복 저장으로 값이 어긋나는 것을 막기 위해서입니다.
- 정답률 기준은 세션을 시작할 때의 값을 세션에 저장합니다. 도중에 설정을 바꿔도 이번 세션은 영향받지 않습니다.
- 모델의 옵셔널 필드는 모두 안전하게 처리합니다(11장).

### 8-1. 시드 데이터
- 앱 번들의 JSON 파일(`Seed/questions.json`)을 첫 실행 때 SwiftData에 넣습니다. 같은 `id`가 이미 있으면 건너뜁니다.
- JSON 필드는 `Question` 모델 필드와 이름을 같게 맞춥니다. 이미지와 영상은 번들 에셋 파일명을 씁니다.
- 분량: 작업 4개 × 난이도 3개 × 구간당 최소 5문제 = **60문제 이상**
- 문제 작성은 팀원이 나눠서 하고, 한 구간의 형식이 통일되도록 작성 가이드(해설 길이, 보기 개수, 태그 규칙)를 `docs/question-guide.md`에 정합니다. **[가정]**

## 9. 모듈 인터페이스

각자 이 이름과 시그니처로 만들면 합칠 때 어긋나지 않습니다. 구현 안의 세부는 자유입니다.

```swift
/// 작업(카테고리) 추천
protocol TaskRecommending {
    func recommendedCategory(sessions: [QuizSession]) -> QuizCategory
}

/// 세션용 문제 선택 (7-3 비율)
protocol QuestionSelecting {
    func select(
        category: QuizCategory,
        difficulty: Difficulty,
        count: Int,
        questions: [Question],
        history: [SessionAnswer]
    ) -> [Question]
}

/// 세션 생성·진행·종료. SwiftData 저장을 담당
protocol SessionManaging {
    func startSession(category: QuizCategory, difficulty: Difficulty, count: Int) throws -> QuizSession
    func submit(answerIndex: Int, for session: QuizSession) throws -> SessionAnswer
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
    let earnedDecorations: Int         // 기준 미만이면 0, 아니면 난이도별 지급 수 (이월분 포함)
    let treeCompleted: Bool            // 이번 세션으로 트리가 완성되었는가
    let carriedOver: Int               // 새 트리로 이월된 장식 수
    let wrongAnswers: [SessionAnswer]
}

/// 장식 지급과 트리 완성 처리
protocol TreeManaging {
    func currentTree() -> TreeRecord
    /// 장식을 지급한다. 12칸이 차면 완성 처리 후 새 트리를 시작하고, 남은 장식은 새 트리로 이월한다
    func grant(decorations: Int) -> TreeGrantResult
    func completedTrees() -> [TreeRecord]
}

/// 효과음과 햅틱
protocol FeedbackPlaying {
    func playCorrect()
    func playWrong()
    func playTreeComplete()
}

/// 장식 지급 결과
struct TreeGrantResult {
    let completedTree: TreeRecord?     // 이번 지급으로 완성된 트리 (없으면 nil)
    let carriedOver: Int               // 새 트리로 이월된 장식 수
    let currentDecorationCount: Int    // 지급 후 현재 트리의 장식 수
}

/// 애니메이션 문제 한 단계
struct TraceStep {
    let line: Int                       // 하이라이트할 코드 줄 (1부터)
    let narration: String               // 말풍선과 VoiceOver 설명
    let variables: [String: String]     // 이 단계 이후의 변수 값
    let sceneAction: TraceSceneAction   // 캐릭터와 배경의 동작
}

/// animationID로 장면과 실행 순서를 찾는 저장소
protocol TraceSceneRegistry {
    func scene(for animationID: String) -> (steps: [TraceStep], view: AnyView)?
}
```

- 조회 결과가 없을 수 있는 값(`resumableSession`, `scene`)은 옵셔널로 반환하고 호출하는 쪽에서 안전하게 처리합니다.
- 설정값은 서비스가 직접 `@AppStorage`를 읽지 않고, 호출하는 쪽에서 값을 넘기거나 `SettingsStore`(UserDefaults 래퍼)를 주입합니다. **[가정]** 테스트하기 쉽게 하기 위해서입니다.

## 10. 폴더 구조 (제안)

```
Santa'sDeliveryCrisis/
  App/                  앱 진입점, 탭 구성
  Models/               SwiftData 모델, enum
  Services/             세션, 추천, 출제, 트리, 피드백
  Features/
    Task/               S1, S2, S3, S8
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

| 에셋 | 형식 | 담당 | 비고 |
| --- | --- | --- | --- |
| 산타, 루돌프, 장면 캐릭터 | PNG 또는 PDF 벡터 | 팀 내 지정 | 애니메이션 장면용 |
| 트리, 장식 12종, 배경 | PNG 또는 PDF 벡터 | 팀 내 지정 | 장식 위치 좌표는 8장 모델이 아닌 뷰 코드에서 관리 |
| 효과음(정답, 오답, 완성) | wav 또는 m4a | 팀이 직접 제작 | 저작권 문제가 없는 소스만 사용 |
| 앱 아이콘 | 1024px | 팀 내 지정 | |

색상은 라이트/다크 모두 Asset 카탈로그에 정의합니다.

## 13. 비기능 요구사항

- **크래시 방지:** 11-1의 규칙을 지킵니다. 빈 배열 접근, 범위 밖 인덱스를 조심합니다. `choices.count != 4`인 문제는 편집 단계에서 저장할 수 없게 하고, 시드 로드 단계에서 건너뛰며 로그를 남깁니다.
- **성능:** 목록은 `List`나 `LazyVStack`을 씁니다. 큰 영상은 미리 로드하지 않고 해당 문제 화면에서만 로드합니다.
- **오프라인:** 네트워크 없이 모든 기능이 동작해야 합니다. 학습 자료 링크는 Safari로 여는 외부 링크이며, 오프라인이면 열리지 않습니다.
- **테스트:** 순수 로직(`TaskRecommender`, `QuestionSelector`, 보상 계산, 트리 완성)은 단위 테스트를 만듭니다.

## 14. 완료 기준 (마감 2026-11-22)

- [ ] iPhone과 iPad에서 시뮬레이터로 실행해 아래 흐름이 처음부터 끝까지 동작합니다.
  1. 작업 선택 → 난이도·문제 수 선택 → 퀴즈 진행 → 결과 → 장식 지급
  2. 장식 12칸을 채워 트리 완성 → 보관함에 기록
  3. 문제 생성/수정/삭제 (사용자가 만든 문제 기준. 시드 문제의 수정·삭제 버튼은 비활성화 상태로 표시)
  4. 기록 대시보드에서 통계와 완성 기록 확인
- [ ] 앱을 세션 도중 종료해도 "이어서 풀기"로 복구됩니다.
- [ ] 애니메이션 문제가 3개 이상 유형으로 동작합니다.
- [ ] 라이트/다크 모드가 모두 자연스럽게 표시됩니다.
- [ ] 가장 큰 Dynamic Type에서 주요 화면이 깨지지 않습니다.
- [ ] 시드 문제가 60문제 이상 들어 있습니다.
- [ ] README(기능, 설치 방법, 의존 라이브러리, 폴더 구조), 주요 흐름(작성-조회-통계) 스크린샷·GIF, 공개 API 문서화 주석이 완성되었습니다.
- [ ] 크래시가 없고, 강제 언래핑이 코드에 없습니다.

## 15. 작업 분리

작업 0이 끝나기 전에는 다른 작업이 서로 의존합니다. 작업 0만 먼저 진행하고, 나머지는 병렬로 진행합니다.

| 번호 | 작업 | 포함 | 의존 | 병렬 가능 |
| --- | --- | --- | --- | --- |
| 0 | 기반 | Xcode 프로젝트 설정(iOS 17, iPad 방향), 폴더 구조, 8장 모델, enum, 색상 Asset 기본 틀, 탭 뼈대 | 없음 | 가장 먼저, 가능한 한 빨리 develop에 병합 |
| 1 | 시드 데이터 | 시드 JSON 스키마, 로더, 첫 실행 주입, 문제 작성(60문제 이상) | 0 | 문제 작성은 작업 0 중에도 시작 가능 |
| 2 | 세션 로직 | `QuestionSelector`, `TaskRecommender`, `SessionManager`, 보상 계산, `TreeManager`, 단위 테스트 | 0 | 1, 3, 4와 병렬 |
| 3 | 퀴즈 화면 | S4, S5, S6, S7, 피드백(햅틱, 효과음), 이어서 풀기 UI | 0, 2의 프로토콜 | 2의 구현 전에는 가짜(mock) 구현으로 개발 |
| 4 | 작업·트리 화면 | S1, S2, S3, S8, 트리 렌더링, 장식 배치, 완성 연출 | 0, 2의 프로토콜 | |
| 5 | 애니메이션 문제 | `TraceStep`, 코드 하이라이트·변수 표시·말풍선 컴포넌트, 장면 3~5개, 접근성(모션 줄이기, VoiceOver) | 0, 에셋 | 3의 S4와 연결하는 시점만 조율 |
| 6 | 기록·설정 | S9(차트), S12, @AppStorage 키 | 0 | |
| 7 | 문제 관리 | S10, S11, 사진 보관함 선택, 파일 복사 저장 | 0 | |
| 8 | 에셋·사운드 | 캐릭터, 트리, 장식, 배경, 효과음, 앱 아이콘 | 없음 | 처음부터 병렬 |
| 9 | 마감 | README, 스크린샷·GIF, 문서화 주석 점검, 접근성·iPad 점검, 크래시 점검 | 전체 | 마지막 |

연결 지점 (여기가 어긋나기 쉽습니다)
- 작업 3, 4는 작업 2의 프로토콜(9장)만 보고 개발하고, 실제 구현이 준비되면 교체합니다.
- 작업 5는 작업 3의 S4가 문제 종류에 따라 애니메이션 뷰를 끼워 넣을 자리(`kind == .animation`)를 만들어 둡니다.
- 작업 1의 시드 JSON과 작업 7의 편집 화면은 같은 `Question` 모델 필드를 씁니다. 필드를 바꾸면 양쪽에 알립니다.

## 16. 확인이 필요한 가정

위에서 **[가정]** 으로 표시한 것 중 영향이 큰 항목입니다. 틀린 곳이 있으면 알려 주세요.

1. **탭 3개(작업/기록/관리):** "출제" 탭을 작업 탭 안의 "오늘의 출제" 버튼으로 줄였습니다.
2. **반응형 비율의 "선호 카테고리 30%":** 작업을 고르면 카테고리가 하나로 정해지므로 "선호 태그"로 바꿨습니다.
3. **작업 추천 점수식:** 취약도 70%, 선호도 30%, 최근 30일 기록 기준입니다. 숫자는 임의로 정한 값입니다.
4. **힌트 버튼:** 문제에 힌트 필드가 있어서 S4에 [힌트] 버튼을 넣었습니다. 원치 않으면 뺍니다.
5. **진행 중 세션은 1개만 허용**, 새로 시작하면 기존 세션은 `abandoned` 처리합니다.
6. **글꼴 크기와 테마 설정을 앱 안에 두지 않음:** 시스템의 Dynamic Type과 라이트/다크를 따릅니다.
7. **iPad 퀴즈 화면:** 가로에서도 중앙 컬럼 폭을 제한합니다.
