# Implementation Plan: app-foundation

## Overview

이 계획은 `requirements.md`와 `design.md`를 기준으로, 다른 모든 Spec이 의존하는 앱 기반(프로젝트 설정, 폴더 구조, 모델, 프로토콜, mock, `SettingsStore`, `MediaFileManager`, `AppContainer`, 색상 Asset, 탭 뼈대, 테스트 타깃)을 만드는 코드 작업을 의존 순서대로 나열합니다. 모델과 프로토콜의 이름, 필드, 시그니처는 `project-spec.md` 8장과 9장이 기준이며, 이 문서는 다시 복사하지 않고 절 번호와 타입 이름으로 참조합니다.

진행 원칙은 다음과 같습니다.

- 구현 언어는 Swift입니다(design.md가 Swift 타입과 API로 작성되어 있어서 별도 언어 선택 질문은 하지 않습니다).
- **팀 결정 대기 항목(Q1~Q6, 속성 테스트 방식)을 조용히 결정하지 않습니다.** 1번 작업의 결정 확인 작업에서 사용자에게 먼저 묻고, 답을 받기 전에는 해당 항목에 의존하는 작업을 시작하지 않습니다. 확정된 내용은 `project-spec.md` 16장 반영 여부를 사용자에게 확인합니다.
- 외부 라이브러리는 쓰지 않습니다. 속성 테스트(Property N)는 design.md 추천안 B(라이브러리 없이 매개변수화 테스트와 고정 시드 의사 난수 생성기)를 기본으로 하되, 1.1에서 사용자가 확정한 방식을 따릅니다.
- Xcode 프로젝트 설정 변경과 파일 추가는 같은 프로젝트 파일을 건드릴 수 있으므로, 아래 의존성 그래프에서 병렬로 가정하지 않고 파도(wave)를 나눠 순서를 명시했습니다.
- 이 문서의 모든 작업은 아직 실행되지 않았으며, 빌드나 테스트가 통과했다는 것을 뜻하지 않습니다. 각 작업의 "검증"은 구현 후 실제로 실행해서 확인할 기준입니다.
- 선택(`*`) 표시가 붙은 테스트 하위 작업은 건너뛸 수 있지만, 12번 통합 검증은 요구사항 9.3 때문에 최소한 round-trip, 멱등성, 기본값 테스트가 있어야 완료로 표시할 수 있습니다. 이 테스트를 건너뛰면 요구사항 9.3이 충족되지 않았음을 PR 설명에 적습니다.

## Tasks

- [ ] 1. 결정 확인 (구현 전 사용자에게 먼저 확인)
  - [ ] 1.1 Q2 테스트 프레임워크와 속성 테스트 방식 확인
    - `user_input`으로 XCTest와 Swift Testing 중 무엇을 쓸지 묻는다. Swift Testing을 고르면 Xcode 27.2와 iOS 17 배포 타깃에서 동작하는지 확인해서 알린다.
    - 속성 테스트 방식(design.md 선택지 A 외부 라이브러리, B 매개변수화 테스트와 고정 시드 생성기, C 예시 테스트만)을 묻는다. 추천은 B이며, A는 steering 3장 변경이 필요하다고 알린다.
    - 답을 받기 전에는 테스트 타깃(2.2)과 테스트 파일(3.3 이후의 `*` 작업)을 만들지 않는다.
    - 검증: 사용자의 답이 이 작업 아래에 기록되어 있고, 이후 테스트 작업이 그 답을 따른다.
    - _Requirements: 9.1, 9.3 (열린 질문 Q2, design.md "속성 테스트 구성")_

  - [ ] 1.2 Q4 mock 위치와 Q5 `@MainActor`/`ModelContext` 접근 방식 확인
    - mock 파일 위치 기본안(`Services/Mocks/`)을 사용자에게 확인한다.
    - 프로토콜 9장에 `@MainActor`를 붙일지, `MediaFileManager`가 `ModelContext`를 어떤 방식(`ModelContext` 또는 `ModelContainer` 주입)으로 받을지 묻는다. 이 결정은 `session-engine` Spec의 구현에도 영향을 주므로 담당자와 합의가 필요하다고 알리고, 합의가 끝나기 전에는 4.2의 프로토콜 격리 한정자와 7.2의 컨텍스트 접근 방식을 확정하지 않는다.
    - 검증: 사용자 답(또는 "session-engine과 합의 후 확정" 결정)이 기록되어 있다.
    - _Requirements: 2.6, 4.1, 5.6, 7.2 (열린 질문 Q4, Q5)_

  - [ ] 1.3 Q6 기존 `MyApp.swift`, `ContentView.swift` 이동·삭제 범위 확인
    - 기본안(`App/`로 옮겨 진입점을 `AppContainer`와 `RootTabView`로 연결하고, 쓰지 않는 `ContentView.swift`는 제거)을 사용자에게 보여 주고 확인을 받는다.
    - 확인 전에는 이 두 파일을 이동하거나 삭제하지 않는다.
    - 검증: 사용자 확인이 기록되어 있다.
    - _Requirements: 2.4 (열린 질문 Q6)_

  - [ ] 1.4 Q3 색상 세트 이름과 개수 확인, Q1 현재 트리 생성 담당 재확인
    - 색상 세트 이름 목록(예: 배경, 강조, 정답, 오답)과 라이트/다크 값을 사용자에게 묻는다. 확정 전에는 구체적인 색상 이름과 값을 정하지 않는다.
    - Q1(첫 실행 때 현재 트리 생성 담당)은 foundation 범위 밖(요구사항 7.10)이라는 기본안을 사용자에게 다시 알리고, 달라지면 요구사항을 먼저 고친다.
    - 검증: 색상 세트 이름 목록이 기록되어 있다(없으면 9.1 작업은 시작하지 않는다).
    - _Requirements: 7.10, 8.8 (열린 질문 Q1, Q3)_

