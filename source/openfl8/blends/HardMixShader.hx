package openfl8.blends;

import flixel.system.FlxAssets.FlxShader;

class HardMixShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		uniform vec4 uBlendColor;

		float blendColorDodge(float base, float blend)
		{
			return (blend == 1.0)
				? blend
				: min(base / (1.0 - blend), 1.0);
		}

		float blendColorBurn(float base, float blend)
		{
			return (blend == 0.0)
				? blend
				: max((1.0 - ((1.0 - base) / blend)), 0.0);
		}

		float blendVividLight(float base, float blend)
		{
			return (blend < 0.5)
				? blendColorBurn(base, (2.0 * blend))
				: blendColorDodge(base, (2.0 * (blend - 0.5)));
		}

		float blendHardMix(float base, float blend)
		{
			return (blendVividLight(base, blend) < 0.5)
				? 0.0
				: 1.0;
		}

		vec4 blendHardMix(vec4 base, vec4 blend)
		{
			return vec4(
				blendHardMix(base.r, blend.r),
				blendHardMix(base.g, blend.g),
				blendHardMix(base.b, blend.b),
				blendHardMix(base.a, blend.a)
			);
		}

		vec4 blendHardMix(vec4 base, vec4 blend, float opacity)
		{
			return (blendHardMix(base, blend) * opacity + base * (1.0 - opacity));
		}

		void main()
		{
			vec4 blend = texture2D(bitmap, openfl_TextureCoordv);
			vec4 res = blendHardMix(uBlendColor, blend);

			gl_FragColor = blendHardMix(blend, res, uBlendColor[3]);
		}')
	public function new()
	{
		super();
	}
}
