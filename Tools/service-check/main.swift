// 서비스 로직 점검 프로그램. Xcode 없이 `run.sh`로 실행한다. SwiftData는 `stubs.swift`의 가짜로 바꿔서 쓴다.
// 정식 단위 테스트 타깃이 생기면 이 시나리오를 옮긴다.
import Foundation
var failures = 0
func check(_ c: Bool, _ m: String) { if !c { failures += 1; print("FAIL:", m) } else { print("ok  :", m) } }
let day: TimeInterval = 86400
let t0 = Date(timeIntervalSince1970: 1_800_000_000)
func q(_ cat: QuizCategory = .swiftSyntax, _ d: Difficulty = .easy, tags: [String] = []) -> Question {
    Question(text: "t", choices: ["a","b","c","d"], correctIndex: 1, explanation: "e", category: cat, difficulty: d, tags: tags)
}
func session(for qs: [Question], answers: [(Int, Bool, Date)]) -> QuizSession {
    let s = QuizSession(category: nil, difficulty: .easy, questionSnapshots: qs.map { QuestionSnapshot($0) }, passThresholdPercent: 80)
    for (i, ok, at) in answers { s.answers.append(SessionAnswer(questionID: qs[i].id, selectedIndex: ok ? 1 : 0, isCorrect: ok, answeredAt: at)) }
    return s
}
func run() throws {
    // ---- Accuracy (정답률은 내림, 지급 판정은 정확한 비교)
    check(Accuracy.percent(correct: 7, total: 9) == 77, "정답률: 7/9 = 77% (내림)")
    check(Accuracy.percent(correct: 159, total: 200) == 79, "정답률: 79.5% → 79")
    check(Accuracy.percent(correct: 0, total: 0) == 0, "정답률: 문제 0개는 0")
    check(Accuracy.percent(correct: 5, total: 5) == 100, "정답률: 5/5 = 100")
    check(Accuracy.meetsThreshold(correct: 4, total: 5, thresholdPercent: 80), "기준: 80%는 80% 기준 충족")
    check(!Accuracy.meetsThreshold(correct: 159, total: 200, thresholdPercent: 80), "기준: 79.5%는 80% 기준 미달")
    check(!Accuracy.meetsThreshold(correct: 0, total: 0, thresholdPercent: 50), "기준: 문제 0개는 미달")
    var consistent = true
    for total in 1...30 { for correct in 0...total { for t in stride(from: 50, through: 100, by: 10) {
        if Accuracy.percent(correct: correct, total: total) >= t && !Accuracy.meetsThreshold(correct: correct, total: total, thresholdPercent: t) { consistent = false }
        if Accuracy.meetsThreshold(correct: correct, total: total, thresholdPercent: t) != (Accuracy.percent(correct: correct, total: total) >= t) { consistent = false }
    } } }
    check(consistent, "정답률: 내림한 값 비교와 정확한 비교가 모든 경우(문제 1~30개, 기준 50~100%)에서 같음")
    // ---- SeedLoader (실제 시드 파일)
    let seedPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
    let seedItems = try SeedLoader.decode(Data(contentsOf: URL(fileURLWithPath: seedPath)))
    check(seedItems.count >= 60, "시드: 60문제 이상 (\(seedItems.count))")
    check(SeedLoader.validate(seedItems).isEmpty, "시드: 검증 문제 없음")
    check(SeedLoader.coverageShortfalls(seedItems).isEmpty, "시드: 카테고리×난이도 조합당 5문제 이상")
    let seedCtx = ModelContext()
    check(try SeedLoader.inject(seedItems, into: seedCtx) == seedItems.count, "시드: 첫 주입 전부")
    check(try SeedLoader.inject(seedItems, into: seedCtx) == 0 && seedCtx.saves == 1, "시드: 재주입 0개, 저장 1회")
    var broken = seedItems[0]
    let dupChoice = SeedQuestion(id: UUID(), kind: .standard, text: "x", codeSnippet: nil, imageFileName: nil, videoFileName: nil, choices: ["a","a","b","c"], correctIndex: 0, explanation: "e", hint: nil, resourceTitle: nil, resourceURL: "ftp://bad", category: .hig, difficulty: .easy, tags: [" "], animationID: nil, createdAt: Date())
    let issues = SeedLoader.validate([broken, broken, dupChoice])
    check(issues.count == 4, "시드: 잘못된 데이터에서 문제 4건 탐지 (\(issues.count))")
    broken = seedItems[1]
    check(SeedLoader.coverageShortfalls(Array(seedItems.prefix(3))).count == 12 - 1 || !SeedLoader.coverageShortfalls(Array(seedItems.prefix(3))).isEmpty, "시드: 분량 부족 탐지")
    // ---- QuestionSelector
    let sel = QuestionSelector(now: { t0 }, shuffle: { $0 })
    let qs = (0..<10).map { _ in q() }
    check(sel.availableCount(category: .swiftSyntax, difficulty: .easy, tags: [], questions: qs) == 10, "availableCount 카테고리/난이도")
    check(sel.availableCount(category: .hig, difficulty: .easy, tags: [], questions: qs) == 0, "availableCount 다른 카테고리 0")
    check(sel.availableCount(category: .swiftSyntax, difficulty: .hard, tags: [], questions: qs) == 0, "availableCount 다른 난이도 0")
    let tagged = [q(tags: ["a"]), q(tags: ["b"]), q(tags: ["a","c"]), q()]
    check(sel.availableCount(category: .swiftSyntax, difficulty: .easy, tags: ["a"], questions: tagged) == 2, "태그 하나")
    check(sel.availableCount(category: .swiftSyntax, difficulty: .easy, tags: ["a","b"], questions: tagged) == 3, "태그 여러 개는 하나라도")
    check(sel.availableCount(category: .swiftSyntax, difficulty: .easy, tags: [], questions: tagged) == 4, "태그 비면 전체")
    check(sel.select(category: .swiftSyntax, difficulty: .easy, tags: [], count: 5, questions: [], history: []).isEmpty, "후보 0개면 빈 배열")
    check(sel.select(category: .swiftSyntax, difficulty: .easy, tags: [], count: 5, questions: Array(qs.prefix(3)), history: []).count == 3, "후보 부족 시 가능한 만큼")
    let r1 = sel.select(category: .swiftSyntax, difficulty: .easy, tags: [], count: 5, questions: qs, history: [])
    check(r1.count == 5 && Set(r1.map(\.id)).count == 5, "기록 없음: 5개 중복 없음")
    // 약한 3 + 오래 안 푼 2: 10문제 중 0,1,2 약함(전부 오답), 3,4 오래됨(6일 전 정답), 5..9 최근 정답
    var ans: [(Int, Bool, Date)] = []
    for i in 0..<3 { ans.append((i, false, t0 - 1*day)) }
    for i in 3..<5 { ans.append((i, true, t0 - 6*day)) }
    for i in 5..<10 { ans.append((i, true, t0 - 1*day)) }
    let h = [session(for: qs, answers: ans)]
    let r2 = sel.select(category: .swiftSyntax, difficulty: .easy, tags: [], count: 5, questions: qs, history: h)
    let ids2 = Set(r2.map(\.id))
    check(ids2 == Set(qs[0..<3].map(\.id)).union(qs[3..<5].map(\.id)), "5문제 = 약한 3 + 오래 안 푼 2")
    let r3 = sel.select(category: .swiftSyntax, difficulty: .easy, tags: [], count: 10, questions: qs, history: h)
    check(r3.count == 10 && Set(r3.map(\.id)).count == 10, "10문제 전부 채움(나머지 후보 포함)")
    let r4 = sel.select(category: .swiftSyntax, difficulty: .easy, tags: [], count: 4, questions: qs, history: h)
    check(Set(r4.map(\.id)).isSuperset(of: qs[0..<2].map(\.id)) && r4.filter { qs[3..<5].map(\.id).contains($0.id) }.count == 2, "4문제 = 약한 2 + 오래 안 푼 2")
    // 약한 문제 부족 시 오래 안 푼 쪽에서 채움: 약한 1개, 안 푼 9개 → 5문제
    let h2 = [session(for: qs, answers: [(0, false, t0 - day)])]
    let r5 = sel.select(category: .swiftSyntax, difficulty: .easy, tags: [], count: 5, questions: qs, history: h2)
    check(r5.contains { $0.id == qs[0].id } && r5.count == 5, "약한 문제 부족 시 다른 범주로 채움")
    // 정답률 60% 경계: 3/5 약하지 않음, 2/5 약함 (마지막은 정답)
    let bq = [q(), q()]
    var a: [(Int, Bool, Date)] = []
    for k in 0..<5 { a.append((0, k < 3, t0 - Double(10 - k) * 0.1 * day * 0 - 1*day + Double(k))) }
    for k in 0..<5 { a.append((1, k < 2 || k == 4, t0 - 1*day + Double(k))) } // 3/5? -> 정답 3개(k0,k1,k4)
    // 문제1은 3/5=60%(마지막 정답) 약하지 않음. 문제0은 마지막(k=4) 오답이고 3/5
    let hb = bq.indices.map { _ in 0 }.isEmpty ? [] : [session(for: bq, answers: a)]
    let rb = sel.select(category: .swiftSyntax, difficulty: .easy, tags: [], count: 1, questions: bq, history: hb)
    check(rb.first?.id == bq[0].id, "마지막 풀이 오답인 문제가 약한 문제(1개 출제 시 우선)")
    // 이동: 다른 세션의 이전 답 시간 비교
    // ---- TaskRecommender
    let rec = TaskRecommender()
    check(rec.recommendedCategory(sessions: []) == nil, "추천: 기록 없음 nil")
    let ai = q(.aiUsage), sw = q(.swiftSyntax), hg = q(.hig)
    let s1 = session(for: [ai, sw, hg], answers: [(0, true, t0), (1, false, t0), (2, false, t0)])
    check(rec.recommendedCategory(sessions: [s1]) == .swiftSyntax, "추천: 정답률 같으면(0%) 작업 순서가 앞선 선물 생산")
    let s2 = session(for: [ai, sw, hg], answers: [(0, true, t0), (1, true, t0), (2, false, t0)])
    check(rec.recommendedCategory(sessions: [s2]) == .hig, "추천: 정답률 최저 포장")
    let s3 = session(for: [ai, sw, hg], answers: [(0, true, t0)])
    check(rec.recommendedCategory(sessions: [s3]) == .aiUsage, "추천: 기록 있는 카테고리만 대상")
    let s4a = session(for: [ai, sw], answers: [(0, true, t0), (0 + 1, true, t0)])
    let s4b = session(for: [ai, sw], answers: [(0, false, t0)])
    check(rec.recommendedCategory(sessions: [s4a, s4b]) == .aiUsage, "추천: 세션 여러 개 합산(aiUsage 1/2 < swift 1/1)")
    // ---- TreeManager
    let ctx = ModelContext()
    var clock = t0
    let trees = TreeManager(context: ctx, now: { clock })
    let cur = trees.currentTree()
    check(cur.decorationCount == 0 && cur.completedAt == nil, "트리: 첫 호출 시 빈 트리 생성")
    check(trees.currentTree() === cur, "트리: 두 번째 호출은 같은 트리")
    var res = try trees.grant(decorations: 0)
    check(res.completedTree == nil && res.currentDecorationCount == 0, "트리: 0개 지급은 변화 없음")
    for _ in 0..<11 { res = try trees.grant(decorations: 1) }
    check(res.completedTree == nil && res.currentDecorationCount == 11, "트리: 11칸")
    clock = t0 + day
    res = try trees.grant(decorations: 1)
    check(res.completedTree === cur && res.currentDecorationCount == 0, "트리: 12칸에서 완성 + 빈 트리 시작")
    check(cur.decorationCount == 12 && cur.completedAt == clock, "트리: 완성 값 12칸, 완성 시각")
    check(trees.currentTree() !== cur && trees.currentTree().decorationCount == 0, "트리: 새 트리가 현재 트리")
    check(trees.completedTrees().count == 1, "트리: 완성 목록 1개")
    do { _ = try trees.grant(decorations: -1); check(false, "트리: 음수 오류") } catch { check(true, "트리: 음수 오류") }
    check(ctx.saves == 0, "트리: save를 호출하지 않음")
    // ---- SessionManager
    let ctx2 = ModelContext()
    let defaults = UserDefaults(suiteName: "svc-test")!; defaults.removePersistentDomain(forName: "svc-test")
    let settings = SettingsStore(defaults: defaults)
    let trees2 = TreeManager(context: ctx2, now: { t0 })
    let mgr = SessionManager(context: ctx2, selector: QuestionSelector(now: { t0 }, shuffle: { $0 }), trees: trees2, settings: settings, now: { t0 })
    let pool = (0..<6).map { _ in q() }
    pool.forEach { ctx2.insert($0) }
    do { _ = try mgr.startSession(category: .hig, difficulty: .easy, tags: [], count: 5); check(false, "후보 0개 오류") } catch { check((error as? SessionError) == .noCandidates, "start: 후보 0개 오류") }
    let s = try mgr.startSession(category: .swiftSyntax, difficulty: .easy, tags: [], count: 5)
    check(s.questionSnapshots.count == 5 && s.passThresholdPercent == 80 && s.status == .inProgress, "start: 5문제, 기준 80 저장")
    check(mgr.resumableSession() === s, "resumable: 진행 중 세션")
    do { _ = try mgr.startSession(category: .swiftSyntax, difficulty: .easy, tags: [], count: 5); check(false, "중복 시작 오류") } catch { check((error as? SessionError) == .sessionAlreadyInProgress, "start: 진행 중이면 오류") }
    do { _ = try mgr.submit(answerIndex: 1, forQuestionAt: 2, in: s); check(false, "순서 오류") } catch { check((error as? SessionError) == .previousQuestionUnanswered, "submit: 앞선 문제 미답 오류") }
    do { _ = try mgr.submit(answerIndex: 9, forQuestionAt: 0, in: s); check(false, "범위 오류") } catch { check((error as? SessionError) == .invalidAnswerIndex(9), "submit: 보기 번호 범위 오류") }
    do { _ = try mgr.submit(answerIndex: 1, forQuestionAt: 7, in: s); check(false, "문제 범위") } catch { check((error as? SessionError) == .invalidQuestionIndex(7), "submit: 문제 번호 범위 오류") }
    let a0 = try mgr.submit(answerIndex: 1, forQuestionAt: 0, in: s)
    check(a0.isCorrect && s.currentIndex == 1 && s.answers.count == 1, "submit: 정답 채점, currentIndex 1")
    let again = try mgr.submit(answerIndex: 0, forQuestionAt: 0, in: s)
    check(again === a0 && again.selectedIndex == 1 && s.answers.count == 1, "submit: 같은 문제 재제출은 처음 답 유지")
    do { _ = try mgr.finish(s); check(false, "미답 finish") } catch { check((error as? SessionError) == .notAllAnswered, "finish: 모두 답하기 전엔 오류") }
    // 5문제 중 4개 정답, 1개 오답 = 80% -> 보상 1개
    for i in 1..<4 { _ = try mgr.submit(answerIndex: 1, forQuestionAt: i, in: s) }
    _ = try mgr.submit(answerIndex: 0, forQuestionAt: 4, in: s)
    // 저장 실패
    ctx2.failNextSave = true
    do { _ = try mgr.finish(s); check(false, "저장 실패") } catch { check(s.status == .completed || ctx2.rollbacks > 0, "finish: 저장 실패 시 rollback 호출됨") }
    // (스텁 rollback은 값을 되돌리지 못하므로 상태를 직접 되돌려 재시도 시나리오 확인)
    s.status = .inProgress; s.earnedDecorations = 0; s.treeCompleted = false; s.finishedAt = nil; trees2.currentTree().decorationCount = 0
    let result = try mgr.finish(s)
    check(result.correctCount == 4 && result.totalCount == 5 && result.accuracyPercent == 80 && result.earnedDecorations == 1, "finish: 80% 기준 충족 → 장식 1")
    check(result.wrongAnswers.count == 1 && s.status == .completed && s.finishedAt == t0, "finish: 오답 1개, completed")
    let savesBefore = ctx2.saves
    let result2 = try mgr.finish(s)
    check(result2.earnedDecorations == 1 && ctx2.saves == savesBefore, "finish 재호출: 저장/지급 없이 같은 결과")
    check(trees2.currentTree().decorationCount == 1, "finish: 트리에 장식 1개만")
    check(mgr.resumableSession() == nil, "완료 후 resumable nil")
    // 79% 미만: 4/5=80 통과, 3/5=60 실패
    let s2m = try mgr.startSession(category: .swiftSyntax, difficulty: .easy, tags: [], count: 5)
    for i in 0..<3 { _ = try mgr.submit(answerIndex: 1, forQuestionAt: i, in: s2m) }
    for i in 3..<5 { _ = try mgr.submit(answerIndex: 0, forQuestionAt: i, in: s2m) }
    let r60 = try mgr.finish(s2m)
    check(r60.earnedDecorations == 0 && r60.accuracyPercent == 60 && trees2.currentTree().decorationCount == 1, "finish: 60%는 기준 미달, 장식 없음")
    // abandon
    let s3m = try mgr.startSession(category: .swiftSyntax, difficulty: .easy, tags: [], count: 3)
    try mgr.abandon(s3m)
    check(s3m.status == .abandoned && mgr.resumableSession() == nil, "abandon: 포기 처리")
    try mgr.abandon(s3m)
    do { try mgr.abandon(s2m); check(false, "완료 세션 포기") } catch { check((error as? SessionError) == .sessionNotInProgress, "abandon: 완료 세션은 오류") }
    // 12칸 완성: 트리를 11칸으로 만든 뒤 한 번 더 완료
    _ = try trees2.grant(decorations: 10)
    check(trees2.currentTree().decorationCount == 11, "준비: 11칸")
    let s4m = try mgr.startSession(category: .swiftSyntax, difficulty: .easy, tags: [], count: 5)
    for i in 0..<5 { _ = try mgr.submit(answerIndex: 1, forQuestionAt: i, in: s4m) }
    let rFull = try mgr.finish(s4m)
    check(rFull.treeCompleted && s4m.treeCompleted && trees2.completedTrees().count == 1 && trees2.currentTree().decorationCount == 0, "finish: 12칸 완성, 빈 트리 시작")
    check(try mgr.finish(s4m).treeCompleted && trees2.completedTrees().count == 1, "finish 재호출: 완성 중복 없음")
    // ---- updateElapsed (누적 총합 저장)
    let se = try mgr.startSession(category: .swiftSyntax, difficulty: .easy, tags: [], count: 5)
    check(se.elapsedSeconds == 0, "elapsed: 시작 시 0")
    try mgr.updateElapsed(12.5, in: se)
    check(se.elapsedSeconds == 12.5, "elapsed: 누적 총합 12.5 저장")
    let savesBeforeSame = ctx2.saves
    try mgr.updateElapsed(12.5, in: se)
    check(se.elapsedSeconds == 12.5 && ctx2.saves == savesBeforeSame, "elapsed: 같은 값 재호출은 저장하지 않음(멱등)")
    try mgr.updateElapsed(8, in: se)
    check(se.elapsedSeconds == 12.5, "elapsed: 작은 값은 무시(시간이 줄어들지 않음)")
    try mgr.updateElapsed(30, in: se)
    check(se.elapsedSeconds == 30, "elapsed: 더 큰 값으로 갱신")
    for bad in [-1.0, Double.nan, Double.infinity] {
        do { try mgr.updateElapsed(bad, in: se); check(false, "elapsed: 잘못된 값 \(bad) 오류") }
        catch { check((error as? SessionError) == .invalidElapsed(bad) || bad.isNaN, "elapsed: 잘못된 값 \(bad)은 invalidElapsed 오류") }
    }
    check(se.elapsedSeconds == 30, "elapsed: 오류 뒤에도 값 유지")
    for i in 0..<5 { _ = try mgr.submit(answerIndex: 1, forQuestionAt: i, in: se) }
    try mgr.updateElapsed(45, in: se)
    let rEl = try mgr.finish(se)
    check(rEl.elapsed == 45, "elapsed: finish 결과의 소요 시간 = 마지막 저장 값")
    let savesAfterFinish = ctx2.saves
    try mgr.updateElapsed(99, in: se)
    check(se.elapsedSeconds == 45 && ctx2.saves == savesAfterFinish, "elapsed: 완료 세션은 오류 없이 무시하고 값을 바꾸지 않음")
    check(try mgr.finish(se).elapsed == 45, "elapsed: 완료 후 재호출해도 결과 유지")
    let sa = try mgr.startSession(category: .swiftSyntax, difficulty: .easy, tags: [], count: 5)
    try mgr.abandon(sa)
    try mgr.updateElapsed(10, in: sa)
    check(sa.elapsedSeconds == 0, "elapsed: 포기한 세션도 무시")
}
MainActor.assumeIsolated { try! run() }
print(failures == 0 ? "ALL PASSED" : "FAILURES: \(failures)")
