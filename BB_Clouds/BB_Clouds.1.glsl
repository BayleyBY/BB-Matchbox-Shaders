// BB_Clouds – Pass 1: cloud generation
// Procedural animated sky and cloud layer for Autodesk Flame 2026.
//
// Based on "Clouds" (Shadertoy) – original author unknown.
// Flame port: entry point, uniforms, and time source adapted for Matchbox.
// Cloud and sky parameters exposed as UI controls.
// Perspective camera: each pixel casts a ray to a horizontal cloud plane,
// giving natural perspective as the camera tilts toward the horizon.
// Four cloud layers distributed across cloud_depth give apparent vertical depth.

uniform float adsk_result_w, adsk_result_h;
uniform float adsk_time;

// Cloud shape
uniform float cloudscale;
uniform float cloudcover;
uniform float cloudalpha;
uniform float cloud_speed;
uniform float cloud_depth;     // vertical span across the four cloud layers
uniform float cloud_softness;  // 0 = sharp/detailed, 1 = soft/diffuse

// Cloud lighting
uniform float clouddark;
uniform float cloudlight;
uniform float skytint;

// Colour
uniform vec3  skycolour1;    // zenith / top of sky
uniform vec3  skycolour2;    // horizon / bottom of sky
uniform vec3  cloud_color;   // base cloud colour

// Camera
uniform float cam_pitch;     // degrees: 0 = horizontal, 90 = straight up
uniform float cam_yaw;       // degrees: rotates the overhead view
uniform float fov;           // horizontal field of view in degrees
uniform float cloud_height;  // height of the cloud plane (higher = more distant)
uniform float pan_x;         // additional UV offset
uniform float pan_y;

// Animation
uniform float time_scale;
uniform float time_offset;

// ----------------------------------------------------------------

const mat2 m = mat2(1.6, 1.2, -1.2, 1.6);

// ----------------------------------------------------------------
// Noise
// ----------------------------------------------------------------

vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(in vec2 p) {
    const float K1 = 0.366025404;
    const float K2 = 0.211324865;
    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;
    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n = h*h*h*h * vec3(dot(a, hash(i)), dot(b, hash(i + o)), dot(c, hash(i + 1.0)));
    return dot(n, vec3(70.0));
}

float fbm(vec2 n) {
    float total = 0.0, amplitude = 0.1;
    for (int i = 0; i < 7; i++) {
        total     += noise(n) * amplitude;
        n          = m * n;
        amplitude *= 0.4;
    }
    return total;
}

// ----------------------------------------------------------------
// Cloud layer sampler
// ----------------------------------------------------------------

void sampleLayer(vec2 uv_base, vec2 seed,
                 float tc1, float tc2, float tc3,
                 out float layer_mix, out vec3 layer_colour)
{
    uv_base += seed;
    float q = fbm(uv_base * cloudscale * 0.5);

    // Ridged noise shape — scaled down by softness to remove hard wispy edges
    float r = 0.0;
    vec2  uv = uv_base * cloudscale;
    uv -= q - tc1;
    float weight = 0.8;
    for (int i = 0; i < 8; i++) {
        r     += abs(weight * noise(uv));
        uv     = m * uv + tc1;
        weight *= 0.7;
    }
    r *= (1.0 - cloud_softness * 0.85);

    // Noise shape
    float f = 0.0;
    uv = uv_base * cloudscale;
    uv -= q - tc1;
    weight = 0.7;
    for (int i = 0; i < 8; i++) {
        f     += weight * noise(uv);
        uv     = m * uv + tc1;
        weight *= 0.6;
    }
    f *= r + f;

    // Noise colour
    float c = 0.0;
    uv = uv_base * cloudscale * 2.0;
    uv -= q - tc2;
    weight = 0.4;
    for (int i = 0; i < 7; i++) {
        c     += weight * noise(uv);
        uv     = m * uv + tc2;
        weight *= 0.6;
    }

    // Noise ridge colour
    float c1 = 0.0;
    uv = uv_base * cloudscale * 3.0;
    uv -= q - tc3;
    weight = 0.4;
    for (int i = 0; i < 7; i++) {
        c1    += abs(weight * noise(uv));
        uv     = m * uv + tc3;
        weight *= 0.6;
    }
    c += c1;

    // Remap UI range [0, 10] → internal [-3.0, 1.0] so 0 = guaranteed no clouds
    float cc      = mix(-3.0, 1.0, cloudcover / 10.0);
    float f_final = cc + cloudalpha * f * r;
    float gamma   = mix(1.0, 0.4, cloud_softness);
    layer_mix     = pow(clamp(f_final + c, 0.0, 1.0), gamma);
    layer_colour  = cloud_color * clamp(clouddark + cloudlight * c, 0.0, 1.0);
}