- [ ] 2. Xcode 프로젝트 설정과 폴더 구조
  - [ ] 2.1 앱 타깃 빌드 설정 변경 (배포 타깃, 지원 기기, 방향)
    - 실제 프로젝트 파일(`Santa'sDeliveryCrisis.xcodeproj` 아래 `project.xcproj`)을 먼저 열어 구조를 확인한다(design.md가 일반적인 `project.pbxproj`와 이름이 다르다고 표시함).
    - Debug와 Release 모두 `IPHONEOS_DEPLOYMENT_TARGET = 17.0`, `TARGETED_DEVICE_FAMILY = 1,2`로 설정한다.
    - iPhone 방향은 세로 한 가지, iPad 방향은 세로와 가로 왼쪽·오른쪽으로 설정한다(현재 Xcode가 생성하는 `INFOPLIST_KEY_UISupportedInterfaceOrientations_*` 이름으로 확인).
    - 외부 패키지 의존성이 없는지 확인하고, 소스 폴더가 폴더 멤버십(파일 시스템 동기화 그룹)으로 등록된 상태인지 확인한다.
    - 검증: `xcodebuild -showBuildSettings`(앱 타깃)에서 배포 타깃 `17.0`, 기기 `1,2`, 방향 값이 위 기준과 같다. 앱 타깃 클린 빌드가 오류 0건으로 끝난다.
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_

  - [ ] 2.2 테스트 타깃 추가 (1.1 결정 후)
    - 1.1에서 확정한 프레임워크로 앱 타깃을 대상으로 하는 단위 테스트 타깃을 정확히 1개 추가한다. 배포 타깃은 Debug와 Release 모두 `17.0`으로 맞추고, `@testable import`로 앱 타깃을 참조할 수 있게 한다.
    - 검증: `xcodebuild -showBuildSettings`(테스트 타깃)에서 배포 타깃이 `17.0`이고, 앱 타깃과 테스트 타깃 클린 빌드가 오류 0건이며 샘플 테스트 1개가 실행된다.
    - _Requirements: 1.1, 1.5, 1.8, 9.1, 9.2_

  - [ ] 2.3 12개 폴더 생성과 `Assets.xcassets` 이동
    - 소스 폴더 바로 아래에 `App`, `Models`, `Services`, `Features/Task`, `Features/Quiz`, `Features/Trace`, `Features/Records`, `Features/Manage`, `Features/Settings`, `Resources/Seed`, `Resources/Sounds`, `Extensions`를 10장과 철자·대소문자가 같게 만든다.
    - `Assets.xcassets`를 `Resources/` 바로 아래로 옮긴다(기존 `AccentColor.colorset` 유지 여부는 사용자에게 확인하지 않고 그대로 옮기며, 내용은 바꾸지 않는다).
    - 파일이 없는 폴더에 `.gitkeep`을 1개씩 둔다.
    - 검증: `git ls-files`에 12개 폴더 경로가 모두 나타나고, 소스 폴더 바로 아래에 `Assets.xcassets`가 없다. 앱 타깃 빌드가 폴더나 파일 참조 경고 없이 끝난다.
    - _Requirements: 2.1, 2.2, 2.3, 2.8, 2.9_

  - [ ] 2.4 기존 진입점 파일 이동과 정리 (1.3 확인 후에만)
    - 1.3에서 사용자가 확인한 범위대로 `MyApp.swift`를 `App/`으로 옮기고(또는 교체), `ContentView.swift`를 처리한다. 확인된 범위를 넘어서 이동·삭제하지 않는다.
    - 이 시점에서는 앱이 빌드되고 실행 가능한 최소 상태만 유지한다(실제 연결은 8.1과 10.2에서 한다).
    - 검증: 앱 타깃 빌드가 오류 0건이고, `App/` 폴더에 진입점 파일이 있으며, 소스 폴더 바로 아래에 진입점 파일이 남아 있지 않다.
    - _Requirements: 2.4, 2.8_

  - [ ] 2.5 테스트 공용 도우미 작성 (격리 규칙)
    - 테스트 타깃에 메모리 전용 `ModelContainer`(4개 모델 등록) 생성 함수, 테스트별 임시 폴더 생성·삭제 함수, 테스트별 고유 suite 이름의 `UserDefaults` 생성·삭제 함수를 만든다.
    - 속성 테스트용 고정 시드 의사 난수 생성기를 만든다(1.1에서 B를 확정한 경우에만). 실패 시 입력 값을 출력해서 재현할 수 있게 한다.
    - 검증: 도우미를 쓰는 샘플 테스트가 2회 연속 실행해도 같은 결과로 통과하고, 종료 후 임시 폴더와 suite가 남아 있지 않다. (3.2가 끝난 뒤에 컨테이너 생성 부분을 확인한다.)
    - _Requirements: 9.4, 9.5_

