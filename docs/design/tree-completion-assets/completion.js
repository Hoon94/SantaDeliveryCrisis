'use strict';

// 디자인 시안 전용. 앱의 세션·보상·트리 저장소에는 접근하지 않는다.
const $ = id => document.getElementById(id);
const media = matchMedia('(prefers-reduced-motion: reduce)');
const room = mode => 'ornament-set-assets/pixel-workshop-room-' + mode + '.png';
const village = mode => 'quiz-stage-assets/santa-village-map-' + mode + '.png';
const colors = ['#df5569','#f0b14d','#56ad86','#63a4e4'];
const positions = [[110,62],[98,92],[122,92],[88,120],[110,120],[132,120],[80,148],[110,148],[140,148],[70,176],[110,176],[150,176]].map(point => [point[0]/220+.11, point[1]/214*.9-.045]);
const concepts = window.completionConcepts || [
  {id:'A',title:'별빛 점등',subtitle:'작은 불빛이 모여 만드는 차분한 완성',duration:3.8,feel:'고요하고 따뜻한 성취감',
   speech:'호호호, 정말 멋진 트리구나!',ending:'열두 개의 빛이 하나가 됐어요',beats:[[0,'마지막 장식'],[.8,'아래부터 점등'],[2,'꼭대기 별'],[2.8,'완성 인사']]},
  {id:'B',title:'선물 축제',subtitle:'황금빛 리본과 작은 선물이 터지는 축하',duration:4.6,feel:'밝고 경쾌한 게임 보상',
   speech:'모두 모았어! 함께 축하하자!',ending:'올해의 첫 번째 트리, 완성!',beats:[[0,'장식 도착'],[.9,'트리 반짝임'],[1.7,'축하 리본'],[3.4,'완성 배지']]},
  {id:'C',title:'산타의 출발',subtitle:'선물 준비를 마치고 창밖으로 이어지는 이야기',duration:5.4,feel:'퀴즈의 작업 과정을 마무리하는 이야기',
   speech:'선물 준비 완료! 이제 출발하자!',ending:'다음 겨울의 소원도 함께 모아요',beats:[[0,'장식 도착'],[1,'트리 점등'],[1.9,'산타의 인사'],[3,'썰매 출발']]},
  {id:'D',title:'마을에 전해진 빛',subtitle:'트리의 빛을 싣고 산타와 루돌프가 선물 배달을 떠나요',duration:10,feel:'작업실과 스테이지 지도가 이어지는 크리스마스 출발',
   speech:'호호호! 크리스마스 선물을 전하러 출발하자!',caption:'크리스마스 선물 배달, 출발!',
   ending:'기다리는 모두에게 선물을 전하러 가요',beats:[[0,'마지막 장식'],[1,'별에 모인 빛'],[2,'출발 인사'],[3.2,'산타 마을'],[4.4,'썰매 비행'],[8.8,'배달 출발']],
   flight:{kind:'cruise',sprite:'tree-completion-assets/sleigh-side.png',start:4.4,end:8.6}}
];
const isVillage = concept => concept.id==='D' || Boolean(concept.flight);
const sleighSVG = '<svg class="sleigh" viewBox="0 0 180 64" aria-hidden="true"><g fill="currentColor"><path d="M5 27h7v10h34V23h7v23H13v5h38v-4h6v8H7v-9H2v-6h6z"/><path d="M15 13h22v18H15zM20 5h12v8H20zM8 22h36v6H8z"/><path d="M97 22h26v12H97zM116 14h8v16h-8zM121 9h9v8h-9zM98 31h5v18h-5zM115 31h5v13h-5zM91 19h8v7h-8zM121 2h3v8h-3zM127 1h3v10h-3zM132 5h3v8h-6z"/><path d="M147 16h24v12h-24zM165 8h7v17h-7zM169 4h9v8h-9zM148 26h5v17h-5zM163 26h5v14h-5zM142 14h6v8h-6zM170 0h3v6h-3zM177 0h3v8h-3z"/></g><path d="M53 36L99 25M123 24L147 20" stroke="currentColor" stroke-width="2" fill="none"/></svg>';
let states = [];
let selected = null;
let raf = null;
let lastFrame = null;

