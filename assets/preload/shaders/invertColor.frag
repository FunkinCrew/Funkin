#pragma header

// The invert blend mode inverts each pixel's color.

void main() {
	// Get the texture to apply to.
	vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

	if (color.a == 1.0) {
		color.r = 1.0 - color.r;
		color.g = 1.0 - color.g;
		color.b = 1.0 - color.b;
	} else if (color.a > 0.0) {
		// TODO: Figure out why alpha is set to 1.0 when other color channels are set.
	}

  // Return the value.
	gl_FragColor = color;
}