#pragma header

uniform float colorAlpha;
uniform float colorRed;
uniform float colorGreen;
uniform float colorBlue;

// The multiply blend mode multiplies the source and destination colors.

void main() {
	// Get the texture to apply to.
	vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

	// Apply the multiply effect.
	color.a *= colorAlpha;
	color.r *= colorRed;
	color.g *= colorGreen;
	color.b *= colorBlue;

  // Return the value.
	gl_FragColor = color;
}