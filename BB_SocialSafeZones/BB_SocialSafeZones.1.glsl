// SocialSafeZones — Social media safe zone overlay for Flame
// Draws colored overlay on unsafe areas with L-shaped engagement cutouts

uniform sampler2D front;
uniform float adsk_result_w;
uniform float adsk_result_h;

uniform int channel;
uniform float overlayOpacity;
uniform float borderWidth;
uniform bool showBorder;
uniform bool showButtons;
uniform float cornerRadius;
uniform float imgScale;
uniform float imgOffsetX;
uniform float imgOffsetY;
uniform vec3 overlayColor;
uniform vec3 borderColor;

// Safe zone margins as fractions: top/bottom of height, left/right of width.
// eng_right/eng_top define L-shaped engagement button cutout.
// valid: 1.0 = confirmed data, 0.5 = estimated, 0.0 = unsupported fallback.
// ch: 0=Instagram Reels (9:16), 1=Meta Feed (1:1), 2=Meta Feed (4:5),
//     3=Meta Stories (9:16), 4=TikTok (9:16),
//     5=YouTube DemandGen (16:9), 6=YouTube Shorts (9:16)
// tl_w/tl_h: top-left corner cutout width/height as UV fractions
// tr_w/tr_h: top-right corner cutout width/height as UV fractions
void getMargins(int ch,
                out float t, out float b, out float l, out float r,
                out float er, out float et,
                out float tl_w, out float tl_h,
                out float tr_w, out float tr_h,
                out float valid) {
    t = 0.05; b = 0.05; l = 0.05; r = 0.05;
    er = 0.0; et = 0.0;
    tl_w = 0.0; tl_h = 0.0; tr_w = 0.0; tr_h = 0.0;
    valid = 0.0;

    // --- Instagram Reels (9:16) (Meta official: 14%/35%/6% + L-shape) ---
    if (ch == 0) {
        t=0.14; b=0.35; l=0.06; r=0.06;
        er=0.21; et=0.60; valid=1.0;
    }
    // --- Meta Feed (1:1) ---
    else if (ch == 1) {
        t=0.125; b=0.125; l=0.025; r=0.025;
        valid=1.0;
    }
    // --- Meta Feed (4:5) ---
    else if (ch == 2) {
        t=0.1; b=0.1; l=0.025; r=0.025;
        valid=1.0;
    }
    // --- Meta Stories (9:16) (Meta official: 14% top, 20% bottom, 6% sides) ---
    else if (ch == 3) {
        t=0.14; b=0.20; l=0.06; r=0.06;
        valid=1.0;
    }
    // --- TikTok (9:16) ---
    else if (ch == 4) {
        t=0.1302; b=0.2109; l=0.0556; r=0.0556;
        er=0.1481; et=0.4479; valid=1.0;
    }
    // --- YouTube DemandGen (16:9) (Google official: 38/387/38/162px on 1920x1080) ---
    else if (ch == 5) {
        t=0.0352; b=0.3583; l=0.0198; r=0.0844;
        tl_w=0.2583; tl_h=0.1694;
        tr_w=0.2474; tr_h=0.1231;
        valid=1.0;
    }
    // --- YouTube Shorts (9:16) (Google official: 15%/35%/4.4%/17.8%) ---
    else if (ch == 6) {
        t=0.15; b=0.35; l=0.0444; r=0.1778;
        valid=1.0;
    }
}