- [ ] 3. 데이터 모델과 enum
  - [ ] 3.1 enum 4개와 `Difficulty.rewardDecorations` 구현 (`Models/Enums.swift`)
    - `QuizCategory`, `Difficulty`, `QuestionKind`, `SessionStatus`를 8장의 케이스 이름, 선언 순서, `String` raw 값, `Codable`, (`QuizCategory`, `Difficulty`는) `CaseIterable`로 만든다.
    - `rewardDecorations`는 easy 1, normal 2, hard 3을 돌려준다. 모든 공개 타입과 멤버에 `///` 문서화 주석을 단다.
    - 검증: 앱 타깃 빌드 성공. (테스트는 3.3)
    - _Requirements: 3.1, 3.2, 3.10_

  - [ ] 3.2 SwiftData 모델과 `QuestionSnapshot` 구현 (`Models/`)
    - `Question`, `QuizSession`, `SessionAnswer`, `TreeRecord`를 `@Model final class`로, `QuestionSnapshot`을 15개 필드의 `Codable` struct로 8장 그대로 만든다. `@Attribute(.unique)`는 `Question.id`, `QuizSession.id`, `TreeRecord.id`에, `@Relationship(deleteRule: .cascade)`는 `QuizSession.answers`에 적용한다.
    - 8장에 없는 모델, 필드, 케이스는 추가하지 않는다. `QuestionSnapshot` 배열을 SwiftData가 `QuizSession`에 저장하는 방식이 동작하지 않으면 임의로 모델을 바꾸지 말고 공통 계약 변경 절차(`integration-contracts.md` 4장)로 사용자에게 올린다.
    - 모든 공개 타입과 필드에 `///` 문서화 주석을 단다.
    - 검증: 앱 타깃 빌드 성공, 메모리 전용 `ModelContainer`에 4개 모델을 등록해 컨테이너가 생성된다(3.3에서 테스트).
    - _Requirements: 3.3, 3.4, 3.5, 3.6, 3.10_

  - [ ]* 3.3 모델과 enum 예시 단위 테스트
    - 테스트 이름 예: `enumsMatchSpec`, `rewardDecorationsValues`, `containerCreatesWithFourModels`, `duplicateQuestionIdKeepsOneRecord`.
    - enum `allCases` 순서와 raw 값 전수, `rewardDecorations` 1/2/3, 4개 모델 등록 컨테이너 생성, 같은 `id`의 `Question`을 두 번 저장했을 때 레코드 1개를 확인한다.
    - 검증: 테스트 통과.
    - _Requirements: 3.1, 3.2, 3.6, 3.9_

  - [ ]* 3.4 Property 1 테스트: 세션 저장 round-trip
    - **Property 1: 세션 저장 round-trip**
    - 스냅샷 2개 이상, 답 1개 이상, 옵셔널 필드가 `nil`인 경우와 값이 있는 경우를 섞은 입력을 고정 시드 생성기로 100개 이상 만들어 저장한 뒤 새 `ModelContext`에서 읽어 모든 필드를 비교한다.
    - 테스트 이름 예: `property1_sessionRoundTrip`. 파일 첫머리에 `Feature: app-foundation, Property 1: 세션 저장 round-trip` 주석 태그를 단다.
    - **Validates: Requirements 3.7**

  - [ ]* 3.5 Property 2 테스트: 세션 삭제의 cascade 범위
    - **Property 2: 세션 삭제의 cascade 범위**
    - 세션 여러 개와 답 개수를 바꿔 가며, 한 세션 삭제 후 그 세션의 `SessionAnswer`만 사라지고 다른 세션의 답과 모든 `Question`이 남는지 확인한다.
    - 테스트 이름 예: `property2_cascadeScope`. 주석 태그 `Feature: app-foundation, Property 2`.
    - **Validates: Requirements 3.8**

