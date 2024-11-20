#pragma header

// Rather than invert the entire color, we invert a sorta dots / dither pattern
// Inspiration from when an object in Adobe Flash is selected

uniform float _amount;

void main() {
	gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
	if (_amount <= 0.0) {return;}
	vec2 texel = floor(mod(openfl_TextureCoordv * openfl_TextureSize, 4.0));
	if (gl_FragColor.a > 0.0 && texel.x == texel.y && mod(texel.x, 2.0) == 0.0) {
		gl_FragColor.rgb -= (2.0 * gl_FragColor.rgb - 1.0) * min(_amount, 1.0);
	}
}