bool pixelInSafe(vec2 p, float t, float b, float l, float r,
                 float er, float et, bool useEng,
                 float tl_w, float tl_h, float tr_w, float tr_h) {
    float left   = l;
    float right  = 1.0 - r;
    float bottom = b;
    float top    = 1.0 - t;

    if (p.x < left || p.x > right || p.y < bottom || p.y > top)
        return false;

    if (useEng && er > r && p.x > 1.0 - er && p.y < 1.0 - et) {
        // Round the inner corner of the cutout where its two edges meet
        if (cornerRadius > 0.0) {
            float crx = cornerRadius / adsk_result_w;
            float cry = cornerRadius / adsk_result_h;
            vec2 cc = vec2((1.0 - er) + crx, (1.0 - et) - cry);
            if (p.x < cc.x && p.y > cc.y) {
                vec2 d = (p - cc) * vec2(adsk_result_w, adsk_result_h);
                if (length(d) > cornerRadius) return true;
            }
        }
        return false;
    }

    // Top-left corner cutout
    if (showButtons && tl_w > 0.0 && p.x < tl_w && p.y > 1.0 - tl_h) {
        if (cornerRadius > 0.0) {
            float crx = cornerRadius / adsk_result_w;
            float cry = cornerRadius / adsk_result_h;
            vec2 cc = vec2(tl_w - crx, (1.0 - tl_h) + cry);
            if (p.x > cc.x && p.y < cc.y) {
                vec2 d = (p - cc) * vec2(adsk_result_w, adsk_result_h);
                if (length(d) > cornerRadius) return true;
            }
        }
        return false;
    }

    // Top-right corner cutout
    if (showButtons && tr_w > 0.0 && p.x > 1.0 - tr_w && p.y > 1.0 - tr_h) {
        if (cornerRadius > 0.0) {
            float crx = cornerRadius / adsk_result_w;
            float cry = cornerRadius / adsk_result_h;
            vec2 cc = vec2((1.0 - tr_w) + crx, (1.0 - tr_h) + cry);
            if (p.x < cc.x && p.y < cc.y) {
                vec2 d = (p - cc) * vec2(adsk_result_w, adsk_result_h);
                if (length(d) > cornerRadius) return true;
            }
        }
        return false;
    }

    // Rounded corners — check pixel distance from each corner center
    if (cornerRadius > 0.0) {
        float crx = cornerRadius / adsk_result_w;
        float cry = cornerRadius / adsk_result_h;

        // Main four corners of the safe zone rectangle
        vec2 bl = vec2(left  + crx, bottom + cry);
        vec2 br = vec2(right - crx, bottom + cry);
        vec2 tl = vec2(left  + crx, top    - cry);
        vec2 tr = vec2(right - crx, top    - cry);

        if      (p.x < bl.x && p.y < bl.y) {
            vec2 d = (p - bl) * vec2(adsk_result_w, adsk_result_h);
            if (length(d) > cornerRadius) return false;
        }
        else if (p.x > br.x && p.y < br.y) {
            vec2 d = (p - br) * vec2(adsk_result_w, adsk_result_h);
            if (length(d) > cornerRadius) return false;
        }
        else if (p.x < tl.x && p.y > tl.y) {
            vec2 d = (p - tl) * vec2(adsk_result_w, adsk_result_h);
            if (length(d) > cornerRadius) return false;
        }
        else if (p.x > tr.x && p.y > tr.y) {
            vec2 d = (p - tr) * vec2(adsk_result_w, adsk_result_h);
            if (length(d) > cornerRadius) return false;
        }

        // Two outer corners where the engagement cutout notch meets the safe zone
        if (useEng && er > r) {
            // Corner A: (1-r, 1-et) — right margin steps into the cutout
            vec2 ccA = vec2(right - crx, (1.0 - et) + cry);
            if (p.x > ccA.x && p.y > 1.0 - et && p.y < ccA.y) {
                vec2 d = (p - ccA) * vec2(adsk_result_w, adsk_result_h);
                if (length(d) > cornerRadius) return false;
            }

            // Corner B: (1-er, b) — cutout left edge meets safe zone bottom
            vec2 ccB = vec2((1.0 - er) - crx, bottom + cry);
            if (p.x > ccB.x && p.x < 1.0 - er && p.y < ccB.y) {
                vec2 d = (p - ccB) * vec2(adsk_result_w, adsk_result_h);
                if (length(d) > cornerRadius) return false;
            }
        }

        // Four outer corners created by top-left and top-right corner cutouts
        if (showButtons && tl_w > 0.0) {
            // Corner 1: (tl_w, top) — TL cutout right edge meets top margin
            vec2 cc1 = vec2(tl_w + crx, top - cry);
            if (p.x > tl_w && p.x < cc1.x && p.y > cc1.y) {
                vec2 d = (p - cc1) * vec2(adsk_result_w, adsk_result_h);
                if (length(d) > cornerRadius) return false;
            }
            // Corner 7: (left, 1-tl_h) — left margin meets TL cutout bottom
            vec2 cc7 = vec2(left + crx, (1.0 - tl_h) - cry);
            if (p.x < cc7.x && p.y > cc7.y && p.y < 1.0 - tl_h) {
                vec2 d = (p - cc7) * vec2(adsk_result_w, adsk_result_h);
                if (length(d) > cornerRadius) return false;
            }
        }

        if (showButtons && tr_w > 0.0) {
            // Corner 2: (1-tr_w, top) — TR cutout left edge meets top margin
            vec2 cc2 = vec2((1.0 - tr_w) - crx, top - cry);
            if (p.x < 1.0 - tr_w && p.x > cc2.x && p.y > cc2.y) {
                vec2 d = (p - cc2) * vec2(adsk_result_w, adsk_result_h);
                if (length(d) > cornerRadius) return false;
            }
            // Corner 4: (right, 1-tr_h) — right margin meets TR cutout bottom
            vec2 cc4 = vec2(right - crx, (1.0 - tr_h) - cry);
            if (p.x > cc4.x && p.y > cc4.y && p.y < 1.0 - tr_h) {
                vec2 d = (p - cc4) * vec2(adsk_result_w, adsk_result_h);
                if (length(d) > cornerRadius) return false;
            }
        }
    }

    return true;
}