- [ ] 4. 프로토콜과 결과 타입
  - [ ] 4.1 결과 타입 구현 (`Services/Results/`)
    - `SessionResult`(필드 8개), `TreeGrantResult`(필드 3개), `TraceStep`(필드 4개), `TraceSceneAction`(`.none` 한 개)을 9장의 이름과 타입 그대로 만든다. 모든 공개 타입에 `///` 주석을 단다.
    - 검증: 앱 타깃 빌드 성공.
    - _Requirements: 4.2, 4.3, 4.4, 4.5_

  - [ ] 4.2 프로토콜 7개 구현 (`Services/Protocols/`)
    - `TaskRecommending`, `QuestionSelecting`, `SessionManaging`, `TreeManaging`, `FeedbackPlaying`, `MediaFileManaging`, `TraceSceneRegistry`를 9장의 이름, 메서드 이름, 매개변수, 반환 타입, `throws` 그대로 파일 단위로 나눠 만든다. 9장에 없는 멤버는 추가하지 않는다.
    - `///` 주석에 design.md "프로토콜 계층" 표의 동작 계약(`submit`의 순서·중복·단일 저장, `finish`의 재호출·단일 저장·실패 시 `inProgress` 유지, `grant`의 save 미호출, `store`의 새 이름 복사, `cleanUnreferencedFiles`의 ①②③ 규칙, `select`의 `tags` 규칙, `scene(for:)`의 `nil`)을 그대로 옮긴다.
    - **주의(Q5):** `@MainActor` 등 격리 한정자는 1.2의 결정(session-engine과 합의)이 확정되기 전에는 붙이지 않는다.
    - 검증: 앱 타깃 빌드 성공, 프로토콜 7개와 메서드 시그니처가 9장과 일치하는지 리뷰 체크리스트로 확인한다.
    - _Requirements: 4.1, 4.4, 4.5_

- [ ] 5. mock 구현
  - [ ] 5.1 mock 6종 구현 (1.2에서 확정한 위치, 기본안 `Services/Mocks/`)
    - `MockTaskRecommender`, `MockQuestionSelector`, `MockSessionManager`, `MockTreeManager`, `MockFeedbackPlayer`, `MockTraceSceneRegistry`를 각각 해당 프로토콜을 채택하게 선언한다. 모두 인자 없이 `init()`으로 생성되고 생성 중 오류를 던지지 않으며, SwiftData, 파일, 네트워크, 오디오, 햅틱에 접근하지 않고 같은 입력에 같은 값을 돌려준다.
    - `MockSessionManager`는 생성 시 `hasResumableSession`(기본 `false`)으로 `resumableSession()`이 `nil`인지 세션 1개인지 고르게 한다. `startSession`, `submit`, `finish`, `abandon`과 `MockTreeManager.grant`는 기본으로 성공 값을 돌려준다. `MockTraceSceneRegistry.scene(for:)`는 모르는 ID(빈 문자열 포함)에 `nil`을 돌려준다.
    - 모든 mock에 `Mock` 접두사 타입 이름과 `///` 주석으로 mock임을 표시한다. `@Model` 인스턴스를 컨텍스트 없이 만들어도 문제가 없는지 확인하고, 문제가 있으면 mock 내부에 메모리 전용 컨테이너를 두는 방식으로 바꾼다(design.md 유의점).
    - 검증: 앱 타깃 빌드 성공(시그니처가 어긋나면 컴파일 실패), SwiftUI 미리보기에서 인자 없이 생성된다.
    - _Requirements: 4.6, 4.7, 4.8, 4.9, 4.10, 4.11, 4.12, 4.13_

  - [ ]* 5.2 mock 예시 테스트와 Property 3 테스트
    - **Property 3: 알 수 없는 animationID는 nil**
    - 예시 테스트: `mockSessionManagerResumableNilAndValue`, `mockSessionManagerThrowingMethodsSucceed`, `mockTreeManagerReturnsDeclaredTypes`, `mockFeedbackPlayerCountsCalls`.
    - 속성 테스트 `property3_unknownAnimationIdReturnsNil`: 빈 문자열, 공백, 유니코드, 매우 긴 문자열을 포함한 입력 100개 이상에서 `scene(for:)`가 크래시 없이 `nil`을 돌려주는지 확인한다.
    - **Validates: Requirements 4.10**
    - _Requirements: 4.9, 4.13, 9.6_

