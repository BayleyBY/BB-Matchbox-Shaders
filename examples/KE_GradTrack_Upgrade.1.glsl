// KE Gradient Tracker v.5
// Created by Ted Stanley (KuleshovEffect) August 2024
// Based on code from:
// Ivar's crok_gradient https://logik-matchbook.org/shader/crok_gradient
// Ivar's crok_gradient is based on https://www.shadertoy.com/view/ltjXDt by anastadunbar
// Tsoding's Straight Lines https://www.youtube.com/watch?v=cU5WcrU_YI4 + https://www.shadertoy.com/view/fst3DH
// Autodesks's PyramidBlur Example
// And of course, ChatGPT

uniform sampler2D front, matte;
uniform float adsk_result_w, adsk_result_h, adsk_result_pixelratio;
uniform vec2 point1Track, point2Track, point3Track, point4Track, point1AdjustIcon, point2AdjustIcon, point3AdjustIcon, point4AdjustIcon;
uniform float blurAmount, bias_adj;
//uniform bool overlay;
uniform int outputType, gradNo, gradType;
//int gradType = 2;
// The UI width is based on the frame size
float width = adsk_result_h / 200.0;

// Set Adjustment Defaults to agree with defaults in XML
vec2 point1AdjustDefault = vec2(.3, .3);
vec2 point2AdjustDefault = vec2(.7, .3);
vec2 point3AdjustDefault = vec2(.3, .7);
vec2 point4AdjustDefault = vec2(.7, .7);

#define PI 3.141592653589793238462

//Return a color for a given point, blurred by the blurAmount
vec3 get_color(vec2 pos)
{
    int intPart = int( blurAmount );
    
    if (intPart < 1)
        // There's no blur, so return the color
        return vec3(texture2D(front, pos).rgb);

    // Stolen from Autodesk's PyramidBlur
    vec3 accu = vec3(0.0);
    float energy = 0.0;
    vec3 endColor = vec3(0.0);
   
    for( int x = -intPart; x <= intPart; x++)
    {
        vec2 currentCoord = vec2(pos.x+float(x)/adsk_result_w, pos.y);
        vec3 aSample = texture2D(front, currentCoord).rgb;
        float anEnergy = 1.0 - ( abs(float(x)) / blurAmount );
        energy += anEnergy;
        accu += aSample * anEnergy;
    }

    for( int y = -intPart; y <= intPart; y++)
   {
      vec2 currentCoord = vec2(pos.x, pos.y+float(y)/adsk_result_h);
      vec3 aSample = texture2D(front, currentCoord).rgb;
      float anEnergy = 1.0 - ( abs(float(y)) / blurAmount );
      energy += anEnergy;
      accu += aSample * anEnergy;
   }
   
    endColor = (accu / energy);
    return endColor;
}

vec2 get_final(vec2 pointTrack, vec2 pointAdjust)
{
    vec2 pointFinal;
    pointFinal.x = ((pointTrack.x + pointAdjust.x) + (adsk_result_w / 2.0)) / (adsk_result_w);
    pointFinal.y = ((pointTrack.y + pointAdjust.y) + (adsk_result_h / 2.0)) / (adsk_result_h);
    return pointFinal;
}

vec2 get_final_icon(vec2 pointTrack, vec2 pointAdjust, vec2 pointDefault)
{
   vec2 pointFinal;
    pointFinal.x = ((pointTrack.x) + (adsk_result_w / 2.0)) / (adsk_result_w);
    pointFinal.y = ((pointTrack.y) + (adsk_result_h / 2.0)) / (adsk_result_h);
    pointFinal += (pointAdjust - pointDefault);
    return pointFinal;
}

vec2 get_normal(vec2 pointTrack, vec2 pointAdjust)
{
    vec2 pointNormal;
    pointNormal.x = pointTrack.x + pointAdjust.x + (adsk_result_w / 2.0);
    pointNormal.y = pointTrack.y + pointAdjust.y + (adsk_result_h / 2.0);
    return pointNormal;
}

vec2 get_normal2(vec2 pointTrack, vec2 pointAdjust, vec2 pointAdjustDefault)
{
    vec2 pointNormal = pointTrack / (gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h ));
    pointNormal.x = pointTrack.x + (adsk_result_w / 2.0);
    pointNormal.y = pointTrack.y + (adsk_result_h / 2.0);
    return pointNormal;
}

vec2 get_pixeloffset(vec2 pointAdjust, vec2 pointDefault)
{
    vec2 offset = (pointAdjust - pointDefault);
    return offset * vec2(adsk_result_w, adsk_result_h);
}

