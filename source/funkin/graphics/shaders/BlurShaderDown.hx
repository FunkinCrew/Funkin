package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;

class BlurShaderDown extends FlxShader
{
  @:glFragmentSource('
    #pragma header

    uniform float offset;
    uniform float scale;

    void main() {
      vec2 uv = openfl_TextureCoordv / scale;
      vec2 rcp = vec2(1.0 / (openfl_TextureSize.x/scale), 1.0 / (openfl_TextureSize.y/scale));

      vec2 halfpixel = rcp * 0.5;
      vec2 o = halfpixel * (offset / scale);

      vec4 color = flixel_texture2D(bitmap, uv) * 4.0;

      color += flixel_texture2D(bitmap, uv + vec2(-o.x, -o.y));
      color += flixel_texture2D(bitmap, uv + vec2( o.x, -o.y));
      color += flixel_texture2D(bitmap, uv + vec2(-o.x,  o.y));
      color += flixel_texture2D(bitmap, uv + vec2( o.x,  o.y));

      gl_FragColor = color / 8.0;
    }
  ')
  public function new(_scale:Float = 1, _offset:Float = 1)
  {
    super();
    offset.value = [_offset];
    scale.value = [_scale];
  }
}

