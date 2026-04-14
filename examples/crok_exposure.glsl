#version 120

uniform sampler2D source;
uniform float expo_o, expo_r, expo_g, expo_b;
uniform float contrast_r, contrast_g, contrast_b;
uniform float pivot_r, pivot_g, pivot_b;
uniform float contrast_all, pivot_all;
uniform float sat_gregPhase;
uniform int encoding;

float ga = 17.5;
float br = 1.74;

// contrast by  Miles
vec3 adjust_contrast(vec3 col, vec4 con, vec4 piv)
{
	vec3 c = con.rgb * vec3(con.a);
	vec3 a_pivot = piv.rgb * vec3(piv.a);
	col = (1.0 - c.rgb) * a_pivot + c.rgb * col;
	return col;
}

// Algorithm from Chapter 16 of OpenGL Shading Language
vec3 saturation(vec3 rgb, float adjustment)
{
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}

// rec709 conversion routine by Miles
vec3 from_rec709(vec3 col)
{
	if (col.r < .081) {
		col.r /= 4.5;
	} else {
		col.r = pow((col.r +.099)/ 1.099, 1 / .45);
	}
	if (col.g < .081) {
		col.g /= 4.5;
	} else {
		col.g = pow((col.g +.099)/ 1.099, 1 / .45);
	}
	if (col.b < .081) {
		col.b /= 4.5;
	} else {
		col.b = pow((col.b +.099)/ 1.099, 1 / .45);
	}
	return col;
}

vec3 to_rec709(vec3 col)
{
    if (col.r < .018) {
        col.r *= 4.5;
    } else if (col.r >= 0.0) {
        col.r = (1.099 * pow(col.r, .45)) - .099;
    }
    if (col.g < .018) {
        col.g *= 4.5;
    } else if (col.g >= 0.0) {
        col.g = (1.099 * pow(col.g, .45)) - .099;
    }
    if (col.b < .018) {
        col.b *= 4.5;
    } else if (col.b >= 0.0) {
        col.b = (1.099 * pow(col.b, .45)) - .099;
    }
    return col;
}

vec3 from_log(vec3 col)
{
	if (col.r >= 0.0) {
		col.r = pow((col.r + br), ga);
	}
	if (col.g >= 0.0) {
		col.g = pow((col.g + br), ga);
	}
	if (col.b >= 0.0) {
		col.b = pow((col.b + br), ga);
	}
	return col;
}

vec3 to_log(vec3 col)
{
    if (col.r >= 0.0) {
    	col.r = (pow(col.r, 1.0 / ga)) - br;
	}
    if (col.g >= 0.0) {
    	col.g = (pow(col.g, 1.0 / ga)) - br;
	}
    if (col.b >= 0.0) {
    	col.b = (pow(col.b, 1.0 / ga)) - br;
	}
    return col;
}

void main (void)
{
  vec2 uv = gl_TexCoord[0].xy;
	vec3 col = texture2D(source, uv).rgb;
	vec3 contrast = vec3(contrast_r, contrast_g, contrast_b);
	vec3 c_pivot = vec3(pivot_r, pivot_g, pivot_b);

	// Scene linear exposure
	if ( encoding == 0 )
	{
		// contrast stuff by Miles
		col = adjust_contrast(col, vec4(contrast, contrast_all), vec4(c_pivot, pivot_all));
		// overall exposure adjustemnt
		col = col * pow(2.0, expo_o);
		// single rgb exposure adjustment
		col.r = col.r * pow(2.0, expo_r);
		col.g = col.g * pow(2.0, expo_g);
		col.b = col.b * pow(2.0, expo_b);
		// desaturation Greg-Paul style
		col = saturation(col, 1.0 - expo_o * 0.01 * sat_gregPhase);
}

	// video  / Rec 709 exposure
	if ( encoding == 1)
	{
		col = from_rec709(col);
		// contrast stuff by Miles
		col = adjust_contrast(col, vec4(contrast, contrast_all), vec4(c_pivot, pivot_all));
		// overall exposure adjustemnt
		col = col * pow(2.0, expo_o);
		// single rgb exposure adjustment
		col.r = col.r * pow(2.0, expo_r);
		col.g = col.g * pow(2.0, expo_g);
		col.b = col.b * pow(2.0, expo_b);
		// desaturation Greg-Paul style
		col = saturation(col, 1.0 - expo_o * 0.01 * sat_gregPhase);
		col = to_rec709(col);
	}

	// Logarithmic exposure
	if ( encoding == 2)
	{
		col = from_log(col);
		// overall exposure adjustemnt
		col = col * pow(2.0, expo_o);
		// single rgb exposure adjustment
		col.r = col.r * pow(2.0, expo_r);
		col.g = col.g * pow(2.0, expo_g);
		col.b = col.b * pow(2.0, expo_b);
		// desaturation Greg-Paul style
		col = saturation(col, 1.0 - expo_o * 0.01 * sat_gregPhase);
		col = to_log(col);
		// contrast stuff by Miles
		col = adjust_contrast(col, vec4(contrast, contrast_all), vec4(c_pivot, pivot_all));
	}

	gl_FragColor = vec4(col, 1.0);
}
