# Requirements Document

## Introduction

이 문서는 `project-spec.md` 15장의 작업 0(기반)과 `integration-contracts.md`의 `app-foundation` 행을 기준으로, 다른 모든 Spec이 공통으로 의존하는 앱 기반의 요구사항을 정의합니다. 이 Spec은 **계약(모델, 프로토콜, 결과 타입), mock, 조립(wiring)** 만 제공합니다. 동작하는 기능 로직과 화면 구현은 다른 Spec이 맡습니다.

문서 작성 규칙은 다음과 같습니다.

- 모델과 프로토콜의 이름, 필드, 시그니처는 `project-spec.md` 8장과 9장이 기준입니다. 이 문서는 선언을 복사하지 않고 절 번호와 타입 이름으로 참조합니다. 이 문서와 steering이 다르면 steering이 우선하며, 바꿀 때는 `integration-contracts.md` 4장의 규칙(공통 계약 변경 절차)을 따릅니다.
- 이 문서는 명세만 다룹니다. 앱 코드와 프로젝트 설정은 이 문서 작성 단계에서 바꾸지 않습니다.

### 의존하는 계약

| 계약 | 출처 |
| --- | --- |
| 기술 스택, 지원 기기, 최소 OS | `project-spec.md` 3장 |
| 탭 구조와 화면 위치 | `project-spec.md` 6-1장, 6-2장 |
| 설정 키와 기본값 | `project-spec.md` 7-8장 |
| 데이터 모델과 enum | `project-spec.md` 8장 |
| 모듈 프로토콜과 결과 타입 | `project-spec.md` 9장 |
| 폴더 구조 | `project-spec.md` 10장 |
| 공통 코드 규칙(강제 언래핑 금지, 색상 Asset, 문서화 주석) | `project-spec.md` 11-1장 |
| 공통 소유권, 통합 완료 조건 | `integration-contracts.md` 1장, 2장 |

### 제공하는 것

- Xcode 프로젝트 설정(iOS 17.0 배포 설정, 기기 방향)
- 10장 폴더 구조
- 8장의 SwiftData 모델과 enum, `QuestionSnapshot`
- 9장의 프로토콜, 결과 타입, `TraceSceneAction`의 빈 자리(`.none`)
- 9장 프로토콜의 mock 구현(SwiftUI 미리보기와 다른 Spec의 개발용)
- `MediaFileManaging`의 구현(파일 저장과 정리)
- `SettingsStore`(설정 키와 기본값)
- `ModelContainer`와 서비스 조립을 한 곳에서 하는 구성과 의존성 주입 경로
- 탭 3개(작업/기록/관리) 뼈대
- 라이트/다크 색상 Asset 기본 틀
- 단위 테스트를 실행할 수 있는 테스트 타깃

### 범위 밖

아래는 다른 Spec이 맡으며, 이 Spec은 계약과 자리만 제공합니다.

- 세션 로직의 실제 구현: `QuestionSelector`, `TaskRecommender`, `SessionManager`, `TreeManager`, 보상 계산 (`session-engine`)
- 화면 S1~S12의 구현 (각 기능 Spec). 이 Spec의 탭 뼈대는 빈 자리 화면만 가집니다.
- 시드 JSON 로더, 시드 주입, 60문제 이상의 문제 작성 (`seed-data`)
- 애니메이션 문제 컴포넌트와 장면, `TraceSceneRegistry`의 실제 구현 (`code-trace-animation`)
- 차트, 문제 관리 화면, 설정 화면
- 효과음과 햅틱의 실제 재생 (`FeedbackPlaying`은 mock만 제공)
- 이미지, 사운드 파일, 앱 아이콘 등 에셋 제작
- README, 스크린샷, 마감 점검

### 열린 질문

steering이 정하지 않아서 팀 확인이 필요한 항목입니다. 이 문서는 임의로 결정하지 않습니다. 확인이 끝나면 `project-spec.md` 16장에도 반영합니다.

| # | 질문 | 관련 요구사항 |
| --- | --- | --- |
| Q1 | 8장 규칙은 "현재 트리는 `completedAt == nil`인 `TreeRecord` 한 개이며 앱 첫 실행 때 생성한다"고 하지만, 15장 작업 0과 1~2번 작업 중 누가 만드는지 적혀 있지 않습니다. 첫 실행 때 현재 트리 생성을 foundation이 맡을지, `session-engine`의 `TreeManaging.currentTree()`가 없으면 만드는 방식으로 맡을지 정해야 합니다. 이 문서는 foundation 범위에 넣지 않았습니다. | 요구사항 5, 범위 밖 |
| Q2 | 단위 테스트 프레임워크(XCTest 또는 Swift Testing)가 steering에 없습니다. | 요구사항 9 |
| Q3 | 색상 세트의 이름과 개수(예: 배경, 강조, 정답, 오답)가 steering에 없습니다. 기본 틀에 넣을 색상 목록을 정해야 합니다. | 요구사항 8 |
| Q4 | mock 구현 파일을 둘 위치가 10장 폴더 구조에 없습니다(예: `Services/Mocks/`). | 요구사항 4 |
| Q5 | 9장 프로토콜을 `@MainActor`로 둘지, SwiftData의 `ModelContext` 접근 방식을 어떻게 맞출지 steering에 없습니다. 이는 `session-engine`의 구현 방식에도 영향을 줍니다. | 요구사항 3, 6 |
| Q6 | 10장 폴더 구조의 최상위 이름은 `Santa'sDeliveryCrisis/`이고, 현재 소스 폴더 이름도 같습니다. 현재의 `MyApp.swift`와 `ContentView.swift`를 `App/` 아래로 옮기거나 교체하는 범위를 foundation이 정할지 확인이 필요합니다. | 요구사항 2 |