// ----------------------------------------------------------------
// Main
// ----------------------------------------------------------------

void main() {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 p   = gl_FragCoord.xy / res;

    // ---- Camera basis vectors ------------------------------------
    float pitch_rad = radians(cam_pitch);
    float yaw_rad   = radians(cam_yaw);

    vec3 fwd = normalize(vec3(
        cos(pitch_rad) * sin(yaw_rad),
        sin(pitch_rad),
        cos(pitch_rad) * cos(yaw_rad)
    ));
    vec3 right = normalize(vec3(cos(yaw_rad), 0.0, -sin(yaw_rad)));
    vec3 up    = normalize(cross(fwd, right));

    // ---- Ray for this pixel --------------------------------------
    vec2  ndc       = (p * 2.0 - 1.0) * vec2(res.x / res.y, 1.0);
    float fov_scale = tan(radians(clamp(fov, 1.0, 170.0) * 0.5));
    vec3  ray       = normalize(fwd + ndc.x * right * fov_scale + ndc.y * up * fov_scale);

    float cloud_contrib = smoothstep(0.0, 0.05, ray.y);

    // ---- Time ----------------------------------------------------
    float secs = adsk_time / 25.0;
    float tc1  = secs * time_scale * cloud_speed         + time_offset;
    float tc2  = secs * time_scale * cloud_speed * 2.0   + time_offset;
    float tc3  = secs * time_scale * cloud_speed * 3.0   + time_offset;

    // ---- Four cloud layers evenly distributed over cloud_depth ---
    float step = cloud_depth / 3.0;
    float ta = ray.y > 0.001 ? (cloud_height)              / ray.y : 0.0;
    float tb = ray.y > 0.001 ? (cloud_height + step)       / ray.y : 0.0;
    float tc = ray.y > 0.001 ? (cloud_height + step * 2.0) / ray.y : 0.0;
    float td = ray.y > 0.001 ? (cloud_height + step * 3.0) / ray.y : 0.0;

    vec2 offset = vec2(pan_x, pan_y);
    vec2 xz     = vec2(ray.x, ray.z);

    float mix0, mix1, mix2, mix3;
    vec3  col0, col1, col2, col3;

    sampleLayer(xz * ta + offset, vec2(  0.00,   0.00), tc1, tc2, tc3, mix0, col0);
    sampleLayer(xz * tb + offset, vec2( 31.41,  27.18), tc1, tc2, tc3, mix1, col1);
    sampleLayer(xz * tc + offset, vec2(157.30,  83.70), tc1, tc2, tc3, mix2, col2);
    sampleLayer(xz * td + offset, vec2(241.90, 193.40), tc1, tc2, tc3, mix3, col3);

    mix0 *= cloud_contrib * 1.00;
    mix1 *= cloud_contrib * 0.90;
    mix2 *= cloud_contrib * 0.80;
    mix3 *= cloud_contrib * 0.70;

    // ---- Composite -----------------------------------------------
    float sky_t     = clamp(ray.y, 0.0, 1.0);
    vec3  skycolour = mix(skycolour2, skycolour1, sky_t);

    float cloud_mix   = max(mix0, max(mix1, max(mix2, mix3)));
    float total_w     = mix0 + mix1 + mix2 + mix3 + 0.0001;
    vec3  cloudcolour = (col0*mix0 + col1*mix1 + col2*mix2 + col3*mix3) / total_w;

    vec3 result = mix(
        skycolour,
        clamp(skytint * skycolour + cloudcolour, 0.0, 1.0),
        cloud_mix);

    gl_FragColor = vec4(result, 1.0);
}
