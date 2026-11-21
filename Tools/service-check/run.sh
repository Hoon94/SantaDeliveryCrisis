#!/bin/zsh
# 세션·출제·트리·시드 서비스 로직을 Xcode 없이 점검한다.
# 사용: Tools/service-check/run.sh         (실패한 항목만 표시)
#       VERBOSE=1 Tools/service-check/run.sh (통과한 항목도 표시)
# 앱 소스를 복사해 SwiftData 매크로(@Model 등)만 제거한 뒤, 가짜 ModelContext(stubs.swift)와 함께 컴파일해 실행한다.
# 실제 SwiftData 동작(저장, 롤백, 고유 제약)은 확인하지 않는다. 그 부분은 Xcode에서 확인한다.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$ROOT/Santa'sDeliveryCrisis"
HERE="$ROOT/Tools/service-check"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/models"
for f in Question QuizSession TreeRecord; do
  sed -E 's/^import SwiftData$//; s/@Model //; s/@Attribute\(\.unique\) //; s/@Relationship\(deleteRule: \.cascade\) //' \
    "$APP/Models/$f.swift" > "$WORK/models/$f.swift"
done
cp "$APP/Models/Enums.swift" "$APP/Models/WorkshopTask.swift" "$APP/Models/QuestionSnapshot.swift" "$WORK/models/"

swiftc -swift-version 5 -default-isolation MainActor -suppress-warnings \
  "$WORK"/models/*.swift \
  "$HERE/stubs.swift" \
  "$APP/Services/Protocols.swift" \
  "$APP/Services/SettingsStore.swift" \
  "$APP/Services/Reminders/DailyQuizReminderTime.swift" \
  "$APP/Services/SelectionCriteria.swift" \
  "$APP/Services/Accuracy.swift" \
  "$APP/Services/SeedLoader.swift" \
  "$APP/Services/QuestionSelector.swift" \
  "$APP/Services/BalancedSelection.swift" \
  "$APP/Services/DuplicateTitleLabeler.swift" \
  "$APP/Services/TaskRecommender.swift" \
  "$APP/Services/TreeManager.swift" \
  "$APP/Services/SessionManager.swift" \
  "$HERE/main.swift" \
  -o "$WORK/check"

"$WORK/check" "$APP/Resources/Seed/questions.json" > "$WORK/out.txt"
if [[ -n "${VERBOSE:-}" ]]; then cat "$WORK/out.txt"; else grep -v '^ok' "$WORK/out.txt" || true; fi
grep -q '^ALL PASSED' "$WORK/out.txt"
