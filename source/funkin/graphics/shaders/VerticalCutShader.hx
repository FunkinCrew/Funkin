package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;

/**
 * Cuts out the top or bottom half of a sprite.
 */
class VerticalCutShader extends FlxShader
{
  /**
   * The type of cut to apply.
   */
  public var cutType(default, set):VerticalCutType;

  function set_cutType(value:VerticalCutType):VerticalCutType
  {
    if (value == cutType) return value;

    cutType = value;

    switch (value)
    {
      case TOP:
        cutTop.value = [true];
      case BOTTOM:
        cutTop.value = [false];
    }

    return value;
  }

  @:glFragmentSource('
    #pragma header

    uniform bool cutTop;

    void main()
    {
      if (cutTop && openfl_TextureCoordv.y < 0.5)
      {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
      }
      else if (!cutTop && openfl_TextureCoordv.y > 0.5)
      {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
      }
      else
      {
        gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
      }
    }
')
  public function new(type:VerticalCutType)
  {
    super();

    cutType = type;
  }
}

enum VerticalCutType
{
  TOP;
  BOTTOM;
}
