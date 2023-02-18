package;

import flixel.system.FlxAssets.FlxShader;

class OverlayShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		uniform vec4 uBlendColor;

		vec3 blendLighten(base:Vec3, blend:Vec3) : Vec3 {
			return mix(
				1.0 - 2.0 * (1.0 - base) * (1.0 - blend),
				2.0 * base * blend,
				step( base, vec3(0.5) )
			);
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
