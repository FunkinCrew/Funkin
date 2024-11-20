#pragma header

uniform float colorAlpha;
uniform float colorRed;
uniform float colorGreen;
uniform float colorBlue;

// The subtract blend mode subtracts the source and destination colors.

void main() {
	// Get the texture to apply to.
	vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

	// Apply the subtract effect.
	color.a -= colorAlpha;
	color.r -= colorRed;
	color.g -= colorGreen;
	color.b -= colorBlue;

	// Cap the color values.
	color = max(color, vec4(0.0, 0.0, 0.0, 0.0));

  // Return the value.
	gl_FragColor = color;
}