- [ ] 6. SettingsStore
  - [ ] 6.1 `SettingsStore` 구현 (`Services/Settings/SettingsStore.swift`)
    - `init(defaults: UserDefaults = .standard)`로 주입받은 인스턴스에만 읽고 쓴다. 키 4개(`hasLaunchedBefore`, `passThresholdPercent`, `soundEnabled`, `hapticsEnabled`)와 기본값(false, 80, true, true)을 외부에서 접근 가능한 상수(예: `SettingsStore.Key`, `SettingsStore.Default`)로 공개하고, 4개 외의 키는 만들지 않는다.
    - Bool 키는 `object(forKey:) == nil`을 먼저 확인해 기본값을 돌려준다. `passThresholdPercent` 쓰기는 50...100이고 10의 배수만 허용하고, 그 외는 저장하지 않고 이전 값을 유지하며 오류를 던진다. 읽을 때 저장된 값이 유효하지 않으면 80을 돌려주고 저장된 원래 값은 바꾸지 않는다.
    - 설정 화면(S12)은 만들지 않는다. 모든 공개 멤버에 `///` 주석을 단다.
    - 검증: 앱 타깃 빌드 성공. (동작 검증은 6.2~6.4)
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.7, 6.8, 6.9, 6.10_

  - [ ]* 6.2 `SettingsStore` 예시 단위 테스트
    - 테스트 이름 예: `settingsKeysMatchSpec`, `settingsDefaultsWhenEmpty`, `settingsDoesNotTouchOtherSuite`.
    - 키 문자열 4개 비교, 저장된 값이 없을 때의 기본값 4개, 별도 suite가 `.standard`를 바꾸지 않는지 확인한다.
    - 검증: 테스트 통과.
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ]* 6.3 Property 7 테스트: 설정 쓰기 후 읽기 round-trip
    - **Property 7: 설정 쓰기 후 읽기 round-trip**
    - 유효한 임계값(50, 60, 70, 80, 90, 100)과 Bool 키 3개의 true/false를 전수로 쓰고, 같은 인스턴스와 같은 suite의 새 인스턴스에서 같은 값을 읽는지 확인한다. 테스트 이름 예: `property7_settingsRoundTrip`.
    - **Validates: Requirements 6.5, 6.6**

  - [ ]* 6.4 Property 8, 9 테스트: 임계값 검증
    - **Property 8: 유효하지 않은 임계값 쓰기는 거부되고 이전 값을 유지한다**
    - **Property 9: 유효하지 않게 저장된 임계값은 80으로 읽힌다**
    - 정수 범위(예: -1000...1000 전수 또는 경계값 포함 100개 이상)를 입력으로, 50...100 안의 10의 배수가 아닌 값은 쓰기가 오류를 던지고 이전 값이 유지되는지(P8), 범위 밖이거나 10의 배수가 아닌 값을 `UserDefaults`에 직접 써 둔 뒤 읽으면 80이고 원래 값이 바뀌지 않는지(P9) 확인한다. 테스트 이름 예: `property8_invalidThresholdRejected`, `property9_invalidStoredThresholdReadsDefault`.
    - **Validates: Requirements 6.7, 6.8**

- [ ] 7. MediaFileManager
  - [ ] 7.1 `MediaReferenceCollector` 구현 (`Services/Media/MediaReferenceCollector.swift`)
    - 입력은 `Question` 값 목록과 세션 값 목록, 출력은 참조 파일명 집합인 순수 함수로 만든다. 8장 규칙 ①(어떤 `Question`), ②(진행 중 세션 스냅샷), ③(원본 `Question`이 남아 있는 문제의 끝난 세션 스냅샷)을 구현하고, `imageFileName`과 `videoFileName`을 같은 규칙으로 처리한다. 원본이 삭제된 문제의 끝난 세션 스냅샷은 참조로 치지 않는다.
    - 검증: 앱 타깃 빌드 성공. (동작 검증은 7.4)
    - _Requirements: 5.6, 5.7, 5.8_

  - [ ] 7.2 `MediaFileManager` 구현 (`Services/Media/MediaFileManager.swift`)
    - `MediaFileManaging`을 채택하고 `baseDirectory: URL`, 참조 수집용 컨텍스트 접근 수단, `fileManager: FileManager`(기본 `.default`)를 생성자로 주입받는다. **컨텍스트 접근 방식은 1.2(Q5)에서 확정한 방식을 따른다.**
    - `store(from:)`: 원본이 없거나 읽을 수 없으면 폴더를 바꾸지 않고 오류를 던진다. `UUID` 기반 새 파일명(원본 확장자 유지)으로 `baseDirectory` 안에 임시 이름으로 복사한 뒤 최종 이름으로 이동하고, 실패하면 임시 파일을 지우고 오류를 던진다. 같은 원본을 두 번 저장해도 서로 다른 이름을 돌려주고 기존 파일을 덮어쓰지 않는다. `baseDirectory`가 없으면 만든다.
    - `cleanUnreferencedFiles()`: 7.1의 참조 집합에 없는 `baseDirectory` 바로 아래 파일만 삭제한다. 조회가 실패하면 아무것도 지우지 않고 오류를 던진다. 삭제 실패 시 오류를 던지되 참조 중인 파일은 대상에 넣지 않는다. 앱 번들 에셋과 폴더 밖 파일은 건드리지 않는다. 진행 중 `store`의 임시 이름 파일을 삭제 대상에서 제외할지는 구현 때 검토하고 결정을 주석에 적는다.
    - 검증: 앱 타깃 빌드 성공. (동작 검증은 7.3~7.6)
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.9, 5.10, 5.11, 5.12, 5.13_

  - [ ]* 7.3 Property 4 테스트: 저장은 내용을 보존하고 기존 파일을 바꾸지 않는다
    - **Property 4: 저장은 내용을 보존하고 기존 파일을 바꾸지 않는다**
    - 빈 파일과 임의 바이트 내용, 다양한 확장자의 원본에 대해 `store(from:)`를 n회(n ≥ 1) 호출하고, 반환된 파일명이 모두 다르고 `baseDirectory`에서 원본과 바이트 단위로 같으며 이후 호출이 이전 파일을 바꾸지 않는지 확인한다. 테스트 이름 예: `property4_storePreservesContent`. 임시 폴더를 쓴다.
    - **Validates: Requirements 5.2, 5.3**

  - [ ]* 7.4 Property 5 테스트: 정리는 참조되지 않은 파일만 삭제한다
    - **Property 5: 정리는 참조되지 않은 파일만 삭제한다**
    - 파일 집합, `Question` 집합, 진행 중 세션과 끝난 세션(원본이 남은 경우와 삭제된 경우 모두)의 스냅샷 집합을 고정 시드로 100개 이상 조합해, 정리 후 남은 파일이 ①②③ 참조 합집합과 정확히 같고, 이미지·영상을 같은 규칙으로 판단하며, `baseDirectory` 밖 파일이 영향받지 않는지 확인한다. 테스트 이름 예: `property5_cleanupRemovesOnlyUnreferenced`.
    - **Validates: Requirements 5.6, 5.7, 5.8, 5.13**

  - [ ]* 7.5 Property 6 테스트: 정리는 멱등이다
    - **Property 6: 정리는 멱등이다**
    - Property 5와 같은 입력 구성에서 데이터 변경 없이 `cleanUnreferencedFiles()`를 연속 두 번 호출해, 두 번째 호출 후 파일 목록이 첫 호출 직후와 같은지 확인한다. 테스트 이름 예: `property6_cleanupIdempotent`.
    - **Validates: Requirements 5.9**

  - [ ]* 7.6 `MediaFileManager` 오류 경로 테스트
    - 테스트 이름 예: `storeMissingSourceThrowsAndLeavesFolderUnchanged`, `storeCopyFailureLeavesNoPartialFile`, `cleanupDeletionFailureThrowsAndKeepsReferencedFiles`.
    - 없는 원본, 복사 실패 주입(대체 `FileManager`), 삭제 실패 주입 경우를 확인한다.
    - 검증: 테스트 통과.
    - _Requirements: 5.4, 5.5, 5.10_

