//
//  VariableBlur.metal
//  particleSearchBar
//
//  Progressive Gaussian blur + fade.
//  - Blur radius ramps quadratically from 0 (at startY) to maxRadius (at endY).
//  - Alpha fades with a steep t^5 curve — stays near-opaque until ~60% of the
//    range, then drops sharply to 0. This is the primary fade-to-transparent
//    mechanism; the SwiftUI gradient masks in beamsContainer provide the
//    initial shape fade, and this shader handles the final dissolve + spread.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[stitchable]] half4 triangleVariableBlur(
    float2 pos, SwiftUI::Layer layer,
    float maxRadius, float startY, float endY
) {
    // t: 0 at startY → 1 at endY
    float t      = clamp((pos.y - startY) / max(endY - startY, 1.0), 0.0, 1.0);
    float radius = t * t * maxRadius;           // quadratic blur ramp

    // t^5 fade — barely touches the upper beam, drops steeply near the base
    float t2   = t * t;
    float fade = 1.0 - t2 * t2 * t;            // 1 at startY, 0 at endY

    // Sharp region — no blur, just apply fade
    if (radius < 0.5) {
        return layer.sample(pos) * half(fade);
    }

    // Gaussian blur (sample radius capped at 10 px for mobile performance)
    half4 color       = half4(0.0);
    float totalWeight = 0.0;
    float sigma       = radius * 0.45;
    float twoSig2     = 2.0 * sigma * sigma;
    int   r           = min(int(ceil(radius)), 10);

    for (int dx = -r; dx <= r; dx++) {
        for (int dy = -r; dy <= r; dy++) {
            float dist2 = float(dx * dx + dy * dy);
            float w     = exp(-dist2 / twoSig2);
            color       += layer.sample(pos + float2(float(dx), float(dy))) * half(w);
            totalWeight += w;
        }
    }

    half4 result = totalWeight > 0.0 ? color / half(totalWeight) : layer.sample(pos);
    return result * half(fade);
}
