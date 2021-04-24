package openfl8.blends;

import flixel.system.FlxAssets.FlxShader;

class LinearDodgeShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		uniform vec4 uBlendColor;

		// Note : Same implementation as BlendAddf
		float blendLinearDodge(float base, float blend)
		{
			return min(base + blend, 1.0);
		}

		vec4 blendLinearDodge(vec4 base, vec4 blend)
		{
			return vec4(
				blendLinearDodge(base.r, blend.r),
				blendLinearDodge(base.g, blend.g),
				blendLinearDodge(base.b, blend.b),
				blendLinearDodge(base.a, blend.a)
			);
		}

		vec4 blendLinearDodge(vec4 base, vec4 blend, float opacity)
		{
			return (blendLinearDodge(base, blend) * opacity + base * (1.0 - opacity));
		}

		void main()
		{
			vec4 base = texture2D(bitmap, openfl_TextureCoordv);
			gl_FragColor = blendLinearDodge(base, uBlendColor, uBlendColor[3]);
		}')
	public function new()
	{
		super();
	}
}
