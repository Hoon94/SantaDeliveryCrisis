# 세션·저장 서비스 사용 가이드 (A 담당 구현)

B, C, D가 화면에서 출제·세션·트리 서비스를 부를 때 참고하는 문서입니다. 규칙의 기준은 [02-session-engine](specs/02-session-engine.md)이고, 이 문서는 구현된 동작과 호출 순서를 정리합니다.

- 서비스는 `@Environment(\.services)`로 받습니다. 화면 코드가 서비스 구현 클래스를 직접 만들지 않습니다.
- 실제 구현은 `AppServices.make(context:)`에서 조립합니다. 미리보기는 가짜 묶음(`AppServices.preview`) 또는 실제 서비스(`PreviewData.make()`, 디버그 빌드 전용)를 씁니다.

## 1. 서비스 목록

| 서비스 | 규약 | 구현 | 역할 |
| --- | --- | --- | --- |
| `services.selector` | `QuestionSelecting` | `QuestionSelector` | 문제 고르기, 후보 수 계산 |
| `services.recommender` | `TaskRecommending` | `TaskRecommender` | [추천] 배지 카테고리 계산 |
| `services.sessions` | `SessionManaging` | `SessionManager` | 세션 시작, 답 저장, 완료, 이어 풀기, 포기 |
| `services.trees` | `TreeManaging` | `TreeManager` | 현재 트리, 완성 트리 목록 (장식 지급은 `finish` 안에서 처리) |

## 2. 호출 순서

### 세션 시작 (C)
```swift
// 1) 진행 중 세션이 있는지 먼저 확인한다.
if let resumable = services.sessions.resumableSession() {
    // "이어서 풀기" 또는 "새로 시작" 선택 화면(S2-A1)
    // 새로 시작을 고르면 확인(S2-A2) 뒤에:
    try services.sessions.abandon(resumable)
}
// 2) 시작한다. 오류는 S2-E1에 연결한다.
let session = try services.sessions.startSession(
    category: .swiftSyntax, difficulty: .normal, tags: [], count: 5
)
```

### 장식 켜짐과 추천 배지 (C)
```swift
// 카테고리마다 호출한다. 1 이상이면 장식을 켠다.
let count = services.selector.availableCount(
    category: category, difficulty: difficulty, tags: [], questions: questions
)
// 추천 배지. nil이면 배지를 표시하지 않는다.
let recommended = services.recommender.recommendedCategory(sessions: sessions)
```
`questions`와 `sessions`는 화면에서 `@Query`로 조회해 넘깁니다.

### 퀴즈 진행 (B)
```swift
// 문제 번호는 0부터. [확인]을 누를 때마다 한 번 호출한다.
let answer = try services.sessions.submit(answerIndex: selected, forQuestionAt: index, in: session)
answer.isCorrect   // 정오답

// 마지막 문제까지 답을 저장한 뒤
let result = try services.sessions.finish(session)
result.earnedDecorations   // 0 또는 1
result.treeCompleted       // true면 트리 완성 연출
```
문제 내용은 원본 `Question`이 아니라 `session.questionSnapshots[index]`에서 읽습니다.

### 이어 풀기 (B, C)
- 복원 위치는 `session.answers.count`번째 문제입니다. `currentIndex`와 다르면 `answers.count`를 따릅니다.
- 모든 문제의 답이 저장된 상태라면 문제 화면 없이 `finish`를 호출합니다.

### 트리와 기록 (C, D)
```swift
services.trees.currentTree().decorationCount    // 0...12
services.trees.completedTrees()                 // 완성한 트리, 최근 완성 순
```

## 3. 동작 규칙 요약

| 상황 | 동작 |
| --- | --- |
| 같은 문제에 `submit`을 다시 호출 | 처음 저장된 답을 그대로 돌려주고 새로 저장하지 않음(값이 달라도 유지) |
| 앞선 문제에 답하지 않고 뒤 문제를 제출 | `previousQuestionUnanswered` 오류 |
| `finish`를 두 번 호출 | 저장된 결과를 돌려주고 장식을 다시 지급하지 않음 |
| 모든 문제에 답하기 전에 `finish` | `notAllAnswered` 오류 |
| 진행 중 세션이 있는데 `startSession` | `sessionAlreadyInProgress` 오류 |
| 조건에 맞는 문제가 0개 | `noCandidates` 오류 |
| 후보가 요청한 문제 수보다 적음 | 가능한 만큼만 출제 `[가정]` |
| 저장 실패 | 바뀐 값을 되돌리고 오류를 던짐. 세션은 `inProgress`로 남아 재시도 가능 |