## Glossary

- **Foundation**: 이 Spec(`app-foundation`)이 만드는 기반 모듈 전체. 모델, 계약, mock, 조립, 뼈대를 포함합니다.
- **App_Project**: Xcode 프로젝트 `Santa'sDeliveryCrisis.xcodeproj`와 앱 타깃. 소스 폴더를 폴더 멤버십으로 등록해서 사용합니다.
- **Test_Target**: 단위 테스트를 담는 Xcode 테스트 타깃.
- **Model_Layer**: `project-spec.md` 8장의 SwiftData 모델(`Question`, `QuizSession`, `SessionAnswer`, `TreeRecord`), 값 타입 `QuestionSnapshot`, enum(`QuizCategory`, `Difficulty`, `QuestionKind`, `SessionStatus`)의 묶음.
- **Contract_Layer**: `project-spec.md` 9장의 프로토콜(`TaskRecommending`, `QuestionSelecting`, `SessionManaging`, `TreeManaging`, `FeedbackPlaying`, `MediaFileManaging`, `TraceSceneRegistry`)과 값 타입(`SessionResult`, `TreeGrantResult`, `TraceStep`, `TraceSceneAction`)의 묶음.
- **Mock_Services**: Contract_Layer 프로토콜을 미리 정한 고정 값으로 구현한 가짜 구현. 네트워크, 파일, 저장소 없이 동작하며 SwiftUI 미리보기와 다른 Spec의 개발에 씁니다.
- **Media_File_Manager**: `MediaFileManaging`의 실제 구현. 앱 내부 폴더에 미디어 파일을 저장하고 참조되지 않는 파일을 정리합니다.
- **Settings_Store**: `UserDefaults`를 감싼 설정 저장소. 설정 키와 기본값은 `project-spec.md` 7-8장이 정의합니다.
- **App_Container**: `ModelContainer`와 서비스 인스턴스를 한 곳에서 만들어 앱에 주입하는 구성 지점.
- **Tab_Skeleton**: `project-spec.md` 6-1장의 탭 3개(작업, 기록, 관리). 각 탭은 독립된 `NavigationStack`을 가집니다.
- **Color_Assets**: Asset 카탈로그의 라이트/다크 색상 세트.
- **Seed_Question**: `isSeed == true`인 `Question`. 이 Spec에서는 모델 필드만 다룹니다.
- **Placeholder_Screen**: 다른 Spec이 실제 화면으로 교체할 때까지 탭 루트에 표시하는 비어 있는 화면.

## Requirements

### Requirement 1: Xcode 프로젝트 설정

**User Story:** As a 팀 개발자, I want 모두가 같은 배포 설정과 기기 방향으로 앱을 빌드하기를, so that 환경 차이 때문에 다른 Spec의 작업이 어긋나지 않는다.

#### Acceptance Criteria

1. THE App_Project SHALL 앱 타깃과 Test_Target의 `IPHONEOS_DEPLOYMENT_TARGET`을 모든 빌드 구성(Debug, Release)에서 17.0으로 설정한다.
2. THE App_Project SHALL 앱 타깃의 지원 기기를 iPhone과 iPad로 설정한다(`TARGETED_DEVICE_FAMILY`가 "1,2").
3. THE App_Project SHALL iPhone의 지원 방향을 세로(portrait) 한 가지로 제한하며, 가로(landscape 두 방향)와 거꾸로 세로(upside down)는 포함하지 않는다.
4. THE App_Project SHALL iPad의 지원 방향을 세로(portrait), 가로 왼쪽(landscape left), 가로 오른쪽(landscape right)으로 설정한다(`project-spec.md` 3장, 6-3장).
5. WHEN `xcodebuild`로 iOS 시뮬레이터 대상 빌드를 앱 타깃과 Test_Target 모두에 대해 클린 상태에서 실행한다, THE App_Project SHALL 오류 0건, 경고 중 배포 타깃 불일치 관련 경고 0건으로 빌드를 마친다.
6. THE App_Project SHALL 외부 패키지 의존성(Swift Package Manager, CocoaPods, Carthage 등)을 한 건도 포함하지 않으며, Apple 기본 프레임워크만 사용한다(`project-spec.md` 3장).
7. THE App_Project SHALL 소스 폴더를 폴더 멤버십으로 등록한 상태를 유지하여, 폴더에 추가한 파일이 프로젝트 파일 수정 없이 앱 타깃에 포함되도록 한다.
8. IF 앱 타깃 또는 Test_Target의 배포 타깃, 지원 기기, 지원 방향 중 하나라도 위 1~4번 값과 다르다, THEN THE App_Project SHALL 해당 설정을 불일치 항목으로 보고하는 확인 절차(빌드 설정 조회 결과 비교)에서 실패로 판정된다(`docs/integration-contracts.md`의 작업 0 통합 완료 조건에 따른다).

### Requirement 2: 폴더 구조

**User Story:** As a 팀 개발자, I want 합의된 폴더 구조가 처음부터 준비되기를, so that 각 Spec이 자기 파일을 충돌 없이 같은 위치에 둘 수 있다.

#### Acceptance Criteria

