package openfl8.blends;

import flixel.system.FlxAssets.FlxShader;

class LightenShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		uniform vec4 uBlendColor;

		vec4 blendLighten(vec4 base, vec4 blend)
		{
			return max(blend, base);
		}

		vec4 blendLighten(vec4 base, vec4 blend, float opacity)
		{
			return (blendLighten(base, blend) * opacity + base * (1.0 - opacity));
		}

		void main()
		{
			vec4 base = texture2D(bitmap, openfl_TextureCoordv);
			gl_FragColor = blendLighten(base, uBlendColor, uBlendColor.a);
		}')
	public function new()
	{
		super();
	}
}
