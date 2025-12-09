package funkin.graphics.shaders;

import flixel.util.FlxColor;
import openfl.display.ShaderParameter;

typedef BlendModeShader =
{
  var uBlendColor:ShaderParameter<Float>;
}

@:nullSafety
class BlendModeEffect
{
  public var shader(default, null):BlendModeShader;

  @:isVar
  public var color(default, set):FlxColor = new FlxColor();

  public function new(shader:BlendModeShader, color:FlxColor):Void
  {
    shader.uBlendColor.value = [];
    this.shader = shader;
    this.color = color;
  }

  function set_color(color:FlxColor):FlxColor
  {
    shader.uBlendColor.value[0] = color.redFloat;
    shader.uBlendColor.value[1] = color.greenFloat;
    shader.uBlendColor.value[2] = color.blueFloat;
    shader.uBlendColor.value[3] = color.alphaFloat;

    return this.color = color;
  }
}
