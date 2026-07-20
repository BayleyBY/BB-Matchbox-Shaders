// BB_PerspectiveLines
// Perspective vanishing point line overlay for Autodesk Flame 2026
//
// Draws a fan of lines between two user-defined outer lines.
// The vanishing point is derived from the intersection of those
// two outer lines (extended) and displayed as an on-screen widget.
//
// Coordinate system: origin (0,0) = bottom-left of frame.

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;

// First VP line set
uniform bool lines1_enable;

// Outer line A  (normalized 0-1, Y=0 bottom)
uniform vec2 la_start, la_end;

// Outer line B
uniform vec2 lb_start, lb_end;

// Intermediate lines
uniform int num_inter;         // 1 – 10

// Line appearance
uniform vec3  line_color;
uniform float line_opacity;
uniform float line_width;      // pixels (AA edge)

// Vanishing point widget
uniform bool  show_vp;
uniform float vp_size;         // widget ring radius in pixels

// Dash style – first VP set
uniform int   dash1_enable;    // 0 = solid, 1 = dashed
uniform float dash1_length;    // dash length in pixels
uniform float dash1_gap;       // gap length in pixels

// Crosshatch – first VP set
uniform bool  crosshatch1_enable;
uniform int   num_cross1;      // number of cross lines (1-10)

// Second VP line set (two-point perspective)
uniform bool  lines2_enable;
uniform vec2  lc_start, lc_end;
uniform vec2  ld_start, ld_end;
uniform int   num_inter2;
uniform vec3  line_color2;
uniform float line_opacity2;
uniform float line_width2;
uniform bool  show_vp2;
uniform float vp_size2;

// Dash style – second VP set
uniform int   dash2_enable;    // 0 = solid, 1 = dashed
uniform float dash2_length;
uniform float dash2_gap;

// Crosshatch – second VP set
uniform bool  crosshatch2_enable;
uniform int   num_cross2;

// Opacity falloff toward VP
uniform float line_falloff;    // 0 = none, 1 = full fade at VP
uniform float line_falloff2;

// Extend lines to VP
uniform bool  extend1_enable;
uniform bool  extend2_enable;

// Matte output
uniform bool  matte_enable;

// Horizon line
uniform bool  horiz_enable;
uniform bool  horiz_auto_vp;
uniform float horiz_y;         // vertical position (0=bottom, 1=top)
uniform float horiz_rot;       // rotation in degrees around horizontal centre
uniform float horiz_width;     // pixels (hard edge)
uniform float horiz_opacity;
uniform vec3  horiz_color;

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

float cross2d(vec2 a, vec2 b) {
    return a.x * b.y - a.y * b.x;
}

// Shortest distance from pixel p to segment a->b (pixel space)
float distToSeg(vec2 p, vec2 a, vec2 b) {
    vec2  ab   = b - a;
    float len2 = dot(ab, ab);
    if (len2 < 0.0001) return length(p - a);
    float t = clamp(dot(p - a, ab) / len2, 0.0, 1.0);
    return length(p - (a + t * ab));
}

// ----------------------------------------------------------------
// Main
// ----------------------------------------------------------------