vec3 draw_4grad(vec2 p1, vec2 p2, vec2 p3, vec2 p4)
{
    vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
    vec2 p[4];
    p[0] = p1;
    p[1] = p2;
    p[2] = p3;
    p[3] = p4;

    vec3 c[4];
    c[0] = get_color(p1);
    c[1] = get_color(p2);
    c[2] = get_color(p3);
    c[3] = get_color(p4);

    float blend = 2.0;

    float w[4];
    vec3 sum = vec3(0.0);
    float valence = 0.0;
    for (int i = 0; i < 4; i++) {
        float distance = length(uv - p[i]);
        if (distance == 0.0) { distance = 1.0; }
        float w =  1.0 / pow(distance, blend);
        sum += w * c[i];
        valence += w;
    }
    sum /= valence;
    
    // apply gamma 2.2 (Approx. of linear => sRGB conversion. To make perceptually linear gradient)

    sum = pow(sum, vec3(1.0/2.2));
    
    // output
    
	return vec3(sum.xyz);
}

vec3 draw_4grad2(vec2 P0, vec2 P1, vec2 P2, vec2 P3)
{
    vec3 color0 = get_color(P0);
    vec3 color1 = get_color(P1);
    vec3 color2 = get_color(P2);
    vec3 color3 = get_color(P3);

    vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );

    vec2 Q = P0 - P2;
    vec2 R = P1 - P0;
    vec2 S = R + P2 - P3;
    vec2 T = P0 - uv;

    float u;
    float t;
 
    if(Q.x == 0.0 && S.x == 0.0) {
        u = -T.x/R.x;
        t = (T.y + u*R.y) / (Q.y + u*S.y);
    } else if(Q.y == 0.0 && S.y == 0.0) {
        u = -T.y/R.y;
        t = (T.x + u*R.x) / (Q.x + u*S.x);
    } else {
        float A = S.x * R.y - R.x * S.y;
        float B = S.x * T.y - T.x * S.y + Q.x*R.y - R.x*Q.y;
        float C = Q.x * T.y - T.x * Q.y;
        // Solve Au^2 + Bu + C = 0
        if(abs(A) < 0.0001)
            u = -C/B;
        else
        u = (-B+sqrt(B*B-4.0*A*C))/(2.0*A);
        t = (T.y + u*R.y) / (Q.y + u*S.y);
    }
    u = clamp(u,0.0,1.0);
    t = clamp(t,0.0,1.0);
 
    // These two lines smooth out t and u to avoid visual 'lines' at the boundaries.  They can be removed to improve performance at the cost of graphics quality.
    t = smoothstep(0.0, 1.0, t);
    u = smoothstep(0.0, 1.0, u);
 
    vec3 colorA = mix(color0,color1,u);
    vec3 colorB = mix(color2,color3,u);
    return mix(colorA, colorB, t);
}

// The following two functions were created by ChatGPT

float calculateWeight(vec2 pos, vec2 uv) {
    return 1.0 / max(distance(pos, uv), 0.001); // Avoid division by zero
}

vec3 draw_4grad3(vec2 P0, vec2 P1, vec2 P2, vec2 P3)
{
    vec3 color0 = get_color(P0);
    vec3 color1 = get_color(P1);
    vec3 color2 = get_color(P2);
    vec3 color3 = get_color(P3);

    vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );

    float weight0 = calculateWeight(P0, uv);
    float weight1 = calculateWeight(P1, uv);
    float weight2 = calculateWeight(P2, uv);
    float weight3 = calculateWeight(P3, uv);

    float totalWeight = weight0 + weight1 + weight2 + weight3;

    vec3 finalColor = (weight0 * color0 + weight1 * color1 + weight2 * color2 + weight3 * color3) / totalWeight;

    return finalColor;
}


// Stolen from anastadunbar's Shadertoy
float gradient_linear2(vec2 uv, vec2 p1, vec2 p2)
{
    return clamp(dot(uv-p1,p2-p1)/dot(p2-p1,p2-p1),0.,1.);
}

// Stolen from Ivar's crok_gradient
float bias(float x, float b)
{
    b = -log2(1.0 - b);
    return 1.0 - pow(1.0 - pow(x, 1./b), b);
}

