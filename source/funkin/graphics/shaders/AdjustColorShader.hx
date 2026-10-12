package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;
import flixel.math.FlxAngle;

/**
 * This shader is a recreation of Adobe Animate/Flash's "Adjust Color" filter.
 * Originally written by Rozebud https://github.com/ThatRozebudDude
 *
 * Adapted from Andrey-Postelzhuks shader found here: https://forum.unity.com/threads/hue-saturation-brightness-contrast-shader.260649/
 * Hue rotation stuff is from here: https://www.w3.org/TR/filter-effects/#feColorMatrixElement
 */
class AdjustColorShader extends FlxRuntimeShader
{
  /**
   * The hue adjustment.
   */
  public var hue(default, set):Float = 0;

  function set_hue(val:Float):Float
  {
    hue = val;

    hueMatrix = makeHueMatrix(val * FlxAngle.TO_RAD);

    updateFinalMatrix();
    return val;
  }

  /**
   * The saturation adjustment.
   */
  public var saturation(default, set):Float = 0;

  function set_saturation(val:Float):Float
  {
    saturation = val;

    if (val > 0) val *= 3;
    val = 1 + (val / 100);

    saturationMatrix = makeSaturationMatrix(val);

    updateFinalMatrix();
    return val;
  }

  /**
   * The brightness adjustment.
   */
  public var brightness(default, set):Float = 0;

  function set_brightness(val:Float):Float
  {
    brightness = val;

    this.setFloat('brightness', val / 255);
    return val;
  }

  /**
   * The contrast adjustment.
   */
  public var contrast(default, set):Float = 0;

  function set_contrast(val:Float):Float
  {
    var e:Float = 2.718281828459045;

    contrast = val;

    val = 1 + (val / 100);
    if (val > 1.0)
    {
      val = (((0.00852259 * Math.pow(e, 4.76454 * (val - 1.0))) * 1.01) - 0.0086078159) * 10.0; // Just roll with it...
      val += 1.0;
    }

    this.setFloat('contrast', val);
    return val;
  }

  var hueMatrix:Array<Float>;
  var saturationMatrix:Array<Float>;

  public function new()
  {
    super(Assets.getText(Paths.frag('adjustColor')));
    hue = 0;
    saturation = 0;
    brightness = 0;
    contrast = 0;
  }

  function updateFinalMatrix():Void
  {
    if (hueMatrix != null)
    {
      this.setFloatArray('hueMatrix', hueMatrix);
    }

    if (saturationMatrix != null)
    {
      this.setFloatArray('saturationMatrix', saturationMatrix);
    }
  }

  function makeHueMatrix(h:Float):Array<Float>
  {
    var c = Math.cos(h);
    var s = Math.sin(h);

    var wR = 0.299;
    var wG = 0.587;
    var wB = 0.114;

    return [
      wR + (1 - wR) * c - wR * s,          wG - wG * c - wG * s, wB - wB * c + (1 - wB) * s,
         wR - wR * c + 0.143 * s, wG + (1 - wG) * c + 0.140 * s,    wB - wB * c - 0.283 * s,
      wR - wR * c - (1 - wR) * s,          wG - wG * c + wG * s, wB + (1 - wB) * c + wB * s
    ];
  }

  function makeSaturationMatrix(s:Float):Array<Float>
  {
    var lr = 0.2126;
    var lg = 0.7152;
    var lb = 0.0722;

    var inv = 1.0 - s;

    return [
      lr * inv + s,     lg * inv,   lb * inv,
          lr * inv, lg * inv + s,   lb * inv,
          lr * inv,     lg * inv, lb * inv + s
    ];
  }

  public override function toString():String
  {
    return 'AdjustColorShader(${this.hue}, ${this.saturation}, ${this.brightness}, ${this.contrast})';
  }
}
