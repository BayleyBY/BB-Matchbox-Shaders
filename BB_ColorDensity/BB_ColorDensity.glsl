// Color Density Shader
// Applies density (luminance reduction with saturation compensation) per color vector
// Similar to PowerGrade Film Emulation methods in DaVinci Resolve / Baselight

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;

// Color space selection
// 0 = Rec.709 (gamma-encoded)
// 1 = Scene-Linear (Rec.709 primaries)
// 2 = ACEScg (AP1 primaries, linear)
// 3 = ACEScct (AP1 primaries, log encoding)
uniform int colorSpace;

// Density controls (0.0 = no effect, positive = add density/darken, negative = remove density/lighten)
uniform float densityRed;
uniform float densityGreen;
uniform float densityBlue;
uniform float densityCyan;
uniform float densityMagenta;
uniform float densityYellow;

// Intensity/Saturation boost per channel (multiplier for saturation compensation)
uniform float intensityRed;
uniform float intensityGreen;
uniform float intensityBlue;
uniform float intensityCyan;
uniform float intensityMagenta;
uniform float intensityYellow;

// Global controls
uniform float globalDensity;
uniform float globalIntensity;

// Luminance preservation toggle
uniform bool preserveLuma;

// Luminance coefficients per color space
vec3 getLumaCoeff() {
    if (colorSpace == 2 || colorSpace == 3) { // ACEScg or ACEScct (AP1 primaries)
        return vec3(0.2722, 0.6741, 0.0537);
    }
    // Rec.709, Scene-Linear use Rec.709 primaries
    return vec3(0.2126, 0.7152, 0.0722);
}

// Convert linear to perceptual space for density operations
vec3 toPerceptual(vec3 color) {
    if (colorSpace == 1 || colorSpace == 2) { // Scene-Linear or ACEScg
        // Apply gamma curve (handles negative values for wide gamut)
        return sign(color) * pow(abs(color), vec3(1.0 / 2.4));
    }
    // Rec.709 and Log are already perceptual-ish
    return color;
}

// Convert from perceptual space back to linear
vec3 fromPerceptual(vec3 color) {
    if (colorSpace == 1 || colorSpace == 2) { // Scene-Linear or ACEScg
        return sign(color) * pow(abs(color), vec3(2.4));
    }
    return color;
}

// Calculate luminance using appropriate coefficients
float getLuma(vec3 color) {
    return dot(color, getLumaCoeff());
}

// Calculate primary color vector weights (R, G, B)
vec3 getPrimaryWeights(vec3 color) {
    float r = color.r - (color.g + color.b) * 0.5;
    float g = color.g - (color.r + color.b) * 0.5;
    float b = color.b - (color.r + color.g) * 0.5;
    return max(vec3(r, g, b), 0.0);
}

// Calculate secondary color vector weights (C, M, Y)
vec3 getSecondaryWeights(vec3 color) {
    float c = min(color.g, color.b) - color.r; // Cyan = G+B, no R
    float m = min(color.r, color.b) - color.g; // Magenta = R+B, no G
    float y = min(color.r, color.g) - color.b; // Yellow = R+G, no B
    return max(vec3(c, m, y), 0.0);
}

// Apply density to a color
// Density reduces luminance while saturation is boosted to compensate
vec3 applyDensity(vec3 color, float density, float intensity) {
    if (abs(density) < 0.001) return color;

    float luma = getLuma(color);

    // Calculate saturation vector (color - neutral)
    vec3 saturationVec = color - vec3(luma);

    // Apply density as luminance reduction (exponential for film-like response)
    float densityMult = exp(-density * 0.5);
    float newLuma = luma * densityMult;

    // Calculate saturation boost to compensate for density
    float satBoost = 1.0 + (density * intensity * 0.5);
    satBoost = max(satBoost, 0.0);

    // Reconstruct color with new luminance and boosted saturation
    vec3 result = vec3(newLuma) + saturationVec * satBoost;

    return result;
}

// Soft clamp - only applied for Rec.709, preserves HDR/wide gamut for other spaces
vec3 softClamp(vec3 color) {
    // Skip clamping for Scene-Linear, ACEScg, and Log
    if (colorSpace != 0) {
        return color;
    }

    // Rec.709: soft clamp to avoid harsh clipping
    float maxChannel = max(max(color.r, color.g), color.b);
    if (maxChannel > 1.0) {
        float compress = 1.0 / maxChannel;
        float blend = smoothstep(1.0, 2.0, maxChannel);
        color = mix(color * compress, vec3(1.0), blend * 0.5);
    }
    return clamp(color, 0.0, 1.0);
}

void main() {
    vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec4 texColor = texture2D(front, uv);
    vec3 color = texColor.rgb;

    // Convert to perceptual space for density operations (linear spaces only)
    vec3 workingColor = toPerceptual(color);

    // Get color vector weights (calculated in perceptual space)
    vec3 primaryW = getPrimaryWeights(workingColor);
    vec3 secondaryW = getSecondaryWeights(workingColor);

    // Normalize weights to prevent over-application
    float totalWeight = primaryW.r + primaryW.g + primaryW.b +
                        secondaryW.r + secondaryW.g + secondaryW.b;
    totalWeight = max(totalWeight, 0.001);

    // Apply density per color vector, weighted by isolation
    // All operations in perceptual space
    vec3 result = workingColor;

    // Primary colors (RGB)
    if (primaryW.r > 0.001) {
        float weight = primaryW.r / totalWeight;
        vec3 adjusted = applyDensity(workingColor, densityRed + globalDensity, intensityRed * globalIntensity);
        result = mix(result, adjusted, weight);
    }
    if (primaryW.g > 0.001) {
        float weight = primaryW.g / totalWeight;
        vec3 adjusted = applyDensity(workingColor, densityGreen + globalDensity, intensityGreen * globalIntensity);
        result = mix(result, adjusted, weight);
    }
    if (primaryW.b > 0.001) {
        float weight = primaryW.b / totalWeight;
        vec3 adjusted = applyDensity(workingColor, densityBlue + globalDensity, intensityBlue * globalIntensity);
        result = mix(result, adjusted, weight);
    }

    // Secondary colors (CMY)
    if (secondaryW.r > 0.001) {
        float weight = secondaryW.r / totalWeight;
        vec3 adjusted = applyDensity(workingColor, densityCyan + globalDensity, intensityCyan * globalIntensity);
        result = mix(result, adjusted, weight);
    }
    if (secondaryW.g > 0.001) {
        float weight = secondaryW.g / totalWeight;
        vec3 adjusted = applyDensity(workingColor, densityMagenta + globalDensity, intensityMagenta * globalIntensity);
        result = mix(result, adjusted, weight);
    }
    if (secondaryW.b > 0.001) {
        float weight = secondaryW.b / totalWeight;
        vec3 adjusted = applyDensity(workingColor, densityYellow + globalDensity, intensityYellow * globalIntensity);
        result = mix(result, adjusted, weight);
    }

    // Restore original luminance if preserve mode is enabled
    // Keeps the chrominance/color enrichment from density but removes the darkening
    if (preserveLuma) {
        float origLuma = getLuma(workingColor);
        float newLuma = getLuma(result);
        vec3 chromaVec = result - vec3(newLuma);
        result = vec3(origLuma) + chromaVec;
    }

    // Convert back from perceptual space to original color space
    result = fromPerceptual(result);

    // Soft clamp (only for Rec.709, preserves HDR for other spaces)
    result = softClamp(result);

    gl_FragColor = vec4(result, texColor.a);
}
