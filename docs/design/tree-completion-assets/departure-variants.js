'use strict';

// 선택한 D안의 공통 도입부를 유지하고 썰매의 모습·비행·배달 장면을 비교한다.
window.completionConcepts = [
  {id:'D1',title:'마을 위를 가로질러',subtitle:'손을 흔드는 산타와 루돌프 한 마리의 또렷한 옆모습',duration:10,feel:'따뜻한 출발 인사와 선명한 비행',
   speech:'호호호! 크리스마스 선물을 전하러 출발하자!',
   caption:'크리스마스 선물 배달, 출발!',ending:'기다리는 모두에게 선물을 전하러 가요',
   beats:[[0,'마지막 장식'],[1,'별에 모인 빛'],[2,'출발 인사'],[3.2,'산타 마을'],[4.4,'썰매 비행'],[8.8,'배달 출발']],
   flight:{kind:'cruise',sprite:'tree-completion-assets/sleigh-side.png',start:4.4,end:8.6}},
  {id:'D2',title:'지붕 따라 선물 배달',subtitle:'두 마리 순록의 행렬과 지붕으로 내려가는 작은 선물',duration:11.5,feel:'배달하는 모습까지 보이는 경쾌한 이야기',
   speech:'루돌프, 준비됐지? 선물을 기다리는 친구들에게 가자!',
   caption:'마을 곳곳에 크리스마스의 기쁨을!',ending:'정성껏 준비한 선물이 하나씩 도착해요',
   beats:[[0,'마지막 장식'],[1,'별에 모인 빛'],[2,'출발 인사'],[3.2,'산타 마을'],[4.4,'선물 배달'],[10,'행복한 마을']],
   flight:{kind:'delivery',sprite:'tree-completion-assets/sleigh-parade.png',start:4.4,end:9.9}},
  {id:'D3',title:'하늘 멀리 출발',subtitle:'뒷모습의 썰매가 별빛을 남기며 작아지는 장면',duration:11,feel:'멀어지는 뒷모습으로 여운을 남기는 마무리',
   speech:'모두의 크리스마스를 밝히러, 하늘로 출발!',
   caption:'메리 크리스마스! 선물을 전하러!',ending:'우리의 다음 크리스마스도 기대해 주세요',
   beats:[[0,'마지막 장식'],[1,'별에 모인 빛'],[2,'출발 인사'],[3.2,'산타 마을'],[4.4,'하늘로 비상'],[9.6,'크리스마스 인사']],
   flight:{kind:'ascend',sprite:'tree-completion-assets/sleigh-departure.png',start:4.4,end:9.4}}
];