function cardHTML(concept,index) {
  const aerial = concept.flight ? '<div class="world-flight"><canvas class="flight-fx" width="640" height="640" aria-hidden="true"></canvas><img class="flying-team" src="' + concept.flight.sprite + '" alt="산타와 루돌프의 선물 배달 썰매"></div>' : '';
  const ornaments = positions.map((p,i) => '<i class="ornament" style="left:' + p[0]*100 + '%;top:' + p[1]*100 + '%;--orb:' + colors[i%4] + '"></i>').join('');
  const dots = Array.from({length:30},(_,i) => {
    const y=.19+(i/29)*.56;
    const spread=.06+(y-.19)*.55;
    const x=.607+Math.sin(i*2.399)*spread;
    return '<i class="light-dot" style="left:' + x*100 + '%;top:' + y*100 + '%"></i>';
  }).join('');
  return '<header class="card-head"><span class="letter">' + concept.id + '</span><div class="card-heading"><h2>' + concept.title + '</h2><p>' + concept.subtitle + '</p></div><span class="duration">' + concept.duration.toFixed(1) + ' SEC</span></header>' +
    '<div class="scene" role="group" aria-label="' + concept.title + ' 연출 시안"><img class="room-image" src="' + room('dark') + '" alt=""><div class="room-light"></div>' + ornaments + dots +
    '<div class="star-glow"></div><div class="star-flare"></div><div class="santa"></div><div class="speech">' + concept.speech + '</div>' +
    '<div class="window-flight">' + sleighSVG + '</div><div class="world-reveal"><img class="world-image" src="' + village('dark') + '" alt="">' + aerial + '<div class="world-caption">' + (concept.caption || '크리스마스 선물 배달, 출발!') + '</div></div>' +
    '<canvas class="fx" width="640" height="640" aria-hidden="true"></canvas><span class="hud">11 / 12</span>' +
    '<div class="finish"><small>TREE COMPLETE · 01</small><strong>트리가 완성됐어요!</strong><span>' + concept.ending + '</span><button data-new="' + index + '">새 트리 미리 보기</button></div><div class="new-tree-note" hidden>다음 소원을 기다리는 새 트리 · 0 / 12</div></div>' +
    '<div class="card-body"><div class="time-row"><button class="play-button" data-play="' + index + '">재생</button><input class="scrubber" data-scrub="' + index + '" aria-label="' + concept.title + ' 재생 시점" type="range" min="0" max="' + concept.duration + '" step=".01" value="0"><output class="clock" aria-live="off">0.0 / ' + concept.duration.toFixed(1) + '</output></div>' +
    '<p class="phase">11개를 모았어요. 마지막 장식을 기다리는 중</p><ol class="beats">' + concept.beats.map(beat => '<li>' + beat[1] + '</li>').join('') +
    '</ol><div class="card-bottom"><span class="feel">' + concept.feel + '</span><button class="pick" data-pick="' + index + '" aria-pressed="false">이 안 선택</button></div></div>';
}

concepts.forEach((concept,index) => {
  const card=document.createElement('article');
  card.className='concept-card';
  card.innerHTML=cardHTML(concept,index);
  $('concepts').append(card);
  states.push({concept,card,time:0,running:false,newTree:false,
    ornaments:[...card.querySelectorAll('.ornament')],dots:[...card.querySelectorAll('.light-dot')],
    ctx:card.querySelector('.fx').getContext('2d'),flightCtx:card.querySelector('.flight-fx')?.getContext('2d')});
});

const clamp = x => Math.max(0,Math.min(1,x));
const smooth = x => {const v=clamp(x);return v*v*(3-2*v);};
const reduced = () => media.matches || $('reduced').checked;
const opacity = (state,selector,value) => {const el=state.card.querySelector(selector);el.style.opacity=String(value);el.setAttribute('aria-hidden',String(value<.05));};