1. THE Foundation SHALL `project-spec.md` 10장에 나열된 12개 폴더(`App`, `Models`, `Services`, `Features/Task`, `Features/Quiz`, `Features/Trace`, `Features/Records`, `Features/Manage`, `Features/Settings`, `Resources/Seed`, `Resources/Sounds`, `Extensions`)를 앱 소스 폴더 바로 아래에 만든다. 폴더 이름은 철자와 대소문자를 10장과 정확히 일치시킨다.
2. THE Foundation SHALL `Assets.xcassets`를 `Resources/` 바로 아래에 둔다. 앱 소스 폴더 바로 아래에는 `Assets.xcassets`를 남기지 않는다.
3. THE Foundation SHALL 파일이 하나도 없는 폴더마다 유지용 파일을 정확히 1개씩 둔다. 각 폴더는 `git ls-files` 결과에 1개 이상의 파일이 나타나야 한다. 같은 폴더에 다른 파일이 들어오면 유지용 파일은 지워도 된다.
4. THE Foundation SHALL 앱 진입점과 탭 구성을 담은 소스 파일을 `App/` 폴더 안에 둔다. 이 파일들은 앱 소스 폴더 바로 아래나 다른 폴더에 두지 않는다.
5. THE Foundation SHALL 모델 타입과 enum(`project-spec.md` 8장에 정의된 타입)을 담은 소스 파일을 `Models/` 폴더 안에 둔다.
6. THE Foundation SHALL `project-spec.md` 9장의 프로토콜, `SessionResult`와 `TreeGrantResult` 같은 결과 타입, Media_File_Manager, Settings_Store, Mock_Services를 담은 소스 파일을 `Services/` 폴더 또는 그 하위 폴더 안에 둔다.
7. THE Foundation SHALL 폴더 구조와 파일 배치가 `docs/integration-contracts.md`에 적힌 각 작업의 통합 완료 조건과 충돌하지 않게 한다.
8. WHEN 폴더 구조를 만든 뒤 App_Project를 iOS 시뮬레이터 대상으로 빌드한다, THE App_Project SHALL 오류 0건, 경고 중 폴더 구조나 파일 참조 누락 때문에 생긴 경고 0건으로 빌드를 마친다.
9. IF 빌드가 폴더 구조나 파일 참조 문제(예: 누락된 파일 참조, 중복된 파일 이름)로 실패한다, THEN THE Foundation SHALL 원인이 된 폴더나 파일을 수정해 8번 기준을 만족할 때까지 구조 작업을 완료로 표시하지 않는다.

### Requirement 3: 데이터 모델과 enum

**User Story:** As a 팀 개발자, I want 8장의 모델과 enum이 한 번에 정확히 만들어지기를, so that 모든 Spec이 같은 필드 이름으로 개발한다.

#### Acceptance Criteria

1. THE Model_Layer SHALL `project-spec.md` 8장의 `QuizCategory`(`aiUsage`, `swiftSyntax`, `hig`, `swiftUIPractice`), `Difficulty`(`easy`, `normal`, `hard`), `QuestionKind`(`standard`, `animation`), `SessionStatus`(`inProgress`, `completed`, `abandoned`)를 8장에 선언된 케이스 이름, 케이스 개수, 선언 순서, `String` raw 값, `Codable` 채택 그대로 제공한다. `QuizCategory`와 `Difficulty`는 `CaseIterable`도 채택하고, 각 케이스의 raw 값은 케이스 이름과 같다.
2. THE Model_Layer SHALL `Difficulty.rewardDecorations`가 `easy`에는 1, `normal`에는 2, `hard`에는 3을 돌려주도록 구현한다.
3. THE Model_Layer SHALL 8장의 `Question`, `QuizSession`, `SessionAnswer`, `TreeRecord`를 8장에 선언된 모든 필드 이름, 타입, 옵셔널 여부, `@Attribute(.unique)`(`Question.id`, `QuizSession.id`, `TreeRecord.id`), `@Relationship(deleteRule: .cascade)`(`QuizSession.answers`) 그대로 SwiftData 모델로 제공한다.
4. THE Model_Layer SHALL 8장의 `QuestionSnapshot`을 8장에 선언된 15개 필드(`questionID`, `category`, `kind`, `tags`, `animationID`, `text`, `codeSnippet`, `imageFileName`, `videoFileName`, `hint`, `choices`, `correctIndex`, `explanation`, `resourceTitle`, `resourceURL`)를 가진 `Codable` 값 타입으로 제공하고, `QuizSession.questionSnapshots`에 저장할 수 있도록 한다.
5. THE Model_Layer SHALL 8장에 없는 모델, 필드, enum 케이스를 추가하지 않는다.
6. WHEN 메모리 전용 `ModelContainer`에 `Question`, `QuizSession`, `SessionAnswer`, `TreeRecord`를 모두 등록한다, THE Model_Layer SHALL 오류 없이 컨테이너를 만든다.
7. WHEN `QuizSession`을 문제 2개 이상의 `QuestionSnapshot` 배열과 `SessionAnswer` 1개 이상과 함께 저장한 뒤 새 `ModelContext`에서 다시 읽는다, THE Model_Layer SHALL 8장에 선언된 모든 필드(옵셔널 필드의 `nil` 포함, `questionSnapshots`와 `answers`의 개수와 각 요소 값)를 저장 전과 같은 값으로 돌려준다(round-trip).
8. WHEN 부모 `QuizSession`을 삭제하고 저장한다, THE Model_Layer SHALL 그 세션에 연결된 `SessionAnswer`를 모두 함께 삭제하고, 다른 `QuizSession`의 `SessionAnswer`와 `Question`은 삭제하지 않는다.
9. IF 같은 `id`를 가진 `Question`을 두 번 저장한다, THEN THE Model_Layer SHALL 해당 `id`의 `Question` 레코드를 1개만 유지하고, 저장 후 조회한 레코드 수가 1개임을 보장한다.
10. THE Model_Layer SHALL `Models/` 폴더(8장과 10장)에 선언한 모든 공개 타입(enum, 모델 클래스, `QuestionSnapshot`)과 그 공개 멤버(필드, 케이스, `Difficulty.rewardDecorations`)에 `///` 문서화 주석을 단다(11장).

