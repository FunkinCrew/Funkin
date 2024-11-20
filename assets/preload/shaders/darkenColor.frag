#pragma header

uniform float colorAlpha;
uniform float colorRed;
uniform float colorGreen;
uniform float colorBlue;

// The darken blend mode changes the color of the destination pixel to the darker of the two constituent colors.
// The RGB values of the provided color are compared to the RGB values of the source pixel.
// If the source pixel is darker, the destination pixel is replaced with the source pixel.
// If the source pixel is lighter, the provided color is used instead..

void main() {
	// Get the texture to apply to.
	vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

	// Apply the darken effect.
	if (color.a > colorAlpha)
		color.a = colorAlpha;
	if (color.r > colorRed)
		color.r = colorRed;
	if (color.g > colorGreen)
		color.g = colorGreen;
	if (color.b > colorBlue)
		color.b = colorBlue;

  // Return the value.
	gl_FragColor = color;
}