- [ ] 8. AppContainer와 환경 주입
  - [ ] 8.1 `AppContainer`, 환경 키, 실패 화면 구현 (`App/`)
    - 4개 `@Model` 타입(`QuestionSnapshot` 제외)을 등록한 `ModelContainer`를 앱 전체에서 1개만 만든다. 서비스는 모두 프로토콜 타입(`any ...`)으로 노출하고, `FeedbackPlaying`, `TaskRecommending`, `QuestionSelecting`, `SessionManaging`, `TreeManaging`, `TraceSceneRegistry`에는 mock을, `MediaFileManaging`과 `SettingsStore`(`.standard`)에는 실제 구현을 연결한다.
    - `EnvironmentKey`로 서비스 묶음을 SwiftUI 환경에 주입하고 `.modelContainer(...)`도 넣는다. 미리보기·테스트용으로 메모리 전용 컨테이너, mock, 임시 폴더 기반 구성을 만들 수 있는 정적 생성 함수를 둔다.
    - `ModelContainer` 생성은 `do/catch`로 감싸고 `try!`와 강제 언래핑을 쓰지 않는다. 실패하면 `Logger`로 오류를 1회 이상 기록하고 `ContainerFailureView`(한국어 안내)를 보여 준다. 시드 주입과 현재 트리 생성은 하지 않는다(Q1).
    - 앱 진입점(2.4에서 옮긴 파일)에서 컨테이너를 만들어 주입하되, 탭 연결은 10.2에서 한다.
    - 검증: 앱 타깃 빌드 성공, 컨테이너 생성 실패를 모사한 입력에서 크래시 없이 실패 화면 상태가 되는지 8.2에서 확인한다.
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.10_

  - [ ]* 8.2 `AppContainer` 테스트
    - 테스트 이름 예: `containerRegistersFourModels`, `containerExposesProtocolTypes`, `containerUsesMocksAndRealServices`, `containerFailureShowsFailureState`.
    - 메모리 구성 생성, 서비스가 프로토콜 타입인지, mock 6종과 실제 구현 2종의 연결, 실패하는 생성 팩토리를 주입했을 때 오류 화면 상태가 되는지 확인한다.
    - 검증: 테스트 통과.
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.7, 7.8_

