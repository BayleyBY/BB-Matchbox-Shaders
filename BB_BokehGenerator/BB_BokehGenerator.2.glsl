// BokehGenerator.2.glsl
// Pass 2: Lens blur applied to pass 1 output
// GLSL 120 compatible (macOS/Linux)

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1;
uniform float lens_blur;

void main() {
    vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec3 col = texture2D(adsk_results_pass1, uv).rgb;

    if (lens_blur > 0.001) {
        // Work in pixel space so X and Y are equal units
        float radius = lens_blur * adsk_result_w * 0.05; // radius in pixels
        vec2 pixelSize = vec2(1.0 / adsk_result_w, 1.0 / adsk_result_h);

        vec3 blurred = col;
        float total = 1.0;

        for (int s = 0; s < 48; s++) {
            float a = float(s) * 2.39996; // golden angle
            float r = sqrt(float(s + 1) / 48.0) * radius;
            // Equal pixel offset in both axes → true circular kernel
            vec2 offset = vec2(cos(a), sin(a)) * r * pixelSize;
            vec2 sampleUV = clamp(uv + offset, 0.0, 1.0);
            blurred += texture2D(adsk_results_pass1, sampleUV).rgb;
            total += 1.0;
        }

        col = blurred / total;
    }

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