function draw(state) {
  const {concept,card}=state;
  const t=state.time;
  const still=reduced();
  const arrived=t>=.65 && !state.newTree;
  const energy=smooth((t-.85)/1.5);
  state.ornaments.forEach((el,i) => {
    if(state.newTree){el.style.opacity='0';return;}
    const landing=i===11?smooth(t/.65):1;
    const travel=i===11 && !still ? (1-landing) : 0;
    el.style.opacity=String(i===11?landing:1);
    el.style.transform='translate(calc(-50% + ' + travel*90 + 'px),calc(-50% - ' + travel*80 + 'px)) scale(' + (i===11 ? .4+.6*landing : 1) + ')';
    const on=smooth((t-.85-(11-i)*.055)/.28);
    el.style.filter='brightness(' + (1+on*.22) + ')';
    el.style.boxShadow='0 0 ' + (on*14) + 'px ' + colors[i%4] + ',0 2px 0 #172b3270';
  });
  state.dots.forEach((el,i) => {
    const on=state.newTree?0:smooth((t-.9-(29-i)*.025)/.22);
    el.style.opacity=String(on*(still ? .8 : .72+.28*Math.sin(t*2+i)));
    el.style.filter='drop-shadow(0 0 4px #ffe3a3)';
  });
  const star=state.newTree?0:smooth((t-1.9)/.55);
  opacity(state,'.room-light',state.newTree?0:energy*(concept.id==='B' ? .85 : .55));
  opacity(state,'.star-glow',star);
  opacity(state,'.star-flare',star*(still ? .65 : .7+.3*Math.sin(t*3)));
  card.querySelector('.star-flare').style.transform='translate(-50%,-50%) scale(' + (still?1:.8+.25*Math.sin(t*2.2)) + ')';
  const santa=card.querySelector('.santa');
  let pose=0;
  if(!still && t>1.9 && !state.newTree){
    pose=concept.id==='B'?(Math.floor((t-1.9)*3)%2?2:3):(Math.floor((t-1.9)*2)%2?1:2);
  }
  santa.style.backgroundPosition=(pose/3*100)+'% 0';
  const santaExit=concept.id==='C' && !still?smooth((t-2.9)/.65):0;
  santa.style.opacity=String(1-santaExit);
  santa.style.transform='translateX(' + -santaExit*40 + '%)';
  const speech=state.newTree?0:smooth((t-2)/.35)*(concept.id==='C'?1-smooth((t-2.95)/.35):1);
  opacity(state,'.speech',speech);
  const flight=card.querySelector('.sleigh');
  const flying=concept.id==='C' && !still && t>=3 && t<4.65;
  flight.style.opacity=flying?'1':'0';
  flight.style.transform='translateX(' + (-110+clamp((t-3)/1.65)*240) + '%)';
  const world=isVillage(concept) && !state.newTree?smooth((t-3.15)/1):0;
  opacity(state,'.world-reveal',world);
  if(isVillage(concept))opacity(state,'.speech',speech*(1-world));
  card.querySelector('.world-image').style.left=(-35-(still?0:clamp((t-3.15)/2.5)*25))+'%';
  drawWorldFlight(state,still,world);
  const done=state.newTree?0:smooth((t-(concept.duration-.8))/.5);
  opacity(state,'.finish',done);
  card.querySelector('.finish').style.pointerEvents=done>.9?'auto':'none';
  card.querySelector('.finish button').disabled=done<.9;
  card.querySelector('.new-tree-note').hidden=!state.newTree;
  card.querySelector('.hud').textContent=state.newTree?'0 / 12':arrived?'12 / 12':'11 / 12';
  card.querySelector('.clock').textContent=t.toFixed(1)+' / '+concept.duration.toFixed(1);
  card.querySelector('.scrubber').value=String(t);
  const phase=concept.beats.reduce((value,beat,index)=>t>=beat[0]?index:value,-1);
  card.querySelectorAll('.beats li').forEach((el,i)=>el.classList.toggle('active',i<=phase && !state.newTree && t>0));
  card.querySelector('.phase').textContent=state.newTree?'새 트리 장면 · 다시 재생하면 완성 연출로 돌아갑니다':t===0?'11개를 모았어요. 마지막 장식을 기다리는 중':t>=concept.duration?'완성된 트리를 감상하는 장면':concept.beats[Math.max(0,phase)][1];
  card.querySelector('.play-button').textContent=state.running?'일시정지':t>=concept.duration || state.newTree?'다시 재생':t>0?'이어서 재생':'재생';
  drawEffects(state,still);
}