### Requirement 4: 모듈 프로토콜, 결과 타입, mock

**User Story:** As a 팀 개발자, I want 9장의 프로토콜과 이를 구현한 mock이 준비되기를, so that 실제 구현이 없어도 화면과 로직을 병렬로 개발하고 미리보기를 볼 수 있다.

#### Acceptance Criteria

1. THE Contract_Layer SHALL `project-spec.md` 9장의 `TaskRecommending`, `QuestionSelecting`, `SessionManaging`, `TreeManaging`, `FeedbackPlaying`, `MediaFileManaging`, `TraceSceneRegistry` 7개 프로토콜을 선언된 이름, 메서드 이름, 매개변수 이름과 타입, 반환 타입, `throws` 여부까지 그대로 제공한다.
2. THE Contract_Layer SHALL 9장의 `SessionResult`(필드 8개), `TreeGrantResult`(필드 3개), `TraceStep`(필드 4개)을 선언된 필드 이름과 타입 그대로 제공한다.
3. THE Contract_Layer SHALL `TraceSceneAction`을 `.none` 케이스 하나만 가진 enum으로 제공한다.
4. THE Contract_Layer SHALL 9장에 없는 프로토콜, 타입, 메서드, 필드를 추가하지 않는다.
5. THE Contract_Layer SHALL 모든 공개 프로토콜, 타입, 함수에 `///` 문서화 주석을 달고, 9장에 적힌 동작 계약을 해당 주석에 그대로 옮겨 적는다. 동작 계약은 다음을 포함한다: `submit`의 중복 호출 시 처음 저장된 답 반환, `submit`의 순서 제한(앞선 미답 문제가 있으면 오류), `submit`의 답 저장과 `currentIndex` 갱신 단일 저장, `finish`의 `completed` 세션 재호출 시 저장된 결과 반환과 장식 재지급 금지, `finish`의 완료·지급·트리 갱신 단일 저장과 실패 시 전체 취소 및 `inProgress` 유지, `TreeManaging.grant`의 저장(save) 미호출과 `finish`의 단일 저장 호출.
6. THE Mock_Services SHALL `MediaFileManaging`을 제외한 6개 프로토콜(`TaskRecommending`, `QuestionSelecting`, `SessionManaging`, `TreeManaging`, `FeedbackPlaying`, `TraceSceneRegistry`) 각각에 대해 mock 구현을 1개 이상 제공한다.
7. THE Mock_Services SHALL SwiftData 저장소, 파일 시스템, 네트워크, 오디오, 햅틱에 접근하지 않고, 같은 입력에 항상 같은 값을 돌려준다.
8. WHEN SwiftUI 미리보기가 Mock_Services 인스턴스를 만든다, THE Mock_Services SHALL 인자 없이 생성되고 생성 중 오류를 던지지 않는다.
9. WHEN 호출하는 쪽이 mock `SessionManaging.resumableSession()`을 호출한다, THE Mock_Services SHALL 옵셔널 결과를 돌려준다. 이때 mock은 진행 중 세션이 없는 상태(`nil` 반환)와 있는 상태(세션 1개 반환)를 생성 시점에 각각 고를 수 있어야 한다.
10. IF 호출하는 쪽이 mock `TraceSceneRegistry.scene(for:)`에 mock이 알지 못하는 `animationID`(빈 문자열 포함)를 넘긴다, THEN THE Mock_Services SHALL 예외나 크래시 없이 `nil`을 돌려준다.
11. THE Mock_Services SHALL 모든 mock 구현이 mock임을 타입 이름(예: `Mock` 접두사 또는 접미사)과 `///` 문서화 주석 양쪽에 드러낸다.
12. THE Foundation SHALL 각 mock 타입이 해당 9장 프로토콜을 채택하도록 선언하여, 시그니처가 어긋나면 빌드(컴파일)가 실패하게 한다.
13. IF mock `SessionManaging`, `TreeManaging`이 9장에서 오류를 던질 수 있다고 정한 메서드(`startSession`, `submit`, `finish`, `abandon`, `grant`)를 호출받는다, THEN THE Mock_Services SHALL 호출자가 미리보기에서 정상 경로를 볼 수 있도록 기본으로 성공 값을 돌려준다.

### Requirement 5: 미디어 파일 저장과 정리 (`MediaFileManaging`)

**User Story:** As a 문제 관리와 세션 담당자, I want 미디어 파일의 저장과 정리를 한 곳에서 하기를, so that 파일 삭제 규칙이 Spec마다 흩어지지 않는다.

#### Acceptance Criteria

