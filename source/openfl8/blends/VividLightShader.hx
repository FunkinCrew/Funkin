package openfl8.blends;

import flixel.system.FlxAssets.FlxShader;

class VividLightShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		uniform vec4 uBlendColor;

		float colorDodge(float base, float blend)
		{
			return (blend == 1.0) ? blend : min(base / (1.0 - blend), 1.0);
		}

		float colorBurn(float base, float blend)
		{
			return (blend == 0.0) ? blend : max((1.0 - ((1.0 - base) / blend)), 0.0);
		}

		float vividLight(float base, float blend)
		{
			return ((blend < 0.5) ? colorBurn(base, (2.0 * blend)) : colorDodge(base, (2.0 * (blend - 0.5))));
		}

		vec4 vividLight(vec4 base, vec4 blend)
		{
			return vec4(
				vividLight(base.r, blend.r),
				vividLight(base.g, blend.g),
				vividLight(base.b, blend.b),
				vividLight(base.a, blend.a)
			);
		}

		vec4 vividLight(vec4 base, vec4 blend, float opacity)
		{
			return (vividLight(base, blend) * opacity + base * (1.0 - opacity));
		}

		void main()
		{
			vec4 base = texture2D(bitmap, openfl_TextureCoordv);
			gl_FragColor = vividLight(base, uBlendColor, uBlendColor[3]);
		}')
	public function new()
	{
		super();
	}
}
