/* 저장소의 시드 문제 일부. 실제 앱의 서비스나 저장소에는 접근하지 않는다. */
const QUESTIONS = [
  {
    "text": "다음 코드에서 pi의 타입으로 Swift가 추론하는 것은?",
    "codeSnippet": "let pi = 3.14159",
    "choices": [
      "Double",
      "Float",
      "Int",
      "Decimal"
    ],
    "correctIndex": 0,
    "explanation": "소수 리터럴(코드에 직접 적은 값)에는 Float가 아니라 항상 Double이 추론됩니다.",
    "hint": null,
    "category": "swiftSyntax"
  },
  {
    "text": "iOS에서 사용자가 동작 줄이기(Reduce Motion) 설정을 켰을 때, HIG가 앱에 요구하는 반응은 무엇일까요?",
    "codeSnippet": null,
    "choices": [
      "자동·반복 애니메이션과 확대·축소 같은 움직임을 줄인다",
      "모든 애니메이션을 같은 속도로 유지하되 효과음만 끄는 방식으로 대응한다",
      "재생 속도를 두 배로 높여 더 빨리 끝나게 한다",
      "움직임 대신 화면을 번쩍이게 해서 변화를 알린다"
    ],
    "correctIndex": 0,
    "explanation": "동작 줄이기가 켜지면 자동·반복 애니메이션, 확대·축소, 주변부 움직임을 줄여야 합니다. 어지러움이나 발작을 유발할 수 있는 효과를 피하려는 설정입니다.",
    "hint": "설정 이름이 힌트입니다.",
    "category": "hig"
  },
  {
    "text": "HIG는 생성형 AI의 환각(hallucination)을 어떻게 설명할까요?",
    "codeSnippet": null,
    "choices": [
      "모델이 사용자의 입력을 이해하지 못해 응답 자체를 거부하는 것",
      "모델이 같은 질문에도 항상 똑같은 답만 반복해서 내놓는 것",
      "모델의 응답이 네트워크 문제로 중간에 끊겨 버리는 것",
      "확신이 없을 때 그럴듯하지만 지어낸 내용을 만드는 것"
    ],
    "correctIndex": 3,
    "explanation": "HIG는 모델이 그럴듯하지만 사실이 아닌 내용을 사실처럼 보여 줄 수 있다고 설명합니다. 그래서 AI 콘텐츠에 오류가 있을 수 있음을 알려야 합니다.",
    "hint": "모델이 모를 때 어떻게 '채우는지' 생각해 보세요.",
    "category": "aiUsage"
  },
  {
    "text": "한 뷰 안에서 소유하는 값 타입 데이터의 단일 진실 공급원(single source of truth)을 만들 때 쓰는 프로퍼티 래퍼는?",
    "codeSnippet": null,
    "choices": [
      "@Binding",
      "@State",
      "@Bindable",
      "@Environment"
    ],
    "correctIndex": 1,
    "explanation": "@State는 SwiftUI가 저장소를 관리하는 값으로, 뷰 계층에서 값 타입의 단일 진실 공급원 역할을 합니다. @Binding은 다른 곳에 있는 진실 공급원에 연결만 합니다.",
    "hint": "저장하는 쪽과 연결만 하는 쪽을 구분해 보세요.",
    "category": "swiftUIPractice"
  },
  {
    "text": "값을 한 번 정하면 바꿀 수 없는 상수를 선언할 때 쓰는 키워드는?",
    "codeSnippet": null,
    "choices": [
      "var",
      "let",
      "const",
      "static"
    ],
    "correctIndex": 1,
    "explanation": "상수는 let, 변수는 var로 선언합니다. let으로 선언한 값은 나중에 다른 값을 대입할 수 없습니다.",
    "hint": null,
    "category": "swiftSyntax"
  },
  {
    "text": "앱에 시스템 색을 적용하는 방법으로 HIG가 권하는 것은 무엇일까요?",
    "codeSnippet": null,
    "choices": [
      "디자인 문서의 RGB 값을 코드에 복사해 상수로 쓴다",
      "첫 출시 때 확인한 색 값을 앱에 고정해 둔다",
      "문서에 적힌 값 대신 API로 시스템 색을 지정한다",
      "화면 캡처에서 색을 추출해 같은 값을 쓴다"
    ],
    "correctIndex": 2,
    "explanation": "문서에 적힌 시스템 색 값은 참고용이고, 실제 값은 릴리스마다 달라질 수 있습니다. 그래서 값을 하드코딩(코드에 직접 박아 넣기)하지 않고 API로 지정해야 합니다.",
    "hint": "값은 릴리스마다 달라질 수 있습니다.",
    "category": "hig"
  },
  {
    "text": "Google 문서에서 프롬프트에 예시를 몇 개 넣은 방식은 무엇이라고 부를까요?",
    "codeSnippet": null,
    "choices": [
      "zero-shot 프롬프트",
      "fallback 프롬프트",
      "chained 프롬프트",
      "few-shot 프롬프트"
    ],
    "correctIndex": 3,
    "explanation": "예시가 하나도 없는 프롬프트는 zero-shot, 몇 개의 예시를 넣은 프롬프트는 few-shot이라고 부릅니다. 예시는 형식과 말투를 맞추는 데 자주 쓰입니다.",
    "hint": "'shot'은 프롬프트에 넣은 예시를 세는 단위입니다.",
    "category": "aiUsage"
  },
  {
    "text": "@AppStorage가 값을 읽고 쓰는 저장소는 무엇인가요?",
    "codeSnippet": null,
    "choices": [
      "iCloud 키-값 저장소",
      "SwiftData",
      "UserDefaults",
      "FileManager"
    ],
    "correctIndex": 2,
    "explanation": "@AppStorage는 UserDefaults에 있는 값을 반영하고, 그 값이 바뀌면 뷰를 다시 그리게 만듭니다. 간단한 설정값 저장에 알맞습니다.",
    "hint": null,
    "category": "swiftUIPractice"
  },
  {
    "text": "다음 코드를 컴파일하면 어떻게 되는가?",
    "codeSnippet": "let i = 1\nif i {\n    print(\"yes\")\n}",
    "choices": [
      "i가 0이 아니므로 yes가 출력된다",
      "런타임에 yes가 출력되고 경고만 나온다",
      "i가 자동으로 true로 변환되어 실행된다",
      "Int는 Bool로 쓸 수 없다는 컴파일 오류가 난다"
    ],
    "correctIndex": 3,
    "explanation": "Swift는 타입 안전 언어라서 if 조건에는 Bool만 쓸 수 있습니다. 숫자를 조건으로 쓰려면 i == 1처럼 비교해야 합니다.",
    "hint": "C 언어와 달리 숫자는 참/거짓으로 취급되지 않습니다.",
    "category": "swiftSyntax"
  },
  {
    "text": "색, 텍스트, 소리, 햅틱처럼 여러 방식으로 피드백을 함께 주라고 HIG가 안내하는 이유는 무엇일까요?",
    "codeSnippet": null,
    "choices": [
      "한 가지 방식만 쓰면 시스템이 피드백을 아예 표시해 주지 않기 때문에 그렇다",
      "App Store 심사에서 네 가지 방식을 모두 요구하기 때문에",
      "무음이거나 화면을 보지 않거나 VoiceOver를 써도 받을 수 있게 하려고",
      "피드백 횟수를 늘려 사용자의 주의를 계속 끌어 두려고"
    ],
    "correctIndex": 2,
    "explanation": "여러 방식을 함께 쓰면 소리를 끄거나 화면을 보지 않거나 VoiceOver(화면 읽기 기능)를 쓰는 사람도 피드백을 받을 수 있습니다.",
    "hint": null,
    "category": "hig"
  },
  {
    "text": "Anthropic 문서에서 컨텍스트 윈도우(context window)는 무엇을 뜻할까요?",
    "codeSnippet": null,
    "choices": [
      "모델이 사전 학습에 사용한 전체 데이터를 보관해 두는 저장 공간",
      "모델이 한 번에 화면에 그려 낼 수 있는 글자 수의 최대치",
      "응답을 포함해 모델이 참조할 수 있는 모든 텍스트",
      "대화 기록이 서버에 보관되는 기간과 삭제 주기"
    ],
    "correctIndex": 2,
    "explanation": "컨텍스트 윈도우는 모델의 작업 기억 공간에 가깝습니다. 학습에 쓴 방대한 데이터와는 다르며, 모델이 생성하는 응답도 그 안에 포함됩니다.",
    "hint": null,
    "category": "aiUsage"
  },
  {
    "text": "`@Environment(\\.colorScheme) var colorScheme` 로 읽은 환경 값에 대한 설명으로 맞는 것은?",
    "codeSnippet": null,
    "choices": [
      "값을 읽고 직접 대입해 앱 전체에 적용할 수 있다",
      "뷰가 처음 만들어질 때 한 번만 읽히고 이후 갱신되지 않는다",
      "값을 읽을 수 있고, 값이 바뀌면 이를 쓰는 부분이 갱신된다",
      "같은 뷰 안에서만 쓰며 자식 뷰에는 전달되지 않는다"
    ],
    "correctIndex": 2,
    "explanation": "@Environment는 환경 값을 읽는 용도이며 직접 설정하지는 못합니다. 값을 바꾸고 싶으면 environment 수정자로 덮어씁니다. 사용자가 외형 설정을 바꾸면 의존하는 부분이 갱신됩니다.",
    "hint": null,
    "category": "swiftUIPractice"
  },
  {
    "text": "guard let으로 만든 상수는 어디에서 사용할 수 있는가?",
    "codeSnippet": null,
    "choices": [
      "guard 문의 else 블록 안에서만",
      "guard 문이 있는 줄에서만",
      "guard 문 다음에 이어지는 코드",
      "같은 파일의 모든 함수"
    ],
    "correctIndex": 2,
    "explanation": "if let으로 만든 상수는 if 본문 안에서만 쓸 수 있지만, guard로 만든 상수는 guard 다음 줄부터 계속 쓸 수 있습니다.",
    "hint": "if let과 범위를 비교해 보세요.",
    "category": "swiftSyntax"
  },
  {
    "text": "iOS에서 안전 영역(safe area)은 무엇을 뜻할까요?",
    "codeSnippet": null,
    "choices": [
      "화면 가장자리에 항상 비워 두어야 하는 고정된 여백 영역",
      "툴바, 탭 바, 하드웨어 기능에 가려지지 않는 영역",
      "앱의 데이터를 안전하게 보관하도록 분리된 샌드박스 영역",
      "한 손으로 닿기 쉬운 화면 아래쪽 엄지손가락 영역"
    ],
    "correctIndex": 1,
    "explanation": "안전 영역은 가장자리가 하드웨어 기능(예: Dynamic Island)이나 툴바, 탭 바, 상태 바 같은 다른 뷰에 덮이지 않는 영역입니다. 콘텐츠와 컨트롤이 가려지지 않도록 이 영역을 지켜야 합니다.",
    "hint": null,
    "category": "hig"
  },
  {
    "text": "Anthropic 문서가 환각을 줄이는 기본 방법으로 안내한 프롬프트 작성법은 무엇일까요?",
    "codeSnippet": null,
    "choices": [
      "모르면 모른다고 말해도 된다고 적는다",
      "항상 하나의 답을 반드시 내놓으라고 강하게 요구한다",
      "질문을 가능한 한 짧은 한 문장으로 줄인다",
      "답변을 최대한 길고 자세하게 쓰라고 요청한다"
    ],
    "correctIndex": 0,
    "explanation": "모델에게 불확실함을 인정할 허락을 주면 지어낸 정보가 크게 줄 수 있다고 문서는 설명합니다. 그래도 완전히 없애 주지는 않습니다.",
    "hint": "모델이 답을 억지로 만들어 내지 않아도 되게 해 주세요.",
    "category": "aiUsage"
  }
];