- [ ] 9. 색상 Asset과 리터럴 색상 검사
  - [ ] 9.1 색상 세트 추가 (1.4에서 확정한 이름 목록이 있을 때만)
    - 사용자가 확정한 이름 목록대로 `Resources/Assets.xcassets`에 색상 세트를 추가하고, 세트마다 Any(라이트) 값과 Dark 값을 모두 정의한다. 이름이나 값을 임의로 정하지 않는다.
    - 검증: 각 `*.colorset/Contents.json`에 라이트와 다크(appearances) 항목이 모두 있다. 앱 타깃 빌드 성공.
    - _Requirements: 8.1, 8.8_

  - [ ] 9.2 `Color` 확장 구현 (`Extensions/Color+Assets.swift`)
    - 색상 세트마다 같은 이름의 `Color("이름")`을 가리키는 정적 프로퍼티를 1개씩 둔다. 파일 첫머리 `///` 주석에 "화면 코드에서 색상 값을 직접 쓰지 않는다" 규칙을 적는다.
    - 검증: 앱 타깃 빌드 성공, 프로퍼티 이름 집합이 `Assets.xcassets`의 색상 세트 이름 집합과 같다(9.3에서 테스트).
    - _Requirements: 8.2, 8.5_

  - [ ]* 9.3 색상 검사 테스트
    - 테스트 이름 예: `noLiteralColorsOutsideAssets`, `colorPropertiesMatchAssetColorsets`.
    - 앱 소스에서 `Color(red:`, `UIColor(red:` 같은 리터럴 색상 패턴을 찾아 파일 경로와 줄 번호를 실패 메시지에 출력한다(패턴 목록은 구현 때 확정). 프로퍼티가 가리키는 이름과 `*.colorset` 디렉터리 이름 집합을 비교해 어긋난 이름을 출력한다. 검출기 자체는 샘플 문자열로도 확인한다. 세트가 없는 상태에서도 통과해야 한다.
    - 검증: 테스트 통과, 의도적으로 리터럴을 넣은 샘플 입력에서는 실패하고 경로와 줄 번호가 출력된다.
    - _Requirements: 8.6, 8.7_

- [ ] 10. 탭 뼈대
  - [ ] 10.1 `PlaceholderScreen` 구현 (`App/PlaceholderScreen.swift`)
    - 탭 이름과 자리 ID(S1, S9, S10)를 한국어 문구로 보여 준다. `ScrollView`를 쓰고 고정 높이를 두지 않으며, 색상은 9.2의 정적 프로퍼티만 쓴다(세트가 아직 없으면 시스템 기본 스타일을 쓰고 색상 값을 직접 쓰지 않는다).
    - 검증: 앱 타깃 빌드 성공, 미리보기에서 가장 큰 Dynamic Type 단계로 확인했을 때 텍스트가 잘리지 않는다.
    - _Requirements: 10.5, 10.11, 10.13, 10.14_

  - [ ] 10.2 `RootTabView`와 앱 진입점 연결 (`App/RootTabView.swift`)
    - `TabView`에 "작업", "기록", "관리" 탭을 왼쪽부터 이 순서로 두고 시작 선택은 "작업"으로 한다. 탭마다 `NavigationStack(path:)`와 탭별 경로 상태를 뷰 밖(상위 `@State` 또는 별도 상태 객체)에 둔다. 루트는 각각 S1, S9, S10 자리의 `PlaceholderScreen`이다.
    - 탭 라벨과 VoiceOver 라벨은 화면에 표시되는 이름과 같게 한다. 탭 아이콘(SF Symbols)은 임의로 정하지 말고 사용자에게 확인해서 정한다(확인 전에는 아이콘 없이 텍스트만).
    - 8.1의 `AppContainer`를 환경으로 주입받는 앱 진입점에서 `RootTabView`를 루트로 표시하고, `ModelContainer` 생성 실패 시 `ContainerFailureView`를 표시한다. `fullScreenCover`와 S2~S8, S11, S12는 만들지 않는다.
    - 검증: 앱 타깃 빌드 성공, 시뮬레이터에서 탭 3개가 표시된다(최종 확인은 12.2).
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.9, 10.10, 10.11, 10.12, 7.6, 7.9_

  - [ ]* 10.3 탭 경로 상태 예시 테스트
    - 테스트 이름 예: `tabPathsAreIndependent`, `tabPathSurvivesTabSwitch`.
    - 한 탭에 경로를 추가해도 다른 두 탭의 경로가 바뀌지 않는지, 탭 전환 후 돌아와도 경로가 유지되는지 상태 객체 수준에서 확인한다.
    - 검증: 테스트 통과.
    - _Requirements: 10.6, 10.7, 10.9_

- [ ] 11. 정적 규칙 검사
  - [ ]* 11.1 강제 언래핑·`try!` 검사 테스트
    - 테스트 이름 예: `noForceUnwrapOrTryBang`.
    - 앱 소스와 테스트 소스에서 `try!`와 강제 언래핑 패턴을 찾아 파일 경로와 줄 번호를 실패 메시지에 출력한다(패턴은 `!=`, 문자열 안의 `!` 등 오탐을 피하도록 구현 때 확정).
    - 검증: 테스트 통과, 샘플 입력에서는 실패한다.
    - _Requirements: 11.1, 11.3_

