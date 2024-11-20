#pragma header

uniform float colorAlpha;
uniform float colorRed;
uniform float colorGreen;
uniform float colorBlue;

// The add blend mode adds the source and destination colors.

void main() {
	// Get the texture to apply to.
	vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

	// Apply the add effect.
	color.a += colorAlpha;
	color.r += colorRed;
	color.g += colorGreen;
	color.b += colorBlue;

	// Cap the color values.
	color = min(color, vec4(1.0, 1.0, 1.0, 1.0));

  // Return the value.
	gl_FragColor = color;
}