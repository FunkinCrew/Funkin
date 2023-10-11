package funkin.shaderslmfao;

import flixel.addons.display.FlxRuntimeShader;
import funkin.Paths;
import openfl.utils.Assets;

class HSVShader extends FlxRuntimeShader
{
  public var hue(default, set):Float;
  public var saturation(default, set):Float;
  public var value(default, set):Float;

  public function new()
  {
    super(Assets.getText(Paths.frag('hsv')));
    hue = 1;
    saturation = 1;
    value = 1;
  }

  function set_hue(value:Float):Float
  {
    this.setFloat('hue', value);
    this.hue = value;

    return this.hue;
  }

  function set_saturation(value:Float):Float
  {
    this.setFloat('sat', value);
    this.saturation = value;

    return this.saturation;
  }

  function set_value(value:Float):Float
  {
    this.setFloat('val', value);
    this.value = value;

    return this.value;
  }
}