const PHASES = [
  {id:'wish',name:'소원 접수',place:'소원 접수실',character:'산타',color:'#e49a85',
   caption:'편지를 살펴보는 산타와 오늘의 소원을 읽어요.',
   idle:'오늘은 어떤 소원이 왔을까?',
   thinkingLines:['편지를 차근차근 읽어 보자.','다른 소원과 헷갈린 건 아닐까?','급하지 않아. 한 번 더 살펴보자.','중요한 단어를 찾아볼까?','어떤 뜻인지 같이 생각해 보자.']},
  {id:'factory',name:'선물 생산',place:'장난감 공방',character:'생산 엘프',color:'#e4ba6f',
   caption:'초록 작업복의 엘프와 부품을 맞추며 선물을 만들어요.',
   idle:'좋아, 선물을 만들 준비가 됐어!',
   thinkingLines:['부품 하나씩 비교해 보자.','조립 순서를 다시 떠올려 볼까?','다른 방법도 천천히 살펴보자.','서두르지 말고 모양을 맞춰 보자.','작은 차이가 있을지도 몰라.']},
  {id:'wrap',name:'포장',place:'리본 포장실',character:'포장 엘프',color:'#97c59e',
   caption:'포장 담당 엘프와 상자를 고르고 리본을 묶어요.',
   idle:'이 선물에는 어떤 리본이 어울릴까?',
   thinkingLines:['모서리까지 꼼꼼히 살펴보자.','리본을 묶기 전에 한 번 더 생각해 보자.','비슷해 보여도 다른 점이 있을까?','천천히 골라도 괜찮아.','포장 순서를 떠올려 보면 어떨까?']},
  {id:'sleigh',name:'썰매 적재',place:'눈 덮인 출발장',character:'루돌프',color:'#96bdcf',
   caption:'루돌프와 마지막 선물을 싣고 출발을 준비해요.',
   idle:'선물들을 싣고 출발할 준비를 하자!',
   thinkingLines:['짐의 균형을 다시 살펴보자.','출발 전에는 차근차근 확인해야지.','다른 자리에 놓으면 어떨까?','천천히 생각해. 아직 출발 전이니까!','놓친 선물이 없는지 한 번 더 볼까?']}
];
const CATEGORY_NAMES={aiUsage:'AI 활용',swiftSyntax:'Swift 문법',hig:'HIG',swiftUIPractice:'SwiftUI 실전'};
const $=id=>document.getElementById(id);
const esc=value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const asset=(phase,kind)=>`quiz-process-assets/${phase.id}-${kind}.png`;
const media=matchMedia('(prefers-reduced-motion: reduce)');
let view='compare';
let state=freshState(5);
let transitionTimer;
let transitionToken=0;
let previewTalkingPhase=null;
let previewTalkTimer;
const previewLineIndices=PHASES.map(()=>-1);

