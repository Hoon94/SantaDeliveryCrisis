# 통합 계약표

여러 Spec이 서로 연결되는 지점을 한 곳에 모은 문서입니다. 기준 문서는 [project-spec.md](../.kiro/steering/project-spec.md)이고, 이 표는 그 계약을 "누가 무엇과 연결해서 끝났다고 보는가"로 풀어 쓴 것입니다.

## 읽는 법

- **착수 조건:** 이것만 있으면 작업을 시작할 수 있습니다. 대부분 공통 계약과 `app-foundation`의 mock입니다.
- **통합 완료 조건:** 실제 구현끼리 연결되어 동작해야 완료입니다. mock으로 화면만 만든 상태는 완료가 아닙니다.
- **확인 상대:** 연결 대상 Spec의 담당자입니다. 두 담당자가 함께 연결을 확인합니다. 사람이 정해지면 이름을 적습니다.

## 1. Spec별 착수 조건과 통합 완료 조건

| Spec | 착수 조건 | 통합 완료 조건 | 확인 상대 |
| --- | --- | --- | --- |
| `app-foundation` | 확정된 공통 계약(steering) | `ModelContainer`와 서비스 조립, 탭·화면 이동 뼈대, mock, `MediaFileManaging`, `SettingsStore`가 앱에서 실제로 연결됨. iOS 17 배포 설정으로 빌드됨. 테스트 타깃이 실행됨 | 모든 Spec |
| `seed-data` | 공통 모델과 JSON 계약 | 첫 실행과 재실행에서 중복 없이 주입됨. 번들 미디어 경로가 맞음. 애니메이션 문제의 `animationID`가 `code-trace-animation`의 장면 목록과 일치함. 60문제 검수 완료 | `code-trace-animation`, `session-engine` |
| `session-engine` | 공통 타입과 mock | 실제 저장소, 문제 공급, 미디어 정리 호출, 설정 스냅샷과 연결됨. 저장 실패, 중복 호출, 재실행이 검증됨 | `seed-data`, `question-management`, `quiz-flow`, `task-and-tree`, `records-and-settings` |
| `quiz-flow` | 세션 계약과 mock | `session-engine`, `code-trace-animation`, 효과음 재생과 연결됨. 결과에서 작업실 탭으로 돌아감. 삭제된 문제가 오답 노트에서 빠짐 | `session-engine`, `code-trace-animation` |
| `task-and-tree` | 세션·트리 계약과 mock | `session-engine`의 후보 수(`availableCount`), 완료 결과와 연결됨. 시드 후보로 S3a/S3b와 S2의 장식 켜짐·꺼짐이 동작함. `quiz-flow`로 진입함. 완성 연출이 동작함 | `session-engine`, `seed-data`, `quiz-flow` |
| `code-trace-animation` | `TraceStep`, 장면 목록 계약, 임시 에셋 | 시드의 `animationID`와 단계 데이터로 S4에서 재생됨. 완료 신호가 `quiz-flow`에 전달됨. 장면을 못 찾았을 때 대체 동작이 있음. VoiceOver 설명이 나옴 | `seed-data`, `quiz-flow` |
| `records-and-settings` | 공통 모델과 `SettingsStore` 계약 | 실제 세션 기록(완료 시각, 카테고리 스냅샷)으로 집계됨. 세션 시작 때 설정값이 세션에 저장됨. 첫 실행과 기록이 없을 때 화면이 동작함. S9의 보관함 진입 → S8이 `TreeManaging.completedTrees()`의 실제 기록과 완성 날짜를 보여 주고, 기록이 없으면 빈 상태를 보여 줌. 트리 완성 직후 목록이 갱신됨 | `session-engine` |
| `question-management` | 공통 모델과 `MediaFileManaging` 계약 | 미디어 저장과 정리를 `MediaFileManaging`으로만 함. 수정·삭제 후 결과, 오답 노트, 후보 수가 갱신됨 | `session-engine`, `quiz-flow` |

에셋·사운드와 마감(README, GIF, 점검)은 Spec이 아니라 체크리스트입니다. 그래도 담당, 필요한 날짜, 파일 이름 규칙, 확인 방법을 정해서 완료 산출물로 취급합니다.

## 2. 공통 소유권