1. THE Media_File_Manager SHALL `project-spec.md` 9장의 `MediaFileManaging`에 정의된 `store(from:)`와 `cleanUnreferencedFiles()`를 모두 구현한다.
2. WHEN `store(from:)`에 읽을 수 있는 파일 URL이 전달된다, THE Media_File_Manager SHALL 파일 내용을 앱 내부 폴더에 원본과 바이트 단위로 동일하게 복사하고, 새 파일명을 돌려준다. 돌려준 파일명으로 앱 내부 폴더에서 그 파일을 찾을 수 있어야 한다.
3. WHEN 같은 원본 URL이 두 번 `store(from:)`에 전달된다, THE Media_File_Manager SHALL 서로 다른 파일명을 돌려주고, 첫 번째 호출로 저장된 파일의 내용을 바꾸지 않는다.
4. IF `store(from:)`의 원본 URL이 존재하지 않거나 읽을 수 없다, THEN THE Media_File_Manager SHALL 오류를 던지고, 호출 전과 비교해 앱 내부 폴더의 파일 목록과 내용을 바꾸지 않는다.
5. IF `store(from:)`의 복사 도중 실패한다(예: 저장 공간 부족), THEN THE Media_File_Manager SHALL 오류를 던지고, 일부만 복사된 파일을 앱 내부 폴더에 남기지 않는다.
6. WHEN `cleanUnreferencedFiles()`가 호출된다, THE Media_File_Manager SHALL 8장 규칙의 ① 어떤 `Question`, ② 진행 중(`inProgress`) 세션의 스냅샷, ③ 원본 `Question`이 남아 있는 문제의 끝난 세션 스냅샷 중 어느 것도 참조하지 않는 파일만 삭제한다.
7. WHEN `cleanUnreferencedFiles()`가 호출된다, THE Media_File_Manager SHALL 위 ①~③ 중 하나 이상이 참조하는 파일을 삭제하지 않고 내용도 바꾸지 않는다. 이미지 파일(`imageFileName`)과 영상 파일(`videoFileName`) 참조를 모두 같은 규칙으로 판단한다.
8. WHEN `cleanUnreferencedFiles()`가 호출되고 어떤 파일을 참조하는 것이 원본 `Question`이 삭제된 문제의 끝난 세션(`completed` 또는 `abandoned`) 스냅샷뿐이다, THE Media_File_Manager SHALL 그 파일을 삭제한다.
9. WHEN `cleanUnreferencedFiles()`가 연속으로 두 번 호출되고 그 사이에 데이터 변경이 없다, THE Media_File_Manager SHALL 두 번째 호출에서 파일을 하나도 삭제하지 않고 앱 내부 폴더의 파일 목록을 첫 번째 호출 직후와 같게 유지한다.
10. IF `cleanUnreferencedFiles()`가 파일 하나를 삭제하다 실패한다, THEN THE Media_File_Manager SHALL 오류를 던지고, 참조 중인 파일은 삭제하지 않은 상태로 유지한다.
11. THE Media_File_Manager SHALL 미디어 파일의 저장과 참조 여부 판단을 `MediaFileManaging` 한 곳에서만 수행하고, 문제 관리와 세션은 파일 삭제를 직접 수행하지 않고 이 구현의 `cleanUnreferencedFiles()`를 호출한다.
12. THE Media_File_Manager SHALL 저장 위치를 생성 시점에 주입받을 수 있게 하여, 테스트가 임시 폴더로 `store(from:)`와 `cleanUnreferencedFiles()`를 실행하고 실제 앱 폴더를 건드리지 않게 한다.
13. THE Media_File_Manager SHALL 주입받은 앱 내부 사용자 폴더 안의 파일만 삭제 대상으로 하고, 앱 번들에 들어 있는 시드 미디어 에셋은 삭제하지 않는다.

### Requirement 6: 설정 저장소 (`SettingsStore`)

**User Story:** As a 팀 개발자, I want 설정 키와 기본값이 한 곳에 정의되기를, so that 서비스가 `@AppStorage`를 직접 읽지 않고 테스트 가능한 방식으로 설정을 쓴다.

#### Acceptance Criteria

1. THE Settings_Store SHALL `project-spec.md` 7-8장의 키 4개(`hasLaunchedBefore`, `passThresholdPercent`, `soundEnabled`, `hapticsEnabled`)를 7-8장 표와 철자·대소문자가 완전히 같은 이름으로 정의하고, 이 4개 외의 키는 정의하지 않는다.
2. WHEN 키에 저장된 값이 없는 상태에서 값을 읽는다, THE Settings_Store SHALL `hasLaunchedBefore`는 false, `passThresholdPercent`는 80, `soundEnabled`는 true, `hapticsEnabled`는 true를 돌려준다.
3. THE Settings_Store SHALL 생성할 때 `UserDefaults` 인스턴스를 주입받고, 주입받은 인스턴스에만 읽기와 쓰기를 수행한다.
4. WHERE 테스트가 별도의 `UserDefaults` 인스턴스를 주입한다, THE Settings_Store SHALL 다른 인스턴스(앱 기본 저장소 포함)의 값을 읽거나 바꾸지 않는다.
5. WHEN 유효한 값을 쓴 뒤 같은 키를 읽는다, THE Settings_Store SHALL 쓴 값과 동일한 값을 돌려준다. 이 동작은 `passThresholdPercent`의 유효값 50, 60, 70, 80, 90, 100과 Bool 키 3개의 true/false 모두에서 성립한다.
6. WHEN 같은 `UserDefaults` 저장소를 사용하는 새 `SettingsStore` 인스턴스를 만든다, THE Settings_Store SHALL 이전 인스턴스가 쓴 값을 돌려준다.
7. IF `passThresholdPercent`에 쓰려는 값이 50 미만, 100 초과, 또는 10의 배수가 아니다, THEN THE Settings_Store SHALL 그 값을 저장하지 않고 이전에 저장된 값을 그대로 유지하며, 호출한 쪽이 거부를 알 수 있도록 오류를 던지거나 실패를 반환한다.
8. IF `passThresholdPercent`에 이미 저장되어 있는 값이 50 미만, 100 초과, 또는 10의 배수가 아니다, THEN THE Settings_Store SHALL 읽을 때 기본값 80을 돌려주고 저장된 원래 값은 바꾸지 않는다.
9. THE Settings_Store SHALL `@AppStorage`가 같은 키를 사용할 수 있도록 4개 키 이름과 기본값을 외부에서 접근 가능한 상수로 공개하고, 서비스 코드에서 키 문자열을 직접 쓰지 않아도 되게 한다.
10. THE Settings_Store SHALL 설정 화면 UI(S12)를 포함하지 않는다.

