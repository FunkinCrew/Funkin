package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

class TextureSwap extends FlxShader
{
  public var swappedImage(default, set):BitmapData;
  public var amount(default, set):Float;

  function set_swappedImage(_bitmapData:BitmapData):BitmapData
  {
    image.input = _bitmapData;

    return _bitmapData;
  }

  function set_amount(val:Float):Float
  {
    fadeAmount.value = [val];

    return val;
  }

  @:glFragmentSource('
        #pragma header

        uniform sampler2D image;
        uniform float fadeAmount;

        void main()
        {
            vec4 tex = flixel_texture2D(bitmap, openfl_TextureCoordv);
            vec4 tex2 = flixel_texture2D(image, openfl_TextureCoordv);

            vec4 finalColor = mix(tex, vec4(tex2.rgb, tex.a), fadeAmount);

            gl_FragColor = finalColor;
        }
    ')
  public function new()
  {
    super();

    this.amount = 1;
  }
}