void main() {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 px  = gl_FragCoord.xy;
    vec2 uv  = px / res;

    vec4 bg = texture2D(front, uv);

    // Convert normalised endpoints → pixel space
    vec2 a0 = la_start * res;
    vec2 a1 = la_end   * res;
    vec2 b0 = lb_start * res;
    vec2 b1 = lb_end   * res;

    // ---- Vanishing point ------------------------------------------
    // Intersection of line A and line B extended beyond their endpoints
    vec2  da      = a1 - a0;
    vec2  db      = b1 - b0;
    float denom   = cross2d(da, db);
    bool  vpValid = abs(denom) > 1e-4;

    // Use a safe fallback of 0 when lines are parallel (no VP)
    float vpT   = vpValid ? cross2d(b0 - a0, db) / denom : 0.0;
    vec2  vp    = a0 + vpT * da;

    bool vpInFrame = vpValid
                     && vp.x >= 0.0 && vp.x <= res.x
                     && vp.y >= 0.0 && vp.y <= res.y;

    // ---- Draw perspective lines -----------------------------------
    float halfW = line_width * 0.5;
    float mask  = 0.0;

    if (lines1_enable) {
        // total lines = 2 outer + num_inter intermediate
        int total = num_inter + 2;

        for (int i = 0; i < 12; i++) {
            if (i >= total) break;

            // t = 0 → line A,  t = 1 → line B,  in-between → intermediate
            float t        = float(i) / float(total - 1);
            vec2  segStart = mix(a0, b0, t);
            vec2  segEnd   = mix(a1, b1, t);
            float d  = distToSeg(px, segStart, segEnd);
            float aa = smoothstep(halfW + 0.5, halfW - 0.5, d);

            if (aa > 0.0) {
                bool inDash = true;
                if (dash1_enable == 1) {
                    vec2  seg   = segEnd - segStart;
                    float len   = length(seg);
                    float along = len > 0.001 ? dot(px - segStart, seg) / len : 0.0;
                    inDash = mod(max(along, 0.0), dash1_length + dash1_gap) < dash1_length;
                }
                if (inDash) {
                    float vpDist  = vpValid ? length(px - vp) / length(res) : 1.0;
                    float contrib = mix(1.0, smoothstep(0.0, 0.35, vpDist), line_falloff);
                    mask = max(mask, aa * contrib);
                }
            }

            // Extension from nearest handle to VP
            if (extend1_enable && vpValid) {
                vec2 nearEnd;
                if (length(segStart - vp) < length(segEnd - vp)) {
                    nearEnd = segStart;
                } else {
                    nearEnd = segEnd;
                }
                float de  = distToSeg(px, nearEnd, vp);
                float aaE = smoothstep(halfW + 0.5, halfW - 0.5, de);
                if (aaE > 0.0) {
                    bool inDash = true;
                    if (dash1_enable == 1) {
                        vec2  seg   = vp - nearEnd;
                        float len   = length(seg);
                        float along = len > 0.001 ? dot(px - nearEnd, seg) / len : 0.0;
                        inDash = mod(max(along, 0.0), dash1_length + dash1_gap) < dash1_length;
                    }
                    if (inDash) {
                        float vpDist  = length(px - vp) / length(res);
                        float contrib = mix(1.0, smoothstep(0.0, 0.35, vpDist), line_falloff);
                        mask = max(mask, aaE * contrib);
                    }
                }
            }
        }

        // Crosshatch: lines connecting corresponding points on Line A and Line B
        if (crosshatch1_enable) {
            for (int j = 0; j < 10; j++) {
                if (j >= num_cross1) break;
                float u      = float(j + 1) / float(num_cross1 + 1);
                vec2  cStart = mix(a0, a1, u);
                vec2  cEnd   = mix(b0, b1, u);
                float d   = distToSeg(px, cStart, cEnd);
                float aaC = smoothstep(halfW + 0.5, halfW - 0.5, d);
                if (aaC > 0.0) {
                    bool inDash = true;
                    if (dash1_enable == 1) {
                        vec2  seg   = cEnd - cStart;
                        float len   = length(seg);
                        float along = len > 0.001 ? dot(px - cStart, seg) / len : 0.0;
                        inDash = mod(max(along, 0.0), dash1_length + dash1_gap) < dash1_length;
                    }
                    if (inDash) {
                        float vpDist  = vpValid ? length(px - vp) / length(res) : 1.0;
                        float contrib = mix(1.0, smoothstep(0.0, 0.35, vpDist), line_falloff);
                        mask = max(mask, aaC * contrib);
                    }
                }
            }
        }
    }

    // ---- Second VP line set (two-point perspective) --------------
    float mask2 = 0.0;

    // VP2 geometry – computed regardless of enable state so the horizon
    // auto-positioning can use it even when VP2 lines are hidden.
    vec2  c0       = lc_start * res;
    vec2  c1       = lc_end   * res;
    vec2  e0       = ld_start * res;
    vec2  e1       = ld_end   * res;
    vec2  dc       = c1 - c0;
    vec2  de       = e1 - e0;
    float denom2   = cross2d(dc, de);
    bool  vp2Valid = abs(denom2) > 1e-4;
    float vp2T     = vp2Valid ? cross2d(e0 - c0, de) / denom2 : 0.0;
    vec2  vp2      = c0 + vp2T * dc;
    bool  vp2InFrame = vp2Valid
                       && vp2.x >= 0.0 && vp2.x <= res.x
                       && vp2.y >= 0.0 && vp2.y <= res.y;

    if (lines2_enable) {
        float halfW2 = line_width2 * 0.5;
        int   total2 = num_inter2 + 2;

        for (int i = 0; i < 12; i++) {
            if (i >= total2) break;
            float t         = float(i) / float(total2 - 1);
            vec2  seg2Start = mix(c0, e0, t);
            vec2  seg2End   = mix(c1, e1, t);
            float d2        = distToSeg(px, seg2Start, seg2End);

            float aa2 = smoothstep(halfW2 + 0.5, halfW2 - 0.5, d2);
            if (aa2 > 0.0) {
                bool inDash2 = true;
                if (dash2_enable == 1) {
                    vec2  seg2   = seg2End - seg2Start;
                    float len2   = length(seg2);
                    float along2 = len2 > 0.001 ? dot(px - seg2Start, seg2) / len2 : 0.0;
                    inDash2 = mod(max(along2, 0.0), dash2_length + dash2_gap) < dash2_length;
                }
                if (inDash2) {
                    float vp2Dist  = vp2Valid ? length(px - vp2) / length(res) : 1.0;
                    float contrib2 = mix(1.0, smoothstep(0.0, 0.35, vp2Dist), line_falloff2);
                    mask2 = max(mask2, aa2 * contrib2);
                }
            }

            // Extension from nearest handle to VP2
            if (extend2_enable && vp2Valid) {
                vec2 nearEnd2;
                if (length(seg2Start - vp2) < length(seg2End - vp2)) {
                    nearEnd2 = seg2Start;
                } else {
                    nearEnd2 = seg2End;
                }
                float de2  = distToSeg(px, nearEnd2, vp2);
                float aaE2 = smoothstep(halfW2 + 0.5, halfW2 - 0.5, de2);
                if (aaE2 > 0.0) {
                    bool inDash2 = true;
                    if (dash2_enable == 1) {
                        vec2  seg2   = vp2 - nearEnd2;
                        float len2   = length(seg2);
                        float along2 = len2 > 0.001 ? dot(px - nearEnd2, seg2) / len2 : 0.0;
                        inDash2 = mod(max(along2, 0.0), dash2_length + dash2_gap) < dash2_length;
                    }
                    if (inDash2) {
                        float vp2Dist  = length(px - vp2) / length(res);
                        float contrib2 = mix(1.0, smoothstep(0.0, 0.35, vp2Dist), line_falloff2);
                        mask2 = max(mask2, aaE2 * contrib2);
                    }
                }
            }
        }

        // Crosshatch: lines connecting corresponding points on Line C and Line D
        if (crosshatch2_enable) {
            for (int j = 0; j < 10; j++) {
                if (j >= num_cross2) break;
                float u       = float(j + 1) / float(num_cross2 + 1);
                vec2  cStart2 = mix(c0, c1, u);
                vec2  cEnd2   = mix(e0, e1, u);
                float d    = distToSeg(px, cStart2, cEnd2);
                float aaC2 = smoothstep(halfW2 + 0.5, halfW2 - 0.5, d);
                if (aaC2 > 0.0) {
                    bool inDash2 = true;
                    if (dash2_enable == 1) {
                        vec2  seg2   = cEnd2 - cStart2;
                        float len2   = length(seg2);
                        float along2 = len2 > 0.001 ? dot(px - cStart2, seg2) / len2 : 0.0;
                        inDash2 = mod(max(along2, 0.0), dash2_length + dash2_gap) < dash2_length;
                    }
                    if (inDash2) {
                        float vp2Dist  = vp2Valid ? length(px - vp2) / length(res) : 1.0;
                        float contrib2 = mix(1.0, smoothstep(0.0, 0.35, vp2Dist), line_falloff2);
                        mask2 = max(mask2, aaC2 * contrib2);
                    }
                }
            }
        }

        if (show_vp2 && vp2InFrame) {
            float dist2 = length(px - vp2);
            if (abs(dist2 - vp_size2) <= 1.0)                                       mask2 = 1.0;
            if (dist2 <= 2.5)                                                        mask2 = 1.0;
            if (abs(px.y - vp2.y) <= 1.0 && abs(px.x - vp2.x) <= vp_size2 * 1.6)  mask2 = 1.0;
            if (abs(px.x - vp2.x) <= 1.0 && abs(px.y - vp2.y) <= vp_size2 * 1.6)  mask2 = 1.0;
        }

        // Off-screen VP2 arrow
        if (show_vp2 && vp2Valid && !vp2InFrame) {
            vec2  ctr2  = res * 0.5;
            vec2  dir2  = normalize(vp2 - ctr2);
            float tx2   = abs(dir2.x) > 1e-5 ? (res.x * 0.5) / abs(dir2.x) : 1e9;
            float ty2   = abs(dir2.y) > 1e-5 ? (res.y * 0.5) / abs(dir2.y) : 1e9;
            vec2  ep2   = ctr2 + min(tx2, ty2) * dir2;
            vec2  perp2 = vec2(-dir2.y, dir2.x);
            vec2  av0   = ep2;
            vec2  av1   = ep2 - 28.0 * dir2 + 20.0 * perp2;
            vec2  av2   = ep2 - 28.0 * dir2 - 20.0 * perp2;
            float ad1   = cross2d(px - av0, av1 - av0);
            float ad2   = cross2d(px - av1, av2 - av1);
            float ad3   = cross2d(px - av2, av0 - av2);
            bool  aN    = (ad1 < 0.0) || (ad2 < 0.0) || (ad3 < 0.0);
            bool  aP    = (ad1 > 0.0) || (ad2 > 0.0) || (ad3 > 0.0);
            if (!(aN && aP)) mask2 = 1.0;
        }
    }

    // ---- Horizon line --------------------------------------------
    float horizMask = 0.0;
    if (horiz_enable) {
        float centreY = horiz_y * res.y;
        if (horiz_auto_vp) {
            int   avpCount = 0;
            float avpYSum  = 0.0;
            if (vpValid)   { avpYSum += vp.y;  avpCount++; }
            if (vp2Valid)  { avpYSum += vp2.y; avpCount++; }
            if (avpCount > 0) centreY = avpYSum / float(avpCount);
        }
        vec2  centre   = vec2(res.x * 0.5, centreY);
        vec2  dir      = vec2(cos(radians(horiz_rot)), sin(radians(horiz_rot)));
        float d          = abs(cross2d(dir, px - centre));
        float horizHalfW = horiz_width * 0.5;
        horizMask = smoothstep(horizHalfW + 0.5, horizHalfW - 0.5, d);
    }

    // ---- Vanishing point widget -----------------------------------
    if (lines1_enable && show_vp && vpInFrame) {
        float dist = length(px - vp);

        // Hollow ring
        if (abs(dist - vp_size) <= 1.0)
            mask = 1.0;

        // Centre dot
        if (dist <= 2.5)
            mask = 1.0;

        // Horizontal crosshair arm
        if (abs(px.y - vp.y) <= 1.0 && abs(px.x - vp.x) <= vp_size * 1.6)
            mask = 1.0;

        // Vertical crosshair arm
        if (abs(px.x - vp.x) <= 1.0 && abs(px.y - vp.y) <= vp_size * 1.6)
            mask = 1.0;
    }

    // Off-screen VP1 arrow
    if (lines1_enable && show_vp && vpValid && !vpInFrame) {
        vec2  ctr1  = res * 0.5;
        vec2  dir1  = normalize(vp - ctr1);
        float tx1   = abs(dir1.x) > 1e-5 ? (res.x * 0.5) / abs(dir1.x) : 1e9;
        float ty1   = abs(dir1.y) > 1e-5 ? (res.y * 0.5) / abs(dir1.y) : 1e9;
        vec2  ep1   = ctr1 + min(tx1, ty1) * dir1;
        vec2  perp1 = vec2(-dir1.y, dir1.x);
        vec2  bv0   = ep1;
        vec2  bv1   = ep1 - 28.0 * dir1 + 20.0 * perp1;
        vec2  bv2   = ep1 - 28.0 * dir1 - 20.0 * perp1;
        float bd1   = cross2d(px - bv0, bv1 - bv0);
        float bd2   = cross2d(px - bv1, bv2 - bv1);
        float bd3   = cross2d(px - bv2, bv0 - bv2);
        bool  bN    = (bd1 < 0.0) || (bd2 < 0.0) || (bd3 < 0.0);
        bool  bP    = (bd1 > 0.0) || (bd2 > 0.0) || (bd3 > 0.0);
        if (!(bN && bP)) mask = 1.0;
    }

    // ---- Composite lines over background -------------------------
    vec3 outColor = mix(bg.rgb,   line_color,  mask       * line_opacity);
    outColor      = mix(outColor, line_color2, mask2      * line_opacity2);
    outColor      = mix(outColor, horiz_color, horizMask  * horiz_opacity);

    // ---- Matte output -------------------------------------------
    // Flame composites shader alpha over source alpha, so pure-alpha mattes
    // collapse to 1.0. Output the matte as grayscale RGB instead — use it
    // as a luma matte source downstream.
    float m1 = clamp(mask      * line_opacity,  0.0, 1.0);
    float m2 = clamp(mask2     * line_opacity2, 0.0, 1.0);
    float mh = clamp(horizMask * horiz_opacity, 0.0, 1.0);
    float drawMatte = max(max(m1, m2), mh);

    if (matte_enable) {
        gl_FragColor = vec4(vec3(drawMatte), 1.0);
    } else {
        gl_FragColor = vec4(outColor, bg.a);
    }
}