### Requirement 7: ModelContainer와 서비스 조립 (`App_Container`)

**User Story:** As a 팀 개발자, I want 컨테이너와 서비스가 한 곳에서 만들어져 주입되기를, so that 다른 Spec이 각자 컨테이너를 만들지 않고 실제 구현으로 교체할 수 있다.

#### Acceptance Criteria

1. THE App_Container SHALL 8장의 `Question`, `QuizSession`, `SessionAnswer`, `TreeRecord` 4개 `@Model` 타입을 모두 등록한 `ModelContainer`를 앱 전체에서 1개만 만든다. `QuestionSnapshot`은 `@Model`이 아니므로 등록 대상에서 제외한다.
2. THE App_Container SHALL 9장의 서비스 프로토콜(`TaskRecommending`, `QuestionSelecting`, `SessionManaging`, `TreeManaging`, `FeedbackPlaying`, `MediaFileManaging`, `TraceSceneRegistry`)의 인스턴스와 Settings_Store를 한 곳에서 조립한다.
3. THE App_Container SHALL 각 서비스를 구체 타입이 아닌 9장의 프로토콜 타입으로 노출하여, 구현을 교체할 때 호출하는 쪽의 소스 코드 수정이 0줄이 되도록 한다.
4. WHEN 앱이 실행된다, THE App_Container SHALL `FeedbackPlaying`, `TaskRecommending`, `QuestionSelecting`, `SessionManaging`, `TreeManaging`, `TraceSceneRegistry`에 Mock_Services를 기본으로 연결한다.
5. WHEN 앱이 실행된다, THE App_Container SHALL `MediaFileManaging`과 Settings_Store에 Mock이 아닌 실제 구현을 연결한다.
6. THE App_Container SHALL SwiftUI 환경(environment)으로 조립한 서비스를 뷰 계층에 주입하여, 하위 뷰가 컨테이너를 직접 생성하지 않고 환경에서 읽을 수 있게 한다.
7. WHERE 실행 환경이 미리보기 또는 테스트이다, THE App_Container SHALL 디스크에 저장하지 않는 메모리 전용 `ModelContainer`와 Mock_Services로 구성할 수 있다.
8. IF `ModelContainer` 생성이 실패한다, THEN THE App_Container SHALL 강제 언래핑과 `try!` 없이 오류를 처리하고, 실패 원인(오류 내용)을 로그로 1회 이상 남기며, 앱이 크래시로 종료되지 않고 사용자에게 데이터를 열 수 없음을 알리는 화면을 표시한다.
9. WHEN 앱이 시뮬레이터에서 실행된다, THE App_Container SHALL 조립한 서비스가 탭 뼈대(작업·기록·관리 3개 탭)의 루트 뷰에서 환경을 통해 읽히도록 하며, 실행 중인 앱에서 이 연결을 확인할 수 있어야 한다.
10. THE Foundation SHALL 시드 주입과 현재 트리 생성을 App_Container에서 수행하지 않는다(열린 질문 Q1, 시드 주입은 `seed-data` 범위).

### Requirement 8: 색상 Asset 기본 틀

**User Story:** As a 팀 개발자, I want 라이트/다크 색상 세트의 기본 틀이 준비되기를, so that 모든 화면이 같은 색상 Asset만 사용해 다크모드를 자연스럽게 지원한다.

#### Acceptance Criteria

1. THE Color_Assets SHALL `Assets.xcassets` 안의 모든 색상 세트에 Any(라이트) 값과 Dark 값을 각각 하나씩 정의한다. 두 값 중 하나라도 없는 색상 세트는 0개여야 한다.
2. THE Color_Assets SHALL 색상 세트마다 `Extensions/` 안의 `Color` 확장에 정적 프로퍼티를 하나씩 제공한다. 이 프로퍼티는 Asset 이름과 같은 이름의 색상 세트를 가리키며, 화면 코드에서 색상 이름 문자열을 직접 쓰지 않고 참조할 수 있게 한다.
3. WHEN 화면이 색상 세트의 정적 프로퍼티를 참조해 렌더링한다, THE Color_Assets SHALL 시스템 설정이 라이트이면 Any 값을, 다크이면 Dark 값을 표시한다.
4. WHEN 시스템 외형이 라이트와 다크 사이에서 바뀐다, THE Color_Assets SHALL 앱 재시작 없이 표시 중인 화면의 색상을 바뀐 외형의 값으로 갱신한다.
5. THE Foundation SHALL 화면 코드에서 색상 값을 직접 쓰지 않고 Color_Assets만 쓴다는 규칙(`project-spec.md` 11-1장)을 `Color` 확장의 문서화 주석(`///`)에 적는다.
6. IF `Color(red:green:blue:)`, `UIColor(red:` 같은 리터럴 색상 값이 Asset 정의 파일 외의 Swift 파일에서 발견된다, THEN THE Foundation SHALL 단위 테스트 또는 검사 스크립트를 실패로 종료하고, 발견된 파일 경로와 줄 번호를 실패 출력에 표시한다.
7. IF 색상 세트에 대응하는 정적 프로퍼티가 없거나, 정적 프로퍼티가 가리키는 이름의 색상 세트가 `Assets.xcassets`에 없다, THEN THE Foundation SHALL 단위 테스트를 실패로 종료하고, 어긋난 이름을 실패 출력에 표시한다.
8. WHERE 열린 질문 Q3에서 색상 세트 이름 목록이 확정된다, THE Color_Assets SHALL 확정된 이름 목록과 일치하는 색상 세트와 정적 프로퍼티를 제공한다. 확정 전에는 구체적인 색상 세트 이름과 색상 값을 정하지 않고 사용자 확인 후 추가한다.

