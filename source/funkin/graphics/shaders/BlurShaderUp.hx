package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;

class BlurShaderUp extends FlxShader
{
  @:glFragmentSource('
    #pragma header


		uniform float offset;
		uniform float scale;

		void main()
		{
			vec2 uv = openfl_TextureCoordv / scale;
			vec2 rcp = vec2(1.0 / (openfl_TextureSize.x/scale), 1.0 / (openfl_TextureSize.y/scale));

			vec2 halfpixel = rcp * 0.5;
			vec2 o = halfpixel * (offset / scale);

			vec4 color = vec4(0.0);

			color += flixel_texture2D(bitmap, uv + vec2(-o.x * 2.0, 0.0));
			color += flixel_texture2D(bitmap, uv + vec2( o.x * 2.0, 0.0));
			color += flixel_texture2D(bitmap, uv + vec2(0.0, -o.y * 2.0));
			color += flixel_texture2D(bitmap, uv + vec2(0.0,  o.y * 2.0));

			color += flixel_texture2D(bitmap, uv + vec2(-o.x,  o.y)) * 2.0;
			color += flixel_texture2D(bitmap, uv + vec2( o.x,  o.y)) * 2.0;
			color += flixel_texture2D(bitmap, uv + vec2(-o.x, -o.y)) * 2.0;
			color += flixel_texture2D(bitmap, uv + vec2( o.x, -o.y)) * 2.0;

			gl_FragColor = color / 12.0;
		}
  ')
  public function new(_scale:Float = 1, _offset:Float = 1)
  {
    super();
    offset.value = [_offset];
    scale.value = [_scale];
  }
}

