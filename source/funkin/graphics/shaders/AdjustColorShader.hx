package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;

@:nullSafety
class AdjustColorShader extends FlxRuntimeShader
{
  public var hue(default, set):Float = 0;
  public var saturation(default, set):Float = 0;
  public var brightness(default, set):Float = 0;
  public var contrast(default, set):Float = 0;

  public function new()
  {
    super(Assets.getText(Paths.frag('adjustColor')));
    // FlxG.debugger.addTrackerProfile(new TrackerProfile(HSVShader, ['hue', 'saturation', 'brightness', 'contrast']));
    hue = 0;
    saturation = 0;
    brightness = 0;
    contrast = 0;
  }

  function set_hue(value:Float):Float
  {
    this.setFloat('hue', value);
    this.hue = value;

    return this.hue;
  }

  function set_saturation(value:Float):Float
  {
    this.setFloat('saturation', value);
    this.saturation = value;

    return this.saturation;
  }

  function set_brightness(value:Float):Float
  {
    this.setFloat('brightness', value);
    this.brightness = value;

    return this.brightness;
  }

  function set_contrast(value:Float):Float
  {
    this.setFloat('contrast', value);
    this.contrast = value;

    return this.contrast;
  }

  public override function toString():String
  {
    return 'AdjustColorShader(${this.hue}, ${this.saturation}, ${this.brightness}, ${this.contrast})';
  }
}