### Requirement 9: 테스트 타깃

**User Story:** As a 팀 개발자, I want 단위 테스트를 바로 실행할 수 있는 타깃이 준비되기를, so that 다른 Spec이 순수 로직에 대한 테스트를 같은 경로에 추가한다.

#### Acceptance Criteria

1. THE App_Project SHALL 앱 타깃을 대상으로 하는 Test_Target을 정확히 1개 포함하고, 앱 타깃의 internal 타입을 `@testable import`로 참조할 수 있어야 한다.
2. WHEN `xcodebuild test`로 iOS 17 이상 iPhone 시뮬레이터를 대상으로 테스트를 실행한다, THE Test_Target SHALL 빌드 오류 0건, 경고로 인한 실패 0건으로 빌드되고 모든 테스트를 실행한다.
3. THE Test_Target SHALL 요구사항 3, 5, 6에서 정의한 round-trip, 멱등성, 기본값 기준을 각각 최소 1개의 단위 테스트로 검증한다.
4. THE Test_Target SHALL 각 테스트마다 메모리 전용 `ModelContainer`, 테스트별로 새로 만든 임시 폴더, 테스트별 고유 suite 이름의 `UserDefaults`를 사용하고, 테스트 종료 시 임시 폴더와 `UserDefaults` suite를 삭제한다.
5. WHEN 테스트 실행 순서를 바꾸거나 같은 테스트를 2회 연속 실행한다, THE Test_Target SHALL 두 실행의 통과/실패 결과가 같다.
6. WHEN Test_Target이 Mock_Services를 호출한다, THE Test_Target SHALL 프로토콜(`project-spec.md` 9장)마다 mock이 선언된 반환 타입(`SessionResult`, `TreeGrantResult` 등)의 값을 돌려주는지, 옵셔널 반환(`resumableSession`, `scene(for:)`)은 `nil`과 값 두 경우 모두 안전하게 처리하는지 검증한다.
7. IF 단위 테스트가 1개라도 실패한다, THEN THE Test_Target SHALL `xcodebuild test`를 0이 아닌 종료 코드로 끝내고 실패한 테스트 이름을 출력한다.
8. WHEN 작업 0(`project-spec.md` 15장)을 develop에 병합하는 PR을 연다, THE Test_Target SHALL 모든 테스트가 통과한 상태여야 하며, 통과하지 못하면 병합하지 않는다(`docs/integration-contracts.md`의 작업 0 통합 완료 조건 기준).

### Requirement 10: 탭 3개 뼈대

**User Story:** As a 팀 개발자, I want 작업/기록/관리 탭 뼈대가 준비되기를, so that 기능 Spec이 각자의 루트 화면을 같은 자리에 끼워 넣을 수 있다.

#### Acceptance Criteria

1. THE Tab_Skeleton SHALL `project-spec.md` 6-1장에 따라 하단 탭 3개를 왼쪽부터 "작업", "기록", "관리" 순서로 표시한다.
2. WHEN 앱이 실행된다, THE Tab_Skeleton SHALL "작업" 탭을 선택된 상태로 표시한다.
3. THE Tab_Skeleton SHALL 각 탭에 다른 탭과 독립된 `NavigationStack`을 하나씩 둔다.
4. THE Tab_Skeleton SHALL 작업 탭의 루트를 S1 자리, 기록 탭의 루트를 S9 자리, 관리 탭의 루트를 S10 자리로 둔다.
5. THE Tab_Skeleton SHALL 각 탭의 루트에 Placeholder_Screen을 표시한다. Placeholder_Screen은 해당 탭 이름과 자리 ID(S1, S9, S10 중 하나)를 한국어 문구로 보여 준다.
6. WHEN 한 탭에서 화면을 푸시한다, THE Tab_Skeleton SHALL 다른 두 탭의 `NavigationStack` 경로(푸시된 화면 수와 순서)를 바꾸지 않는다.
7. WHEN 사용자가 푸시된 화면이 있는 탭에서 다른 탭으로 이동했다가 같은 탭으로 돌아온다, THE Tab_Skeleton SHALL 이동 전에 푸시했던 화면 수와 순서를 그대로 유지한다.
8. WHERE 기기가 iPad이다, THE Tab_Skeleton SHALL 가로와 세로 방향 모두에서 3개 탭을 표시하고 각 탭을 탭하면 해당 탭의 루트 또는 마지막 화면으로 이동한다.
9. WHEN 사용자가 iPad에서 기기 방향을 가로와 세로 사이에서 바꾼다, THE Tab_Skeleton SHALL 선택된 탭과 각 탭의 푸시 상태를 유지한다.
10. THE Tab_Skeleton SHALL 탭 항목마다 한국어 VoiceOver 라벨을 제공하고, 라벨은 화면에 표시된 탭 이름("작업", "기록", "관리")과 같다.
11. THE Tab_Skeleton SHALL 탭 이름과 Placeholder_Screen의 모든 문구를 한국어로 표시한다.
12. THE Tab_Skeleton SHALL 퀴즈 진행과 결과용 전체 화면(`fullScreenCover`)과 S2~S8, S11, S12 화면을 구현하지 않는다.
13. WHEN 기기 글자 크기가 가장 큰 Dynamic Type 단계(접근성 크기 포함)로 설정된다, THE Tab_Skeleton SHALL Placeholder_Screen 텍스트를 줄바꿈이나 스크롤로 잘림 없이 모두 볼 수 있게 한다.
14. WHEN 앱이 라이트 모드 또는 다크 모드에서 실행된다, THE Tab_Skeleton SHALL Color_Assets에 정의된 라이트/다크 색상 세트만 사용해 Placeholder_Screen을 표시하고, 화면 코드에 색상 값을 직접 쓰지 않는다.