- [ ] 12. 통합 검증
  - [ ] 12.1 클린 빌드와 전체 테스트 실행 확인
    - 앱 타깃과 테스트 타깃을 iOS 시뮬레이터 대상으로 클린 빌드하고 `xcodebuild test`를 실행한다. 빌드 설정 조회로 앱·테스트 타깃의 배포 타깃 `17.0`, 기기 `1,2`, 방향을 확인한다. 실패 시 0이 아닌 종료 코드와 실패 테스트 이름이 출력되는지 확인한다.
    - 요구사항 9.3(round-trip, 멱등성, 기본값 테스트 최소 1개씩)이 건너뛴 `*` 작업 때문에 비어 있지 않은지 확인하고, 비어 있으면 해당 테스트를 작성한다.
    - 검증: 빌드 오류 0건, 배포 타깃 관련 경고 0건, 모든 테스트 통과, 테스트를 2회 연속 실행해도 결과가 같다.
    - _Requirements: 1.5, 1.8, 2.8, 9.2, 9.3, 9.5, 9.7, 9.8_

  - [ ] 12.2 iPhone과 iPad 시뮬레이터 실행 확인
    - iPhone 시뮬레이터와 iPad 시뮬레이터에서 앱을 실행해 크래시 없이 "작업 / 기록 / 관리" 탭 3개가 표시되는지, `ModelContainer`, 서비스, `SettingsStore`, `MediaFileManager`가 실제 실행 경로에서 환경으로 연결되었는지 확인한다.
    - iPad 가로·세로 전환 때 선택된 탭과 푸시 상태가 유지되는지, 라이트/다크 전환, 가장 큰 Dynamic Type, VoiceOver 라벨을 수동으로 점검한다.
    - 확인하지 못한 항목은 완료로 표시하지 않고 PR 설명의 미충족 항목으로 적는다.
    - 검증: 위 항목을 직접 실행한 결과가 기록되어 있다.
    - _Requirements: 7.9, 10.8, 10.9, 10.10, 10.13, 10.14, 8.3, 8.4, 12.3, 12.4_

- [ ] 13. Final checkpoint - 통합 완료 조건 확인
  - `docs/integration-contracts.md` 1장 `app-foundation` 행의 통합 완료 조건을 확인한다: `ModelContainer`와 서비스 조립, 탭·화면 이동 뼈대, mock, `MediaFileManaging`, `SettingsStore`가 실행 중인 앱에서 실제로 연결됨, iOS 17.0 배포 설정으로 빌드됨, 테스트 타깃이 실행됨.
  - 요구사항 1~11의 수락 기준 중 충족하지 못했거나 mock으로만 확인된 항목이 있으면 완료로 표시하지 않고 미충족 항목을 정리한다.
  - 1번 결정 항목(Q1~Q6, 속성 테스트 방식) 중 아직 확정되지 않은 것이 있으면 사용자에게 알리고, 확정된 내용은 `project-spec.md` 16장 반영 여부를 확인한다. 질문이 있으면 사용자에게 묻는다.

## Notes

- `*`가 붙은 하위 작업은 선택이며 MVP에서 건너뛸 수 있습니다. 단 요구사항 9.3은 최소 테스트를 요구하므로 12.1에서 확인합니다.
- 각 작업은 요구사항 번호로 추적되고, 속성 테스트는 design.md의 Property 번호와 대응합니다(P1: 3.4, P2: 3.5, P3: 5.2, P4: 7.3, P5: 7.4, P6: 7.5, P7: 6.3, P8·P9: 6.4).
- 1번 결정 작업은 사용자의 답이 있어야 진행할 수 있습니다. 답이 없으면 해당 항목에 의존하는 작업(2.2, 2.4, 3.3 이후 테스트, 4.2의 격리 한정자, 7.2의 컨텍스트 접근, 9.1)을 시작하지 않습니다.
- 모델(`Models/`)을 바꾸는 PR은 팀원 모두에게 알리고, 공통 계약(8장, 9장) 변경은 `project-spec.md`를 먼저 고친 뒤 영향받는 Spec 목록을 PR에 적습니다.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4"] },
    { "id": 1, "tasks": ["2.1"] },
    { "id": 2, "tasks": ["2.2"] },
    { "id": 3, "tasks": ["2.3"] },
    { "id": 4, "tasks": ["2.4", "3.1"] },
    { "id": 5, "tasks": ["3.2", "6.1", "9.1"] },
    { "id": 6, "tasks": ["2.5", "4.1", "9.2"] },
    { "id": 7, "tasks": ["4.2", "7.1", "3.3", "3.4", "3.5", "6.2", "6.3", "6.4", "9.3"] },
    { "id": 8, "tasks": ["5.1", "7.2", "10.1"] },
    { "id": 9, "tasks": ["5.2", "8.1", "7.3", "7.4", "7.5", "7.6"] },
    { "id": 10, "tasks": ["8.2", "10.2"] },
    { "id": 11, "tasks": ["10.3", "11.1"] },
    { "id": 12, "tasks": ["12.1"] },
    { "id": 13, "tasks": ["12.2"] }
  ]
}
```