void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 coords = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
	vec3 frontpix = texture2D(front, coords).rgb;
    float mattepix = texture2D(matte, coords).r;
    vec2 point1Final, point2Final, point3Final, point4Final;
    
    // Get the Start and End coordinates from the user, add in the offset
    //point1Final = get_final(point1Track, point1Adjust);
    //point2Final = get_final(point2Track, point2Adjust);

    point1Final = get_final_icon(point1Track, point1AdjustIcon, point1AdjustDefault);
    point2Final = get_final_icon(point2Track, point2AdjustIcon, point2AdjustDefault);

    //point1Final = get_final(point1Track, vec2(0,0));
    //point2Final = get_final(point2Track, vec2(0.0));

    if (gradNo == 1)
    {
        point3Final = get_final_icon(point3Track, point3AdjustIcon, point3AdjustDefault);
        point4Final = get_final_icon(point4Track, point4AdjustIcon, point4AdjustDefault);
    }

    vec3 finalColor = vec3(0.0);
    vec3 point1Color = vec3(0.0);
    vec3 point2Color = vec3(0.0);

   
    // Get the colors for the two points
    point1Color = get_color(point1Final);
    point2Color = get_color(point2Final);

    if (gradNo == 1)
    {
        vec3 point3Color = get_color(point3Final);
        vec3 point4Color = get_color(point4Final);
    }
 
    // Stolen from Ivar's crok_gradient
    float drawing = 0.;
    drawing = gradient_linear2(coords,point1Final,point2Final);
    drawing = clamp(drawing, 0.0, 1.0);
    drawing = bias(drawing, bias_adj);
    finalColor = vec3(drawing * point2Color + (1.0 - drawing) * point1Color);
    
    // Output Ty[e is 'UI Overlay' and 2 Point
    if (outputType == 0 && gradNo == 0)
    {
        // Output the front image, unless there should be some UI elements instead
        finalColor = frontpix;
        vec2 startOffset, endOffset;

        // The line drawing function I stole works in screen space, not UV space

        // Move Adjust value to pixels, in terms of distance from default
        vec2 point1Adjust = vec2(((point1AdjustIcon.x - point1AdjustDefault.x) * adsk_result_w), ((point1AdjustIcon.y - point1AdjustDefault.y) * adsk_result_h));
        vec2 point2Adjust = vec2(((point2AdjustIcon.x - point2AdjustDefault.x) * adsk_result_w), ((point2AdjustIcon.y - point2AdjustDefault.y) * adsk_result_h));
        
        startOffset.x = point1Track.x + point1Adjust.x + (adsk_result_w / 2.0);
        startOffset.y = point1Track.y + point1Adjust.y + (adsk_result_h / 2.0);
        endOffset.x = point2Track.x + point2Adjust.x + (adsk_result_w / 2.0);
        endOffset.y = point2Track.y + point2Adjust.y + (adsk_result_h / 2.0);

        // Stolen from Tsoding, draws the UI
        vec2 p3 = gl_FragCoord.xy;
        vec2 p12 = endOffset - startOffset;
        vec2 p13 = p3 - startOffset;

        float d = dot(p12, p13) / length(p12);
        vec2 p4 = startOffset + normalize(p12) * d;
        if (length(p4 - p3) < width
            && length(p4 - startOffset) <= length(p12)
            && length(p4 - endOffset) <= length(p12)) {
            finalColor = vec3(0.0, 1.0, 0.0);
        }

        // These two draw the UI circles
        if (length(p3 - startOffset) < width) {
        finalColor = vec3(1.0, 0.0, 0.0);
        }

        if (length(p3 - endOffset) < width) {
        finalColor = vec3(0.0, 0.0, 1.0);
        }
    }

    // Output type is 'Comp' and 2 Point
    if (outputType == 2 && gradNo == 0)
    {
        finalColor = (finalColor * mattepix) + (frontpix * (1.0 - mattepix));
    }

    // Output type is 'UI' and 4 Point
    if (outputType == 0 && gradNo == 1)
    {
        finalColor = frontpix;
        vec2 res = vec2(adsk_result_w, adsk_result_h);
        if (length(gl_FragCoord.xy - (point1Track + get_pixeloffset(point1AdjustIcon, point1AdjustDefault) + res/2)) < width)
        {
            finalColor = vec3(1.0, 0.0, 0.0);
        }
        if (length(gl_FragCoord.xy - (point2Track + get_pixeloffset(point2AdjustIcon, point2AdjustDefault) + res/2)) < width)
        {
            finalColor = vec3(0.0, 0.0, 1.0);
        }
        if (length(gl_FragCoord.xy - (point3Track + get_pixeloffset(point3AdjustIcon, point3AdjustDefault) + res/2)) < width)
        {
            finalColor = vec3(1.0, 1.0, 0.0);
        }
        if (length(gl_FragCoord.xy - (point4Track + get_pixeloffset(point4AdjustIcon, point4AdjustDefault) + res/2)) < width)
        {
            finalColor = vec3(1.0, 0.0, 1.0);
        }
    }

    // Output type is 'Grad' and 4 Point
    if (outputType == 1 && gradNo == 1)
    {
        if (gradType == 0)
            {finalColor = draw_4grad(point1Final, point2Final, point3Final, point4Final);}
        if (gradType == 1)
            {finalColor = draw_4grad2(point1Final, point2Final, point3Final, point4Final);}
        if (gradType == 2)
            {finalColor = draw_4grad3(point1Final, point2Final, point3Final, point4Final);}
    }

    // Output type is 'Comp' and 4 Point
    if (outputType == 2 && gradNo == 1)
    {
        if (gradType == 0)
            {finalColor = draw_4grad(point1Final, point2Final, point3Final, point4Final);}
        if (gradType == 1)
            {finalColor = draw_4grad2(point1Final, point2Final, point3Final, point4Final);}
        if (gradType == 2)
            {finalColor = draw_4grad3(point1Final, point2Final, point3Final, point4Final);}
        finalColor = (finalColor * mattepix) + (frontpix * (1.0 - mattepix));
    }

    gl_FragColor = vec4(finalColor, drawing);
}