function pixelStar(ctx,x,y,r,alpha) {
  ctx.fillStyle='rgba(255,239,174,'+alpha+')';
  ctx.fillRect(x-r/5,y-r,r*2/5,r*2);
  ctx.fillRect(x-r,y-r/5,r*2,r*2/5);
}

function drawEffects(state,still) {
  const {ctx,concept,time:t}=state;
  ctx.clearRect(0,0,640,640);
  if(still || state.newTree)return;
  // 완료 순간의 입자는 작은 픽셀 도형으로만 그린다.
  if(concept.id==='A'){
    const p=clamp((t-1.1)/1.5);
    if(p>0 && p<1)for(let i=0;i<18;i++){
      const y=(.78-p*.62)*640;
      const x=389+Math.sin(i*2.4)*(.05+(1-p)*.2)*640;
      pixelStar(ctx,x,y+Math.sin(i*4)*16,4,Math.sin(p*Math.PI));
    }
  }
  if(concept.id==='B'){
    const age=t-1.7;
    if(age>0 && age<2.5)for(let i=0;i<60;i++){
      const angle=i*2.399, speed=70+(i%7)*25;
      const x=389+Math.cos(angle)*speed*age;
      const y=245+Math.sin(angle)*speed*age+90*age*age;
      ctx.save();ctx.globalAlpha=clamp((2.5-age)/.7);ctx.translate(x,y);ctx.rotate(i+age*3);
      ctx.fillStyle=['#f5cf70','#dc6260','#70b9aa','#fff1bb'][i%4];
      ctx.fillRect(-3,-3,i%3===0?11:5,i%3===0?4:8);ctx.restore();
    }
    if(t>1.7 && t<2.5){
      const p=(t-1.7)/.8;
      ctx.strokeStyle='rgba(255,225,139,'+(1-p)*.8+')';ctx.lineWidth=3;
      ctx.beginPath();ctx.arc(389,245,20+p*210,0,Math.PI*2);ctx.stroke();
    }
  }
  if(concept.id==='C' && t>3 && t<4.8){
    const p=clamp((t-3)/1.65);
    for(let i=0;i<8;i++){
      const x=(p*.3-i*.015)*640;
      if(x>0 && x<.242*640)pixelStar(ctx,x,.22*640+Math.sin(i)*3,2,Math.max(0,.8-i*.1));
    }
  }
  if(isVillage(concept)){
    const age=t-2.3;
    if(age>0 && age<1.7){
      const p=age/1.7;
      ctx.strokeStyle='rgba(255,224,139,'+(1-p)*.75+')';ctx.lineWidth=5*(1-p)+1;
      ctx.beginPath();ctx.arc(389,33,p*730,0,Math.PI*2);ctx.stroke();
      for(let i=0;i<24;i++){const a=i/24*Math.PI*2;pixelStar(ctx,389+Math.cos(a)*p*730,33+Math.sin(a)*p*730,3,(1-p)*.8);}
    }
  }
}

// 궤적은 시간의 함수라 시간 막대에서 어느 순간을 골라도 같은 장면을 볼 수 있다.
function flightPoint(kind,p) {
  if(kind==='delivery')return {x:-.3+1.6*p,y:.27+.1*Math.sin(p*Math.PI*2),width:.66,angle:Math.cos(p*Math.PI*2)*5};
  if(kind==='ascend')return {x:.05+.97*p,y:.57-.68*Math.sin(p*Math.PI/2),width:.78*(1-.92*smooth(p)),angle:-4};
  return {x:-.38+1.76*p,y:.31-.1*p+.016*Math.sin(p*Math.PI*2),width:.59,angle:-3};
}

