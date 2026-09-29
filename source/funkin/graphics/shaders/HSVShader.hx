package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;

@:nullSafety
class HSVShader extends FlxRuntimeShader
{
  public var hue(default, set):Float = 1;
  public var saturation(default, set):Float = 1;
  public var value(default, set):Float = 1;

  /**
   * The shader source, read once and shared, rather than re-read for every instance.
   */
  static var fragmentSource:Null<String> = null;
  static var registeredTrackerProfile:Bool = false;

  static function getFragmentSource():String
  {
    if (fragmentSource == null) fragmentSource = Assets.getText(Paths.frag('ui/shaders/hsv'));

    return fragmentSource ?? '';
  }

  public function new(h:Float = 1, s:Float = 1, v:Float = 1)
  {
    super(getFragmentSource());

    if (!registeredTrackerProfile)
    {
      registeredTrackerProfile = true;
      FlxG.debugger.addTrackerProfile(new TrackerProfile(HSVShader, ['hue', 'saturation', 'value']));
    }

    hue = h;
    saturation = s;
    value = v;
  }

  function set_hue(value:Float):Float
  {
    this.setFloat('_hue', value);
    this.hue = value;

    return this.hue;
  }

  function set_saturation(value:Float):Float
  {
    this.setFloat('_sat', value);
    this.saturation = value;

    return this.saturation;
  }

  function set_value(value:Float):Float
  {
    this.setFloat('_val', value);
    this.value = value;

    return this.value;
  }
}
