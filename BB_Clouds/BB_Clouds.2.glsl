// BB_Clouds – Pass 2: defocus blur
// Reads the cloud image from pass 1 and applies a circular disc blur.
// Uses a 32-tap Vogel spiral (golden-angle) kernel for an even disc distribution.
// At blur_amount = 0 the pass is a no-op.

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1;
uniform float blur_amount;

void main() {
    vec2 uv  = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec4 src = texture2D(adsk_results_pass1, uv);

    if (blur_amount < 0.5) {
        gl_FragColor = src;
        return;
    }

    vec2  px    = vec2(1.0 / adsk_result_w, 1.0 / adsk_result_h);
    vec3  acc   = src.rgb;
    float total = 1.0;

    for (int s = 0; s < 32; s++) {
        float a      = float(s) * 2.39996;                      // golden angle ~137.5°
        float r      = sqrt(float(s + 1) / 32.0) * blur_amount; // Vogel radius
        vec2  offset = vec2(cos(a), sin(a)) * r * px;
        acc   += texture2D(adsk_results_pass1, clamp(uv + offset, 0.0, 1.0)).rgb;
        total += 1.0;
    }

    gl_FragColor = vec4(acc / total, src.a);
}
