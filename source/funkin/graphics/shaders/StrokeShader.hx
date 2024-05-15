package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

class StrokeShader extends FlxShader
{
  // MOSTLY STOLEN FROM AUSTIN EAST LOL!
  // https://gist.github.com/AustinEast/d3892fdf6a6079366fffde071f0c2bae
  public var width(default, set):Float = 0;
  public var height(default, set):Float = 0;

  public var col(default, set):FlxColor = 0xFFFFFFFF;

  function set_width(val):Float
  {
    size.value = [val, height];

    return val;
  }

  function set_height(val):Float
  {
    size.value = [width, val];
    return val;
  }

  function set_col(val:FlxColor):FlxColor
  {
    color.value = [val.red, val.green, val.blue, val.alpha];

    return val;
  }

  @:glFragmentSource('
        #pragma header

        uniform vec2 size;
        uniform vec4 color;

        void main()
        {
            vec4 gay = flixel_texture2D(bitmap, openfl_TextureCoordv);
            if (gay.a == 0.) {
                float w = size.x / openfl_TextureSize.x;
                float h = size.y / openfl_TextureSize.y;

                if (flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x + w, openfl_TextureCoordv.y)).a != 0.
                || flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x - w, openfl_TextureCoordv.y)).a != 0.
                || flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y + h)).a != 0.
                || flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y - h)).a != 0.)
                    gay = color;
            }
            gl_FragColor = gay;
        }
    ')
  public function new(color:FlxColor = 0xFFFFFFFF, width:Float = 1, height:Float = 1)
  {
    super();

    col = color;
    this.width = width;
    this.height = height;
  }
}
