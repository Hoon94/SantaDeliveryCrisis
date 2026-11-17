# 작업 0. 기반

- 상위 문서: [프로젝트 스펙](../../.kiro/steering/project-spec.md). 이 문서에서 말하는 5장, 8장, 9장, 11장은 그 문서의 장입니다. 데이터 모델(8장)과 모듈 인터페이스(9장)는 모든 작업이 맞춰야 하는 공통 계약이라 그쪽에 있습니다.
- 통합 완료 조건과 확인 담당: [통합 계약표](../integration-contracts.md)
- 표기: `[가정]`은 팀이 아직 확정하지 않은 내용입니다. 구현 전에 사용자에게 확인합니다(프로젝트 스펙 16장).

## 작업 범위

- 포함: Xcode 프로젝트 설정(iOS 17, iPad 방향), 폴더 구조, 8장 모델, enum, 9장 프로토콜과 결과 타입(`SessionResult`, `TreeGrantResult`, `QuestionSnapshot`, `TraceSceneAction` 빈 자리), 화면 미리보기용 가짜(mock) 구현, `MediaFileManaging`, `SettingsStore`(설정 키와 기본값), 테스트 타깃, iOS 17 배포 설정 확인, 색상 Asset 기본 틀, 탭 뼈대
- 의존: 없음
- 병렬 가능: 가장 먼저, 가능한 한 빨리 develop에 병합
