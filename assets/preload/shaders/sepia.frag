#pragma header

// Value from (0, 1)
uniform float amount;

// Converts the input image to sepia, with `amount` representing the proportion of the conversion.

// See https://drafts.fxtf.org/filter-effects/#sepiaEquivalent
vec4 to_sepia(vec4 input_rgba) {
    float red = (0.393 + 0.607 * (1.0 - amount)) * input_rgba.r + (0.769 - 0.769 * (1.0 - amount)) * input_rgba.g + (0.189 - 0.189 * (1.0 - amount)) * input_rgba.b;
    float green = (0.349 - 0.349 * (1.0 - amount)) * input_rgba.r + (0.686 + 0.314 * (1.0 - amount)) * input_rgba.g + (0.168 - 0.168 * (1.0 - amount)) * input_rgba.b;
    float blue = (0.272 - 0.272 * (1.0 - amount)) * input_rgba.r + (0.534 - 0.534 * (1.0 - amount)) * input_rgba.g + (0.131 + 0.869 * (1.0 - amount)) * input_rgba.b;

    return vec4(red, green, blue, input_rgba.a);
}

void main() {
	// Get the texture to apply to.
	vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

	// Apply the darken effect.
	color = to_sepia(color);

    // Return the value.
	gl_FragColor = color;
}