오류는 모두 `SessionError`이며 한국어 설명(`error.localizedDescription`)이 있습니다.

## 4. 기준값과 계산 규칙

기준값은 `Services/SelectionCriteria.swift`에 있습니다.

| 기준 | 값 |
| --- | --- |
| 약한 문제 | 정답률 60% **미만**, 또는 마지막 풀이가 오답 |
| 오래 안 푼 문제 | 마지막 풀이가 5일 **이상** 지남(하루 = 24시간). 한 번도 안 푼 문제도 이 범주 |
| 보상 | 세션 시작 때 저장된 정답률 기준 **이상**이면 장식 1개 |

- 출제: 약한 문제와 오래 안 푼 문제를 절반씩 고릅니다. 5문제는 3·2, 10문제는 5·5, 15문제는 8·7입니다. 한 범주가 모자라면 다른 범주에서 채웁니다.
- 정답률은 **내림**해서 정수 퍼센트로 보여 줍니다(7/9 = 77%). 팀 합의 사항이며 규칙은 `Services/Accuracy.swift`에 있습니다. 기록 화면의 평균 점수와 카테고리별 정답률도 `Accuracy.percent(correct:total:)`를 쓰면 같은 값이 나옵니다.
- 보상 판정은 정확하게 비교합니다(79.5%는 79%로 보이고 80% 기준 미달). 내림한 값이 기준 이상이면 정확한 값도 기준 이상이라, 기준 이상으로 보이는데 장식을 못 받는 경우는 없습니다.
- 추천: 답한 기록이 있는 카테고리 중 정답률이 가장 낮은 곳. 동률이면 작업 순서(소원 접수, 선물 생산, 포장, 썰매 적재)가 앞선 곳, 기록이 없으면 `nil`.

## 5. 시드 문제

- 앱 시작 때 `MyApp`이 `SeedLoader.seed(into:)`를 호출합니다. 같은 `id`가 이미 있으면 건너뛰므로 여러 번 실행해도 중복되지 않습니다.
- 검증에 실패하면 문제를 하나도 넣지 않고 로그에 오류 목록을 남깁니다.
- 검증 항목: id 중복, 빈 문제·해설, 보기 4개와 빈 보기·같은 보기, 정답 번호 0~3, 빈 태그, 자료 URL 형식(http/https), 애니메이션 문제의 `animationID`.
- 분량 점검(조합당 5문제 이상)은 `SeedLoader.coverageShortfalls`로 확인합니다.
- 문제를 추가할 때는 각자 별도 JSON으로 작성하고 A가 `questions.json`에 합칩니다. 같은 파일을 동시에 고치면 충돌합니다.

## 6. 개발 도구

- **실제 서비스로 미리보기**: `PreviewData.make()`(디버그 빌드 전용)는 메모리 저장소에 시드 문제를 넣고 실제 서비스를 조립합니다.
  ```swift
  #Preview {
      let preview = PreviewData.make()
      TaskHomeView()
          .modelContainer(preview.container)
          .environment(\.services, preview.services)
  }
  ```
- **서비스 점검**: `Tools/service-check/run.sh`가 출제, 추천, 세션, 트리, 시드 로직을 Xcode 없이 점검합니다. `VERBOSE=1`을 앞에 붙이면 통과한 항목도 보입니다. SwiftData 실제 동작은 확인하지 않으므로 Xcode 빌드와 실행은 따로 해야 합니다.

## 7. 아직 정해지지 않은 것

| 항목 | 상태 |
| --- | --- |
| 소요 시간(`elapsedSeconds`) 저장 방식 | 규약에 저장 함수가 없음. B와 협의 필요 |
| 사용자가 삭제한 시드 문제 | 앱을 다시 켜면 `SeedLoader`가 다시 넣음. D와 협의 필요 |
| "하루" 계산 기준, "최근 오답"의 범위 | 팀 확인 필요 |
| 기록 화면의 점수 계산 | 내림으로 합의함. D가 `RecordsStatistics`를 `Accuracy`와 같은 내림으로 맞추는 중 |
| 단위 테스트 타깃과 프레임워크 | `app-foundation` 결정 대기. 확정되면 `Tools/service-check/main.swift`의 시나리오를 옮김 |
