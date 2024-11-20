#pragma header

		// Modified version of a tilt shift shader from Martin Jonasson (http://grapefrukt.com/)
		// Read http://notes.underscorediscovery.com/ for context on shaders and this file
		// License : MIT

			/*
				Take note that blurring in a single pass (the two for loops below) is more expensive than separating
				the x and the y blur into different passes. This was used where bleeding edge performance
				was not crucial and is to illustrate a point.

				The reason two passes is cheaper?
				   texture2D is a fairly high cost call, sampling a texture.

				   So, in a single pass, like below, there are 3 steps, per x and y.

				   That means a total of 9 "taps", it touches the texture to sample 9 times.

				   Now imagine we apply this to some geometry, that is equal to 16 pixels on screen (tiny)
				   (16 * 16) * 9 = 2304 samples taken, for width * height number of pixels, * 9 taps
				   Now, if you split them up, it becomes 3 for x, and 3 for y, a total of 6 taps
				   (16 * 16) * 6 = 1536 samples

				   That\'s on a *tiny* sprite, let\'s scale that up to 128x128 sprite...
				   (128 * 128) * 9 = 147,456
				   (128 * 128) * 6 =  98,304

				   That\'s 33.33..% cheaper for splitting them up.
				   That\'s with 3 steps, with higher steps (more taps per pass...)

				   A really smooth, 6 steps, 6*6 = 36 taps for one pass, 12 taps for two pass
				   You will notice, the curve is not linear, at 12 steps it\'s 144 vs 24 taps
				   It becomes orders of magnitude slower to do single pass!
				   Therefore, you split them up into two passes, one for x, one for y.
			*/

		// I am hardcoding the constants like a jerk

		const float bluramount  = 1.0;
		const float center      = 1.0;
		const float stepSize    = 0.004;
		const float steps       = 3.0;

		const float minOffs     = (float(steps-1.0)) / -2.0;
		const float maxOffs     = (float(steps-1.0)) / +2.0;


		vec4 blur9(sampler2D image, vec2 uv, vec2 resolution, vec2 direction) {

      vec4 color = vec4(0.0);
			vec2 off1 = vec2(1.3846153846) * direction;
			vec2 off2 = vec2(3.2307692308) * direction;
			color += texture2D(image, uv) * 0.2270270270;
			color += texture2D(image, uv + (off1 / resolution)) * 0.3162162162;
			color += texture2D(image, uv - (off1 / resolution)) * 0.3162162162;
			color += texture2D(image, uv + (off2 / resolution)) * 0.0702702703;
			color += texture2D(image, uv - (off2 / resolution)) * 0.0702702703;
			return color;
		}

		vec4 blur13(sampler2D image, vec2 uv, vec2 resolution, vec2 direction) {
			vec4 color = vec4(0.0);
			vec2 off1 = vec2(1.411764705882353) * direction;
			vec2 off2 = vec2(3.2941176470588234) * direction;
			vec2 off3 = vec2(5.176470588235294) * direction;
			color += texture2D(image, uv) * 0.1964825501511404;
			color += texture2D(image, uv + (off1 / resolution)) * 0.2969069646728344;
			color += texture2D(image, uv - (off1 / resolution)) * 0.2969069646728344;
			color += texture2D(image, uv + (off2 / resolution)) * 0.09447039785044732;
			color += texture2D(image, uv - (off2 / resolution)) * 0.09447039785044732;
			color += texture2D(image, uv + (off3 / resolution)) * 0.010381362401148057;
			color += texture2D(image, uv - (off3 / resolution)) * 0.010381362401148057;
			return color;
		}

    uniform float _amount;

		void main()
    {

			vec4 blurred;


			vec4 blurredShit = blur13(bitmap, openfl_TextureCoordv, openfl_TextureSize.xy, vec2(0.0, _amount * 2.0));
			blurredShit = mix(blur13(bitmap, openfl_TextureCoordv, openfl_TextureSize.xy, vec2(_amount * 2.0, 0.0)), blurredShit, 0.5);

			// Work out how much to blur based on the mid point
			// _amount = pow((openfl_TextureCoordv.y * center) * 2.0 - 1.0, 2.0) * bluramount;

			// This is the accumulation of color from the surrounding pixels in the texture
			blurred = vec4(0.0, 0.0, 0.0, 1.0);

			// From minimum offset to maximum offset
			for (float offsX = minOffs; offsX <= maxOffs; ++offsX) {
				for (float offsY = minOffs; offsY <= maxOffs; ++offsY) {

					// copy the coord so we can mess with it
					vec2 temp_tcoord = openfl_TextureCoordv.xy;

					//work out which uv we want to sample now
					temp_tcoord.x += offsX * _amount * stepSize;
					temp_tcoord.y += offsY * _amount * stepSize;

					// accumulate the sample
					blurred += texture2D(bitmap, temp_tcoord);
				}
			}

			// because we are doing an average, we divide by the amount (x AND y, hence steps * steps)
			blurred /= float(steps * steps);

			// return the final blurred color
			gl_FragColor = blurredShit;
    }