### Requirement 11: 공통 코드 규칙 준수

**User Story:** As a 리뷰어, I want 기반 코드가 11장의 공통 규칙을 지키기를, so that 이후 Spec이 같은 규칙으로 작성된 기반 위에서 개발한다.

#### Acceptance Criteria

1. THE Foundation SHALL 강제 언래핑(`!`)과 `try!`를 Foundation이 만드는 모든 Swift 소스 파일(앱 타깃과 테스트 타깃)에서 0건으로 유지한다(`project-spec.md` 11-1장). 옵셔널은 `guard let`, `if let`, `??`로 처리한다.
2. THE Foundation SHALL 사용자에게 보이는 모든 문자열(탭 이름, 화면 제목, 버튼 문구, 안내 문구, 접근성 라벨)을 한국어로 작성한다(`project-spec.md` 11-1장).
3. THE Foundation SHALL 외부 라이브러리 의존을 0개로 유지하고 Apple 기본 프레임워크(SwiftUI, SwiftData, Swift Charts 등)만 사용한다(`project-spec.md` 3장).
4. THE Foundation SHALL 데이터 처리 로직(세션, 추천, 출제, 트리, 미디어 파일 처리)을 `Services/`에 두고, 뷰 파일 안의 SwiftData 조회는 `@Query`만 사용한다(`project-spec.md` 11-1장).
5. THE Foundation SHALL `///` 문서화 주석을 Foundation이 정의하는 모든 공개 타입과 함수에 단다(`project-spec.md` 11-1장).
6. THE Foundation SHALL 색상을 Asset 카탈로그의 라이트/다크 색상 세트로만 정의하고, 화면 코드에는 색상 값을 직접 쓰지 않는다(`project-spec.md` 11-1장).
7. IF 모델 파일(`Models/`)을 바꾸는 PR을 올린다, THEN THE Foundation SHALL PR 설명에 변경 이유와 영향을 받는 Spec을 적고 팀원 모두에게 알린다(`project-spec.md` 8장, 11-4장).
8. IF 코드 리뷰에서 1~6번 규칙 위반이 발견된다, THEN THE Foundation SHALL 위반 항목을 수정한 뒤에만 `develop` 병합을 허용한다(`project-spec.md` 11-4장, `docs/integration-contracts.md`).

### Requirement 12: 통합 완료 조건

**User Story:** As a 모든 Spec의 담당자, I want foundation의 완료 기준이 `integration-contracts.md`와 일치하기를, so that mock만 만든 상태를 완료로 착각하지 않는다.

#### Acceptance Criteria

1. WHEN 요구사항 1~11의 수락 기준이 전부 충족된다, THE Foundation SHALL 완료로 표시한다.
2. IF 요구사항 1~11의 수락 기준 중 하나라도 충족되지 않았거나 mock 구현으로만 확인되었다, THEN THE Foundation SHALL 완료로 표시하지 않고 미충족 항목을 PR 설명에 적는다.
3. WHEN 앱이 iPhone 시뮬레이터와 iPad 시뮬레이터에서 각각 실행된다, THE Foundation SHALL `ModelContainer`, 서비스, Tab_Skeleton, Settings_Store, Media_File_Manager를 실제 앱 실행 경로에서 연결하고, 크래시 없이 "작업 / 기록 / 관리" 탭 3개를 표시한다.
4. WHEN Foundation이 develop에 병합된다, THE Foundation SHALL 다른 Spec이 Mock_Services와 8장 모델만으로 프로젝트를 빌드하고, 자기 화면 또는 로직의 Xcode 미리보기를 오류 없이 렌더링할 수 있는 상태를 제공한다.
5. WHEN 다른 Spec이 Foundation의 공통 계약(`project-spec.md` 8장, 9장)을 바꿔야 한다, THE Foundation SHALL `docs/integration-contracts.md` 4장 절차에 따라 `project-spec.md`를 먼저 수정하게 하고, 영향받는 Spec 이름을 해당 PR 설명에 적게 한다.
6. IF 8장 또는 9장의 공통 계약을 바꾸는 PR에 `project-spec.md` 수정이 포함되지 않았거나 영향받는 Spec 목록이 PR 설명에 없다, THEN THE Foundation SHALL 해당 PR을 병합 가능한 상태로 인정하지 않는다.
7. THE Foundation SHALL 세션 로직, 화면 S1~S12, 시드 로더, 애니메이션 장면, 차트, 문제 관리, 실제 소리·햅틱 재생, 에셋 제작, README를 구현 범위에 포함하지 않는다.