function drawWorldFlight(state,still,world) {
  const flight=state.concept.flight;
  if(!flight)return;
  const ctx=state.flightCtx;
  const layer=state.card.querySelector('.world-flight');
  const team=state.card.querySelector('.flying-team');
  const t=state.time;
  const p=clamp((t-flight.start)/(flight.end-flight.start));
  const visible=!state.newTree && (still?world>.5:t>=flight.start && t<=flight.end);
  ctx.clearRect(0,0,640,640);
  layer.style.opacity=visible?'1':'0';
  layer.setAttribute('aria-hidden',String(!visible));
  const point=still?{x:.53,y:.32,width:flight.kind==='ascend' ? .5 : .64,angle:0}:flightPoint(flight.kind,p);
  team.style.left=point.x*100+'%';
  team.style.top=point.y*100+'%';
  team.style.width=point.width*100+'%';
  team.style.transform='translate(-50%,-50%) rotate('+point.angle+'deg)';
  team.style.opacity=String(still?1:smooth(p/.08)*(1-smooth((p-.94)/.06)));
  const caption=state.card.querySelector('.world-caption');
  caption.style.opacity=String(still?1:smooth((t-flight.end+.1)/.55));
  caption.setAttribute('aria-hidden',String(!still && t<flight.end-.1));
  if(!visible || still)return;

  // 별빛 자취는 이미지에 넣지 않고 비행 위치를 따라 별도로 그린다.
  for(let i=1;i<25;i++){
    const before=p-i*.012;
    if(before<0)continue;
    const here=flightPoint(flight.kind,before);
    const next=flightPoint(flight.kind,Math.min(p,before+.012));
    const alpha=(1-i/25)*.75;
    const x=(here.x-here.width*.39)*640, y=(here.y+here.width*.09)*640;
    ctx.strokeStyle='rgba(255,224,143,'+alpha+')';ctx.lineWidth=Math.max(1,4*(1-i/25));
    ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo((next.x-next.width*.39)*640,(next.y+next.width*.09)*640);ctx.stroke();
    if(i%3===0)pixelStar(ctx,x,y+Math.sin(i*2.4)*8,2.5,alpha);
  }
  if(flight.kind==='delivery'){
    [{at:.34,x:.24,y:.7},{at:.63,x:.78,y:.68}].forEach((drop,i)=>{
      const progress=(p-drop.at)/.17;
      if(progress<0 || progress>1.65)return;
      const origin=flightPoint('delivery',drop.at);
      if(progress<=1){
        const u=smooth(progress),x=(origin.x-origin.width*.25)*(1-u)+drop.x*u,y=origin.y*(1-u)+drop.y*u;
        ctx.save();ctx.translate(x*640,y*640);ctx.rotate(progress*.5);
        ctx.fillStyle=i?'#56ad86':'#dc5c64';ctx.fillRect(-7,-7,14,14);
        ctx.fillStyle='#ffe4a1';ctx.fillRect(-1.5,-7,3,14);ctx.fillRect(-7,-2,14,3);ctx.restore();
        pixelStar(ctx,x*640-3,y*640-16,2,.6);
      }else{
        const glow=(progress-1)/.65;
        ctx.strokeStyle='rgba(255,230,163,'+(1-glow)*.9+')';ctx.lineWidth=2;
        ctx.beginPath();ctx.arc(drop.x*640,drop.y*640,6+glow*24,0,Math.PI*2);ctx.stroke();
        pixelStar(ctx,drop.x*640,drop.y*640,5*(1-glow),1-glow);
      }
    });
  }
}

