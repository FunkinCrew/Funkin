package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

class PureColor extends FlxShader
{
  public var col(default, set):FlxColor;
  public var colorSet(default, set):Bool;

  function set_colorSet(bol:Bool):Bool
  {
    colSet.value = [bol];

    return bol;
  }

  function set_col(val:FlxColor):FlxColor
  {
    funnyColor.value = [val.red, val.green, val.blue, val.alpha];

    return val;
  }

  @:glFragmentSource('
        #pragma header

        uniform vec4 funnyColor;
        uniform bool colSet;

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

            if (color.a > 0.0 && colSet)
                color = vec4(funnyColor.r, funnyColor.g, funnyColor.b, color.a);

            gl_FragColor = color;
        }
    ')
  public function new(colr:FlxColor)
  {
    super();

    this.col = colr;
    this.colorSet = false;
  }
}
