#pragma header

// Value from (0, 1)
uniform float _amount;

// Converts the input image to grayscale, with `_amount` representing the proportion of the conversion.

// See https://drafts.fxtf.org/filter-effects/#grayscaleEquivalent
vec4 to_grayscale(vec4 input_rgba) {
    float red = (0.2126 + 0.7874 * (1.0 - _amount)) * input_rgba.r + (0.7152 - 0.7152  * (1.0 - _amount)) * input_rgba.g + (0.0722 - 0.0722 * (1.0 - _amount)) * input_rgba.b;
    float green = (0.2126 - 0.2126 * (1.0 - _amount)) * input_rgba.r + (0.7152 + 0.2848  * (1.0 - _amount)) * input_rgba.g + (0.0722 - 0.0722 * (1.0 - _amount)) * input_rgba.b;
    float blue = (0.2126 - 0.2126 * (1.0 - _amount)) * input_rgba.r + (0.7152 - 0.7152  * (1.0 - _amount)) * input_rgba.g + (0.0722 + 0.9278 * (1.0 - _amount)) * input_rgba.b;

    return vec4(red, green, blue, input_rgba.a);
}

void main() {
	// Get the texture to apply to.
	vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

	// Apply the darken effect.
	color = to_grayscale(color);

    // Return the value.
	gl_FragColor = color;
}
