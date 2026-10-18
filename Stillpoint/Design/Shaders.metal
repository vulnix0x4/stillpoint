#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Noise

static float2 hash2(float2 p) {
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

/// Gradient noise in roughly [-0.7, 0.7].
static float gnoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = dot(hash2(i), f);
    float b = dot(hash2(i + float2(1.0, 0.0)), f - float2(1.0, 0.0));
    float c = dot(hash2(i + float2(0.0, 1.0)), f - float2(0.0, 1.0));
    float d = dot(hash2(i + float2(1.0, 1.0)), f - float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

/// Five octaves of rotated gradient noise.
static float fbm(float2 p) {
    float sum = 0.0;
    float amplitude = 0.5;
    const float2x2 rotation = float2x2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 5; i++) {
        sum += amplitude * gnoise(p);
        p = rotation * p * 2.03;
        amplitude *= 0.5;
    }
    return sum;
}

// MARK: - Orb

/// A luminous, slowly churning orb.
///
/// - turbulence: 0...1. How restless the surface and interior are. High when a session
///   starts, low once attention has settled.
/// - energy: 0...1. Extra size and glow, used for breathing and the goal bloom.
[[ stitchable ]] half4 orb(float2 position,
                           float4 bounds,
                           float time,
                           float turbulence,
                           float energy,
                           half4 core,
                           half4 mid,
                           half4 rim) {
    float2 size = bounds.zw;
    float2 center = bounds.xy + size * 0.5;
    float scale = min(size.x, size.y) * 0.5;
    float2 uv = (position - center) / scale;
    float r = length(uv);
    float pixel = 1.5 / scale;

    float t = time;
    float baseRadius = 0.62 * (1.0 + 0.012 * sin(t * 0.9) + 0.12 * energy);

    // The silhouette: noise sampled around the unit circle, so there is no seam.
    float2 direction = r > 1e-4 ? uv / r : float2(0.0, 1.0);
    float edgeNoise = fbm(direction * 1.3 + float2(t * 0.11, -t * 0.07));
    float edgeDetail = gnoise(direction * 3.5 + float2(-t * 0.23, t * 0.19));
    float edge = baseRadius * (1.0 + turbulence * (0.17 * edgeNoise + 0.05 * edgeDetail) + 0.012 * edgeNoise);

    float3 coreColor = float3(core.rgb);
    float3 midColor = float3(mid.rgb);
    float3 rimColor = float3(rim.rgb);

    // Soft halo that fades out well before the edges of the drawing rect.
    float outside = max(r - edge, 0.0);
    float halo = exp(-outside * (5.5 - 2.0 * energy)) * (0.40 + 0.40 * energy);
    halo *= 1.0 - smoothstep(0.78, 1.0, r);
    float3 haloColor = mix(midColor, rimColor, 0.55);

    if (r > edge + pixel * 2.0) {
        return half4(half3(haloColor * halo), half(halo));
    }

    // Interior: domain-warped noise gives slow, liquid filaments.
    float2 p = uv / baseRadius;
    float warp = 0.35 + 1.3 * turbulence;
    float2 q = float2(fbm(p * 1.6 + float2(0.0, t * 0.06)),
                      fbm(p * 1.6 + float2(5.2, 1.3) - t * 0.05));
    float2 w = float2(fbm(p * 1.9 + warp * q + float2(1.7, 9.2) + t * 0.04),
                      fbm(p * 1.9 + warp * q + float2(8.3, 2.8) - t * 0.035));
    float f = fbm(p * 2.1 + warp * w);

    float radial = clamp(r / edge, 0.0, 1.0);
    float shade = radial + f * (0.55 + 0.45 * turbulence);
    float3 body = mix(coreColor, midColor, smoothstep(0.05, 0.75, shade));
    body = mix(body, rimColor, smoothstep(0.62, 1.15, shade));

    float ridge = 1.0 - abs(f * 2.4);
    body += coreColor * pow(saturate(ridge), 8.0) * (0.22 + 0.22 * turbulence);

    // Pseudo-3D lighting: a soft key light from the upper left and a Fresnel rim.
    float z = sqrt(saturate(1.0 - radial * radial));
    float3 normal = normalize(float3(uv / edge, z));
    float specular = pow(saturate(dot(normal, normalize(float3(-0.35, -0.55, 0.76)))), 18.0) * 0.3;
    float fresnel = pow(1.0 - z, 2.5);
    body = body * (0.8 + 0.2 * z) + specular + fresnel * mix(midColor, coreColor, 0.3) * 0.32;
    body *= 1.0 + 0.22 * energy;
    body = saturate(body);

    float inside = smoothstep(edge + pixel, edge - pixel, r);
    float alpha = inside + halo * (1.0 - inside);
    float3 color = body * inside + haloColor * halo * (1.0 - inside);
    return half4(half3(color), half(saturate(alpha)));
}

// MARK: - Grain

/// Fine static film grain, which keeps large dark gradients from banding.
[[ stitchable ]] half4 grain(float2 position, half4 color, float strength) {
    float n = fract(sin(dot(position, float2(12.9898, 78.233))) * 43758.5453);
    return half4(color.rgb + half((n - 0.5) * strength) * color.a, color.a);
}