void main(void) {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 uv = gl_FragCoord.xy / res;
    vec2 sampleUV = (uv - 0.5) / imgScale + 0.5 - vec2(imgOffsetX, imgOffsetY);
    vec4 src = texture2D(front, sampleUV);

    float t, b, l, r, er, et, tl_w, tl_h, tr_w, tr_h, valid;
    getMargins(channel, t, b, l, r, er, et, tl_w, tl_h, tr_w, tr_h, valid);

    bool useEng = showButtons && er > 0.0;
    bool safe = pixelInSafe(uv, t, b, l, r, er, et, useEng, tl_w, tl_h, tr_w, tr_h);

    vec3 result = src.rgb;
    float alpha = src.a;

    if (!safe) {
        result = mix(result, overlayColor, overlayOpacity);
    }

    if (showBorder) {
        float dx = borderWidth / adsk_result_w;
        float dy = borderWidth / adsk_result_h;

        bool edge = false;
        if (safe) {
            if (!pixelInSafe(uv + vec2( dx, 0.0), t, b, l, r, er, et, useEng, tl_w, tl_h, tr_w, tr_h) ||
                !pixelInSafe(uv + vec2(-dx, 0.0), t, b, l, r, er, et, useEng, tl_w, tl_h, tr_w, tr_h) ||
                !pixelInSafe(uv + vec2(0.0,  dy), t, b, l, r, er, et, useEng, tl_w, tl_h, tr_w, tr_h) ||
                !pixelInSafe(uv + vec2(0.0, -dy), t, b, l, r, er, et, useEng, tl_w, tl_h, tr_w, tr_h)) {
                edge = true;
            }
        }

        if (edge) {
            vec3 bc = borderColor;
            if (valid < 0.25) bc = vec3(1.0, 0.8, 0.0);
            else if (valid < 0.75) bc = vec3(1.0, 0.65, 0.0);
            result = bc;
        }
    }

    gl_FragColor = vec4(result, alpha);
}