아래는 `app-foundation`이 만들고 소유합니다. 다른 Spec은 다시 정의하지 않습니다.

| 소유 대상 | 설명 |
| --- | --- |
| 데이터 모델과 enum | project-spec 8장 |
| 모듈 프로토콜, 결과 타입, mock | project-spec 9장 |
| `ModelContainer` 조립 | 한 곳에서 만들고 다른 Spec은 주입받음 |
| `SettingsStore` | 설정 키와 기본값 (설정 화면은 `records-and-settings`) |
| `MediaFileManaging` | 미디어 저장과 정리. 정리 로직은 이 한 곳 |
| 색상 Asset, 테스트 타깃 | 라이트/다크 색상, 단위 테스트 실행 경로 |

## 3. 통합 시나리오 5개

각 시나리오는 두 Spec 이상이 연결되어야 통과합니다. 한 Spec만 만든 상태에서는 확인할 수 없습니다.

| # | 시나리오 | 주 담당 | 연동 | 확인 내용 |
| --- | --- | --- | --- | --- |
| 1 | 오늘의 출제(혼합)와 카테고리·태그를 고른 선택 출제(출제 탭) | `task-and-tree` | `session-engine`, `seed-data` | 오늘의 출제가 여러 작업의 문제를 섞음. 태그를 여러 개 고르거나 하나도 안 고를 때 후보가 맞음. 후보가 모자라면 장식이 꺼지고, 선택한 카테고리 중 어느 것도 N문제를 못 채우면 그 문제 수가 잠김. 진행 중 세션이 있을 때 장식을 누르면 이어서 풀기/새로 시작 선택이 나옴 |
| 2 | 마지막 답을 저장한 직후 앱을 종료하고 다시 켬 | `quiz-flow` | `session-engine` | 이어서 풀기로 결과 계산부터 진행함. 이미 저장된 답을 다시 채점하지 않음 |
| 3 | 세션 완료를 두 번 호출함, 12칸 완성 | `session-engine` | `task-and-tree` | 장식이 한 번만 지급됨(항상 1개). 11칸에서 1개를 받으면 트리가 완성되고 빈 트리가 새로 시작됨 |
| 4 | 미디어 문제를 푼 뒤 문제를 수정하거나 삭제함 | `question-management` | `session-engine`, `quiz-flow` | 진행 중 세션은 이어 풀 수 있음. 삭제한 문제는 오답 노트에서 사라짐. 수정한 문제의 오답 노트는 풀 당시 내용으로 보임. 쓰이지 않는 파일만 정리됨 |
| 5 | 주·월 통계와 설정 변경 | `records-and-settings` | `session-engine` | 끝난 세션만 집계됨. 정답률 기준을 바꿔도 이미 시작한 세션은 시작 당시 값을 씀 |

## 4. 지키는 규칙

- 한 Spec이 완료를 선언하려면 위 표 1의 "통합 완료 조건"을 충족하고, 확인 상대와 함께 연결을 확인해야 합니다.
- 공통 계약(모델, 프로토콜)을 바꿀 때는 project-spec을 먼저 고치고, 영향을 받는 Spec의 문서·mock·소비 코드·테스트를 같은 변경에서 함께 고칩니다. 영향을 받는 Spec 목록을 PR에 적습니다.
- 기능 Spec이 공통 계약과 다르면 담당자가 임의로 해결하지 않고 공통 계약 변경으로 논의합니다.
- 문서(Spec) 작성과 코드 구현은 따로 진행합니다. 문서가 병합되어도 `app-foundation`의 코드는 아직 없습니다.
- Spec의 작업 완료 체크는 실제 구현을 확인한 뒤에만 합니다.
- `docs/future-work.md`의 제외 기능은 Spec에 다시 넣지 않습니다.

## 5. 진행 방식

- 팀원 4명이 처음에는 함께 작업합니다(`app-foundation`과, 계약 확인을 위한 `session-engine`). 한두 기능이 끝난 뒤에 기능별로 나눕니다.
- 시드 문제 작성과 에셋·효과음 제작은 `app-foundation` 코드를 기다리지 않고 처음부터 병렬로 진행할 수 있습니다.
- 각자 자기 기능이 끝나기 전에 첫 통합(한 문제 풀이 → 저장 → 재실행 → 결과 → 보상)을 일찍 한 번 확인합니다.