function start(index) {
  const state=states[index];
  state.newTree=false;
  if(state.time>=state.concept.duration)state.time=0;
  if(reduced()){
    state.time=state.concept.duration;state.running=false;draw(state);
    $('status').textContent='동작 줄이기: 이동·입자 없이 완성 장면을 표시했습니다.';
  }else{state.running=true;draw(state);schedule();}
}
function schedule() {if(raf===null){lastFrame=performance.now();raf=requestAnimationFrame(tick);}}
function tick(now) {
  const delta=Math.min((now-lastFrame)/1000,.08)*Number($('speed').value);
  lastFrame=now;
  states.forEach(state=>{
    if(!state.running)return;
    state.time=Math.min(state.concept.duration,state.time+delta);
    if(state.time>=state.concept.duration)state.running=false;
    draw(state);
  });
  if(states.some(state=>state.running)){raf=requestAnimationFrame(tick);}
  else{raf=null;$('status').textContent='재생이 끝났어요. 시간 막대를 움직이거나 마음에 드는 안을 선택해 주세요.';}
}
function pauseAll() {
  states.forEach(state=>{state.running=false;draw(state);});
  if(raf!==null)cancelAnimationFrame(raf);
  raf=null;lastFrame=null;
}
function resetAll() {pauseAll();states.forEach(state=>{state.time=0;state.newTree=false;draw(state);});$('status').textContent='모든 연출을 마지막 장식 도착 전으로 되돌렸어요.';}
function syncMode() {
  const mode=$('dark').checked?'dark':'light';
  document.body.classList.toggle('dark',mode==='dark');
  states.forEach(state=>{state.card.querySelector('.room-image').src=room(mode);state.card.querySelector('.world-image').src=village(mode);});
}
function syncReduced() {
  if(media.matches)$('reduced').checked=true;
  pauseAll();
  states.forEach(state=>{if(reduced() && state.time>0)state.time=state.concept.duration;draw(state);});
}

$('play-all').addEventListener('click',()=>{resetAll();states.forEach((_,i)=>start(i));$('status').textContent=reduced()?'동작 줄이기: '+concepts.length+'가지 완성 장면을 표시했습니다.':concepts.length+'가지 연출을 함께 재생하고 있어요.';});
$('pause-all').addEventListener('click',()=>{pauseAll();$('status').textContent='원하는 시점에서 일시정지했어요.';});
$('reset-all').addEventListener('click',resetAll);
$('dark').addEventListener('change',syncMode);
$('reduced').addEventListener('change',syncReduced);
media.addEventListener('change',syncReduced);
document.addEventListener('visibilitychange',()=>{if(document.hidden)pauseAll();});
document.addEventListener('click',event=>{
  const play=event.target.closest('[data-play]'),pick=event.target.closest('[data-pick]'),next=event.target.closest('[data-new]');
  if(play){
    const index=Number(play.dataset.play),state=states[index];
    if(state.running){state.running=false;draw(state);}else start(index);
  }else if(pick){
    selected=Number(pick.dataset.pick);
    states.forEach((state,i)=>{state.card.classList.toggle('chosen',i===selected);state.card.querySelector('.pick').setAttribute('aria-pressed',String(i===selected));state.card.querySelector('.pick').textContent=i===selected?'선택한 안':'이 안 선택';});
    const concept=concepts[selected];
    $('selection-title').textContent=concept.id+' · '+concept.title;
    $('selection-description').textContent=concept.feel+' / '+concept.duration+'초 / '+concept.beats.map(beat=>beat[1]).join(' → ');
    $('copy').disabled=false;
    $('status').textContent=concept.id+'안 ‘'+concept.title+'’을 선택했어요.';
  }else if(next){
    const state=states[Number(next.dataset.new)];
    state.running=false;state.newTree=true;draw(state);
  }
});
document.addEventListener('input',event=>{
  if(event.target.dataset.scrub===undefined)return;
  const state=states[Number(event.target.dataset.scrub)];
  state.running=false;state.newTree=false;state.time=Number(event.target.value);draw(state);
});
$('copy').addEventListener('click',async()=>{
  if(selected===null)return;
  const concept=concepts[selected];
  const text='트리 완성 연출 선택: '+concept.id+' · '+concept.title+'\n분위기: '+concept.feel+'\n길이: 약 '+concept.duration+'초\n진행: '+concept.beats.map(beat=>beat[1]).join(' → ')+'\n산타 대사: '+concept.speech+(concept.caption?'\n마무리 문구: '+concept.caption:'')+(concept.flight?'\n썰매 이미지: '+concept.flight.sprite:'')+'\n라이트·다크 배경 대응 / 동작 줄이기에서 완성 장면 표시';
  try{await navigator.clipboard.writeText(text);$('status').textContent='선택 내용을 복사했어요. 대화에 붙여 넣어 주세요.';}
  catch{$('status').textContent=text;}
});
if(media.matches)$('reduced').checked=true;
syncMode();
states.forEach(draw);
