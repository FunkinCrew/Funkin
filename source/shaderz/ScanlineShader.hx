package shaders;

import flixel.system.FlxAssets.FlxShader;

class ScanlineShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		const float scale = 1.0;

		void main()
		{
			if (mod(floor(openfl_TextureCoordv.y * openfl_TextureSize.y / scale), 2.0) == 0.0)
				gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
			else
				gl_FragColor = texture2D(bitmap, openfl_TextureCoordv);
		}')

	public function new()
	{
		super();
	}
}