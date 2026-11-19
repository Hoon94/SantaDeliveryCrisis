#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// 장식 획득 연출에 쓰는 GPU 효과.
// SwiftUI의 `ShaderLibrary`에서 이름으로 불러 `.layerEffect` / `.colorEffect`에 붙인다.
// 모든 길이 값은 뷰 좌표계의 포인트가 아니라 효과가 그려지는 픽셀 좌표(`position`)와 같은 단위다.

/// 충격파. 중심에서 퍼지는 고리를 따라 화면을 밀어내고, 고리 근처에서 R/G/B를 다른 거리에서 읽어 색 번짐(색수차)을 만든다.
/// - Parameters:
///   - center: 충격파 중심
///   - radius: 지금 고리의 반지름
///   - width: 고리 두께
///   - amplitude: 화면을 미는 최대 거리
///   - aberration: 색 번짐 거리
[[ stitchable ]] half4 shockwave(
    float2 position,
    SwiftUI::Layer layer,
    float2 center,
    float radius,
    float width,
    float amplitude,
    float aberration
) {
    float2 delta = position - center;
    float dist = max(length(delta), 0.001);
    float2 dir = delta / dist;

    // 고리 중심에서 1, 멀어질수록 0으로 가는 종 모양 가중치
    float x = (dist - radius) / max(width, 1.0);
    float ring = exp(-x * x * 2.2);
    // 고리 안쪽은 당기고 바깥쪽은 밀어서 물결처럼 보이게 한다.
    float push = ring * amplitude * sin(x * 2.6);

    float2 base = position - dir * push;
    float2 fringe = dir * aberration * ring;

    half4 r = layer.sample(base - fringe);
    half4 g = layer.sample(base);
    half4 b = layer.sample(base + fringe);
    return half4(r.r, g.g, b.b, max(max(r.a, g.a), b.a));
}

/// 후광. 중심에서 뻗어 나가며 천천히 도는 빛줄기.
/// 색과 투명도만 계산하므로 아무 도형 위에 `.colorEffect`로 붙인다.
/// - Parameters:
///   - center: 빛의 중심
///   - time: 회전용 시간(초)
///   - intensity: 전체 밝기 0...1
///   - reach: 빛이 닿는 거리(0에 가까울수록 중심에 모인다)
///   - tint: 빛의 색
[[ stitchable ]] half4 godRays(
    float2 position,
    half4 color,
    float2 center,
    float time,
    float intensity,
    float reach,
    half4 tint
) {
    float2 delta = position - center;
    float dist = length(delta);
    float angle = atan2(delta.y, delta.x);

    // 서로 반대로 도는 두 겹의 빛줄기를 겹쳐 단조로운 방사형을 피한다.
    float a = 0.5 + 0.5 * sin(angle * 9.0 + time * 0.55 + 1.7 * sin(angle * 3.0 - time * 0.3));
    float b = 0.5 + 0.5 * sin(angle * 15.0 - time * 0.35 + 2.1 * sin(angle * 5.0 + time * 0.4));
    float rays = pow(a, 3.2) * 0.75 + pow(b, 5.0) * 0.55;

    // 중심은 밝고 멀어질수록 부드럽게 사라진다.
    float falloff = exp(-dist / max(reach, 1.0));
    float core = exp(-dist / max(reach * 0.22, 1.0));

    float strength = saturate((rays * falloff + core * 0.9) * intensity);
    // 색을 곱한 뒤 알파를 곱하는 미리 곱한(premultiplied) 알파 형태로 돌려준다.
    half s = half(strength);
    return half4(tint.rgb * s, s);
}

/// 빛 모임 중심의 맥동하는 후광 원판. 충전 단계에서 중앙이 점점 달아오르는 느낌을 준다.
/// - Parameters:
///   - center: 중심
///   - radius: 원판 반지름
///   - pulse: 0...1, 맥동 위상
///   - heat: 0...1, 가열 정도(클수록 중심이 하얗게 달아오른다)
///   - tint: 가장자리 색
///   - core: 중심 색
[[ stitchable ]] half4 chargeOrb(
    float2 position,
    half4 color,
    float2 center,
    float radius,
    float pulse,
    float heat,
    half4 tint,
    half4 core
) {
    float dist = length(position - center);
    float n = dist / max(radius, 1.0);
    float body = exp(-n * n * 2.4);
    float rim = exp(-pow((n - (0.78 + 0.08 * pulse)) * 5.0, 2.0)) * 0.5;
    float hot = exp(-n * n * 9.0) * heat;

    float alpha = saturate(body * (0.55 + 0.45 * heat) + rim * heat);
    half3 rgb = mix(tint.rgb, core.rgb, half(saturate(hot * 1.4)));
    half a = half(alpha);
    return half4(rgb * a, a);
}