function freshState(count){
  return {count,index:0,pick:null,answers:[],feedback:false,hint:false,done:false,banner:false,previousPhase:null,
          thinkingLine:null,thinkingCursors:PHASES.map(()=>-1)};
}
function countsFor(total){
  const base=Math.floor(total/4),remainder=total%4;
  return PHASES.map((_,i)=>base+(i>=4-remainder?1:0));
}
function rangesFor(total){
  let start=0;
  return countsFor(total).map(count=>{const range={start,end:start+count-1,count};start+=count;return range;});
}
function phaseAt(index,total){
  const target=Math.min(Math.max(index,0),total-1);
  return rangesFor(total).findIndex(range=>target>=range.start&&target<=range.end);
}
function currentPhase(){return phaseAt(state.index,state.count);}
function icon(name){
  const paths={close:'M5 5l14 14M19 5L5 19',hint:'M9 18h6M10 21h4M8 13a6 6 0 1 1 8 0l-1 3H9z'};
  return `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="${paths[name]}"/></svg>`;
}
// 작업실 산타의 인상을 기준으로 소원 접수용 두 자세를 만들고, 나머지도 같은 2프레임 형식으로 표시한다.
function spriteInfo(phase){
  return {
    path:phase.id==='wish'
      ?'quiz-process-assets/wish-character-poses-letter.png'
      :`quiz-process-assets/${phase.id}-character-poses-clean.png`,
    columns:2
  };
}
function characterSprite(phase,{className='',talking=false,pose=null,original=false}={}){
  const info=original?{path:'quiz-process-assets/workshop-santa-reference.png',columns:4}:spriteInfo(phase);
  const manual=pose!==null;
  const selectedPose=manual?pose:media.matches?0:talking?1:0;
  const speaking=!manual&&talking&&!media.matches;
  return `<svg class="sprite-svg ${className} ${speaking?'speaking':''}" viewBox="0 0 300 400" preserveAspectRatio="xMidYMax meet" role="img" aria-label="${original?'작업실 산타 원본':phase.character} · ${selectedPose?'대화':'기본'} 자세"><image class="sprite-image" href="${info.path}" width="${info.columns*300}" height="400" style="--sprite-pose:${selectedPose}"/></svg>`;
}
function artWindow(phase,talking=false){
  return `<div class="art-window"><img class="room" src="${asset(phase,'background')}" alt="${phase.place} 픽셀 배경">${characterSprite(phase,{className:'character',talking})}<span class="art-tag">${phase.place} / ${phase.character}</span></div>`;
}
function posePair(phase,index){
  return `<div class="pose-pair" aria-label="${phase.character}의 두 자세 비교"><div>${characterSprite(phase,{pose:0})}<span>A · 기본 자세</span></div><div>${characterSprite(phase,{pose:1})}<span>B · 대화 자세</span></div></div><button class="preview-talk" data-preview-talk="${index}">대사와 두 자세 재생</button>`;
}
function santaIdentityComparison(phase){
  if(phase.id!=='wish')return '';
  return `<details class="identity-comparison"><summary>작업실 산타와 모습 비교</summary><div class="identity-pair"><div>${characterSprite(phase,{pose:0,original:true})}<span>작업실 원본</span></div><div>${characterSprite(phase,{pose:0})}<span>소원 접수</span></div></div></details>`;
}
function processTrack(phaseIndex,finished=false){
  return `<div class="process-track" aria-label="네 작업 과정">${PHASES.map((phase,i)=>{
    const done=finished||i<phaseIndex,current=!finished&&i===phaseIndex;
    return `<div class="process-step ${done?'done':current?'active':''}" ${current?'aria-current="step"':''}><span class="step-number">${done?'✓':String(i+1).padStart(2,'0')}</span>${phase.name}<span class="sr-only">${done?' 완료':current?' 진행 중':' 예정'}</span></div>`;
  }).join('')}</div>`;
}
function scene(phase,preview){
  const previous=!preview&&state.previousPhase!==null&&$('motion-mode').checked&&!media.matches
    ?`<img class="scene-previous" src="${asset(PHASES[state.previousPhase],'background')}" alt="">`:'';
  return `<div class="scene" aria-hidden="true"><img src="${asset(phase,'background')}" alt="">${previous}</div>`;
}
function renderDevice(phaseIndex,preview=false){
  const phase=PHASES[phaseIndex],question=preview?QUESTIONS[0]:QUESTIONS[state.index];
  const graded=!preview&&state.feedback,answer=graded?state.answers[state.index]:null;
  const progress=preview?0:state.answers.length/state.count*100;
  const talking=preview?previewTalkingPhase===phaseIndex:!graded&&state.pick!==null;
  const mood=talking?'thinking':'idle';
  const bubble=preview
    ?(talking?phase.thinkingLines[Math.max(0,previewLineIndices[phaseIndex])]:phase.idle)
    :(state.thinkingLine??phase.idle);
  const inert=graded?'inert':'';
  return `<div class="device" style="--phase:${phase.color}">
    ${scene(phase,preview)}
    <div class="device-header" ${inert}>
      <div class="question-toolbar">
        <button class="round-button" data-action="exit" aria-label="퀴즈 체험 나가기" ${preview?'disabled':''}>${icon('close')}</button>
        <span class="question-number">${preview?'예시 문제':`${state.index+1} / ${state.count}`}</span>
        <button class="round-button" data-action="hint" aria-label="힌트 ${state.hint&&!preview?'닫기':'보기'}" aria-pressed="${!preview&&state.hint}" ${preview||!question.hint?'disabled':''}>${icon('hint')}</button>
      </div>
      <div class="progress-track" role="progressbar" aria-label="문제 풀이 진도" aria-valuemin="0" aria-valuemax="100" aria-valuenow="${Math.floor(progress)}"><span style="width:${progress}%"></span></div>
      ${processTrack(phaseIndex)}
    </div>
    <div class="device-main" ${inert}>
      <div class="metadata"><span class="chip stage">스테이지 1-1</span><span class="chip">쉬움</span><span class="chip">#${CATEGORY_NAMES[question.category]}</span></div>
      <div class="question-card" ${preview?'':'tabindex="-1"'}>${esc(question.text)}</div>
      ${question.codeSnippet?`<button class="code-button" data-action="code" ${preview?'disabled':''}><pre>${esc(question.codeSnippet)}</pre><small>눌러서 코드 크게 보기</small></button>`:''}
      ${!preview&&state.hint&&question.hint?`<div class="hint">${esc(question.hint)}<br><small>힌트를 봐도 점수와 보상은 달라지지 않아요.</small></div>`:''}
      <div class="choices">${question.choices.map((text,i)=>{
        const chosen=!preview&&state.pick===i;
        const style=graded?(i===question.correctIndex?'correct':chosen?'wrong':'dimmed'):chosen?'picked':'';
        return `<button class="choice ${style}" data-choice="${i}" ${preview||graded?'disabled':''} aria-pressed="${chosen}"><span class="letter">${'ABCD'[i]}</span><span class="choice-text">${esc(text)}</span>${graded&&i===question.correctIndex?'<span class="verdict-mark" aria-label="정답">✓</span>':graded&&chosen?'<span class="verdict-mark" aria-label="오답">✕</span>':''}</button>`;
      }).join('')}</div>
    </div>
    <div class="bottom-dock" ${inert}>
      <div class="portrait ${mood}">${characterSprite(phase,{talking})}<span class="character-name">${phase.character}</span></div>
      <div class="bubble">${bubble}</div>
      <button class="confirm" data-action="confirm" ${preview||state.pick===null||graded?'disabled':''}>확인</button>
    </div>
    ${!preview&&state.banner?`<div class="process-banner"><small>NEXT WORKSHOP</small><b>${phase.name}</b> 과정을 시작해요</div>`:''}
    ${graded?renderFeedback(question,answer):''}
  </div>`;
}
function renderFeedback(question,answer){
  const last=state.index===state.count-1;
  return `<div class="feedback-shade" aria-hidden="true"></div><section class="feedback ${answer.correct?'':'wrong'}" role="dialog" aria-modal="true" aria-labelledby="feedback-title"><span class="feedback-badge" aria-hidden="true">${answer.correct?'✓':'✕'}</span><h3 id="feedback-title" tabindex="-1">${answer.correct?'정답이에요!':'아쉬워요'}</h3>${answer.correct?'':`<p class="correct-answer">정답 · ${'ABCD'[question.correctIndex]}. ${esc(question.choices[question.correctIndex])}</p>`}<div class="explanation"><p>${esc(question.explanation)}</p></div><button class="confirm" data-action="next">${last?'결과 보기':'다음 문제'}</button></section>`;
}
function renderResult(){
  const correct=state.answers.filter(answer=>answer.correct).length;
  const score=Math.floor(correct/state.count*100),passed=score>=80,phase=PHASES[3];
  return `<div class="device" style="--phase:${phase.color}">${scene(phase,false)}<div class="device-header"><div class="question-toolbar"><span class="question-number">세션 결과</span><button class="round-button" data-action="exit" aria-label="결과 닫기">${icon('close')}</button></div><div class="progress-track"><span style="width:100%"></span></div>${processTrack(3,true)}</div><div class="result-content ${passed?'':'failed'}"><div class="result-orb" aria-hidden="true"></div><h3>${passed?'장식 기준을 통과했어요!':'이번에는 기준에 못 미쳤어요'}</h3><p>소원 접수부터 썰매 적재까지 한 판을 마쳤어요.</p><div class="score">${score}<span style="font-size:19px">%</span></div><p>${state.count}문제 중 ${correct}문제 정답 · 기준 80%</p><div class="result-stats">네 작업 과정은 문항 진행에 따라 모두 지나갑니다.<br>보상 통과 여부는 세션 전체의 정답률로 판단합니다.</div><button class="confirm" data-action="restart">다시 체험하기</button><p class="result-notice">실제 장식 지급·세션 저장·스테이지 해금은 하지 않습니다.</p></div></div>`;
}
function renderComparison(){
  $('comparison-grid').innerHTML=PHASES.map((phase,i)=>`<article class="concept"><div class="concept-title"><span class="index">0${i+1}</span><div><strong>${phase.name}</strong><small>${phase.place} · ${phase.character}</small></div></div>${artWindow(phase,previewTalkingPhase===i)}${posePair(phase,i)}${santaIdentityComparison(phase)}${renderDevice(i,true)}<p class="concept-note">${phase.caption}${phase.id==='wish'?'<br>작업실 산타의 인상과 복장을 기준으로 편지를 든 두 자세를 만들었습니다.':''}</p></article>`).join('');
}
function renderLive(){
  const phaseIndex=currentPhase(),phase=PHASES[phaseIndex];
  $('live-device').innerHTML=state.done?renderResult():renderDevice(phaseIndex);
  $('count-controls').innerHTML=[5,10,15].map(count=>`<button data-count="${count}" aria-pressed="${state.count===count}">${count}문제</button>`).join('');
  $('allocation').innerHTML=rangesFor(state.count).map((range,i)=>`<div class="${phaseIndex===i?'active':''}">${PHASES[i].name}<b>${range.start+1}${range.count===1?'':`~${range.end+1}`}번</b></div>`).join('');
  $('live-phase-code').textContent=`PROCESS 0${phaseIndex+1} / 04`;
  $('environment-live').innerHTML=artWindow(phase,!state.done&&!state.feedback&&state.pick!==null);
  $('phase-story').innerHTML=`<div class="phase-story"><h3>${phase.place}</h3><p>${phase.caption}</p><p>담당 캐릭터 · ${phase.character}<br>현재 과정 · ${rangesFor(state.count)[phaseIndex].start+1}~${rangesFor(state.count)[phaseIndex].end+1}번</p></div>`;
}
function clearTransition(){
  clearTimeout(transitionTimer);transitionToken+=1;state.banner=false;state.previousPhase=null;
}
function setView(next){
  view=next;$('compare').hidden=view!=='compare';$('experience').hidden=view!=='experience';
  document.querySelectorAll('[data-view]').forEach(button=>button.setAttribute('aria-pressed',String(button.dataset.view===view)));
}
function restart(count=state.count){
  clearTransition();state=freshState(count);renderLive();$('announcement').textContent=`${count}문제 체험을 소원 접수부터 다시 시작합니다.`;
}
function choose(index){
  if(state.feedback||state.done||state.pick===index)return;
  const phaseIndex=currentPhase(),lines=PHASES[phaseIndex].thinkingLines;
  state.thinkingCursors[phaseIndex]=(state.thinkingCursors[phaseIndex]+1)%lines.length;
  state.thinkingLine=lines[state.thinkingCursors[phaseIndex]];
  state.pick=index;renderLive();
  $('announcement').textContent=`${PHASES[phaseIndex].character}: ${state.thinkingLine}`;
  $('live-device').querySelector(`[data-choice="${index}"]`)?.focus({preventScroll:true});
}
function confirm(){
  if(state.pick===null||state.feedback||state.done)return;
  const question=QUESTIONS[state.index];
  state.answers.push({pick:state.pick,correct:state.pick===question.correctIndex});
  state.feedback=true;state.hint=false;renderLive();
  $('live-device').querySelector('#feedback-title')?.focus({preventScroll:true});
}
function advance(){
  if(!state.feedback||state.done)return;
  const oldPhase=currentPhase();clearTransition();state.feedback=false;
  if(state.index===state.count-1){state.done=true;renderLive();$('announcement').textContent='퀴즈 체험을 마쳤습니다.';return;}
  state.index+=1;state.pick=null;state.thinkingLine=null;
  const nextPhase=currentPhase();
  if(nextPhase!==oldPhase){state.banner=true;state.previousPhase=oldPhase;}
  renderLive();$('live-device').querySelector('.question-card')?.focus({preventScroll:true});
  if(state.banner){
    $('announcement').textContent=`${PHASES[nextPhase].name} 과정을 시작합니다.`;
    const token=transitionToken;
    transitionTimer=setTimeout(()=>{
      if(token!==transitionToken)return;
      state.banner=false;state.previousPhase=null;
      $('live-device').querySelector('.process-banner')?.remove();
      $('live-device').querySelector('.scene-previous')?.remove();
    },1200);
  }
}
function syncMotion(){
  $('motion-mode').disabled=media.matches;
  document.body.classList.toggle('motion',$('motion-mode').checked&&!media.matches);
  if(media.matches){$('live-device').querySelector('.scene-previous')?.remove();}
}
media.addEventListener('change',()=>{if(media.matches)$('motion-mode').checked=false;syncMotion();renderComparison();renderLive();});
$('motion-mode').checked=!media.matches;
$('motion-mode').addEventListener('change',()=>{syncMotion();if(!$('motion-mode').checked)$('live-device').querySelector('.scene-previous')?.remove();});
$('dark-mode').addEventListener('change',event=>document.body.classList.toggle('dark',event.target.checked));
$('large-type').addEventListener('change',event=>document.body.classList.toggle('big-type',event.target.checked));
$('restart').addEventListener('click',()=>restart());
$('close-code').addEventListener('click',()=>$('code-dialog').close());
$('continue-quiz').addEventListener('click',()=>$('exit-dialog').close());
$('pause-quiz').addEventListener('click',()=>{$('exit-dialog').close();setView('compare');});
$('copy-direction').addEventListener('click',async()=>{
  const text='퀴즈 과정 시안: 소원 접수 → 선물 생산 → 포장 → 썰매 적재\n담당 캐릭터: 작업실 산타 기반의 소원 접수 산타 / 생산 엘프 / 포장 엘프 / 루돌프\n각 캐릭터는 기본·대화 두 자세를 교대\n기존 문제 배치 유지, 과정별 배경·캐릭터·진행 표시 변경\n문항 배분: 5개 1·1·1·2 / 10개 2·2·3·3 / 15개 3·4·4·4\n과정 경계에서 1.2초 안내, 추가 확인 버튼 없음';
  try{await navigator.clipboard.writeText(text);$('copy-status').textContent='복사했어요. 대화에 붙여 넣어 주세요.';}
  catch{$('copy-status').textContent=text;}
});
document.addEventListener('click',event=>{
  const button=event.target.closest('button');if(!button||button.disabled)return;
  if(button.dataset.previewTalk!==undefined){
    clearTimeout(previewTalkTimer);
    previewTalkingPhase=Number(button.dataset.previewTalk);
    const lines=PHASES[previewTalkingPhase].thinkingLines;
    previewLineIndices[previewTalkingPhase]=(previewLineIndices[previewTalkingPhase]+1)%lines.length;
    renderComparison();
    document.querySelector(`[data-preview-talk="${previewTalkingPhase}"]`)?.focus({preventScroll:true});
    previewTalkTimer=setTimeout(()=>{
      const focusedPreview=document.activeElement?.dataset.previewTalk;
      previewTalkingPhase=null;renderComparison();
      if(focusedPreview!==undefined)document.querySelector(`[data-preview-talk="${focusedPreview}"]`)?.focus({preventScroll:true});
    },1800);
    return;
  }
  if(button.dataset.view){setView(button.dataset.view);return;}
  if(button.dataset.count){restart(Number(button.dataset.count));return;}
  if(button.dataset.choice!==undefined){choose(Number(button.dataset.choice));return;}
  switch(button.dataset.action){
    case 'confirm':confirm();break;
    case 'next':advance();break;
    case 'restart':restart();break;
    case 'hint':if(!state.feedback&&!state.done){state.hint=!state.hint;renderLive();$('live-device').querySelector('[data-action="hint"]')?.focus({preventScroll:true});}break;
    case 'code':$('expanded-code').textContent=QUESTIONS[state.index].codeSnippet||'';$('code-dialog').showModal();break;
    case 'exit':$('exit-dialog').showModal();break;
  }
});
document.addEventListener('keydown',event=>{
  if(view==='experience'&&state.feedback&&event.key==='Tab'){
    event.preventDefault();$('live-device').querySelector('.feedback [data-action="next"]')?.focus();
  }
});
syncMotion();renderComparison();renderLive();setView('compare');
