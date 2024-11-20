#pragma header

uniform sampler2D source;
uniform int blendMode;

const int DARKEN = 2;
const int HARDLIGHT = 5;
const int LIGHTEN = 8;
const int OVERLAY = 11;

vec3 screen(vec3 bg, vec3 src) {
	return 1.0 - (1.0 - bg) * (1.0 - src);
}

vec3 hardlight(vec3 bg, vec3 src) {
	vec3 c1 = bg * src * 2.0;
	vec3 c2 = screen(bg, 2.0 * src - 1.0);
	return mix(c2, c1, vec3(lessThanEqual(src, vec3(0.5))));
}

vec3 overlay(vec3 bg, vec3 src) {
	return hardlight(src, bg);
}

vec3 blend(vec3 bg, vec3 src) {
	if (blendMode == DARKEN) {
		return min(bg, src);
	} else if (blendMode == HARDLIGHT) {
		return hardlight(bg, src);
	} else if (blendMode == LIGHTEN) {
		return max(bg, src);
	} else if (blendMode == OVERLAY) {
		return overlay(bg, src);
	} else {
		return vec3(1, 0, 1); // not supported
	}
}

void main() {
	vec4 bg = sampleBitmapScreen(screenCoord);
	vec4 src = texture2D(source, screenCoord);
	vec3 res = blend(bg.rgb, src.rgb);
	gl_FragColor = vec4(mix(bg.rgb, res.rgb, src.a), mix(bg.a, 1.0, src.a));
}
