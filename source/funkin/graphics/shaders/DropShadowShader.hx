package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import flixel.math.FlxAngle;
import flixel.graphics.frames.FlxFrame;
import openfl.display.BitmapData;

/**
 * A shader that aims to *mostly recreate how Adobe Animate/Flash handles drop shadows, but its main use here is for rim lighting.
 *
 * Has options for color, angle, distance, and a threshold to not cast the shadow on parts like outlines.
 * Can also be supplied a secondary mask which can then have an alternate threshold, for when sprites have too many conflicting colors
 * for the drop shadow to look right (e.g. the tankmen on GF's speakers).
 *
 * Also has an Adjust Color shader in here so they can work together when needed.
 */
class DropShadowShader extends FlxRuntimeShader
{
  /**
   * The color of the drop shadow.
   */
  public var color(default, set):FlxColor;

  /**
   * The angle of the drop shadow.
   *
   * For reference, depending on the angle, the affected side will be:
   * 0 = RIGHT
   * 90 = UP
   * 180 = LEFT
   * 270 = DOWN
   */
  public var angle(default, set):Float;

  /**
   * An offset for the angle.
   * Used for rotated frames.
   */
  public var angleOffset(default, set):Float;

  /**
   * The distance or size of the drop shadow, in pixels,
   * relative to the texture itself... NOT the camera.
   */
  public var distance(default, set):Float;

  /**
   * The strength of the drop shadow.
   * Effectively just an alpha multiplier.
   */
  public var strength(default, set):Float;

  /**
   * The brightness threshold for the drop shadow.
   * Anything below this number will NOT be affected by the drop shadow shader.
   * A value of 0 effectively means theres no threshold, and vice versa.
   */
  public var threshold(default, set):Float;

  /**
   * Whether the shader should try and use the alternate mask.
   * False by default.
   */
  public var useAltMask(default, set):Bool;

  /**
   * The image for the alternate mask.
   * At the moment, it uses the blue channel to specify what is or isn't going to use the alternate threshold.
   * TODO: maybe have a sort of "threshold intensity texture" as well? where higher/lower values indicate threshold strength.
   */
  public var altMaskImage(default, set):BitmapData;

  /**
   * An alternate brightness threshold for the drop shadow.
   * Anything below this number will NOT be affected by the drop shadow shader,
   * but ONLY when the pixel is within the mask.
   */
  public var maskThreshold(default, set):Float;

  /**
   * The FunkinSprite that the shader should get the frame data from.
   * Needed to keep the drop shadow shader in the correct bounds and rotation.
   */
  public var attachedSprite(default, set):FunkinSprite;

  /**
   * The antialiasing amount.
   */
  @:deprecated("Not fully functional with the rewrite use antialiasing instead, only here for compatibility")
  public var antialiasAmt(default, set):Float = 2.0;

  /**
   * The antialiasing flag.
   */
  public var antialiasing(default, set):Bool;

  /**
   * The hue component of the Adjust Color part of the shader.
   */
  public var baseHue(default, set):Float;

  /**
   * The saturation component of the Adjust Color part of the shader.
   */
  public var baseSaturation(default, set):Float;

  /**
   * The brightness component of the Adjust Color part of the shader.
   */
  public var baseBrightness(default, set):Float;

  /**
   * The contrast component of the Adjust Color part of the shader.
   */
  public var baseContrast(default, set):Float;

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

  function updateAngle():Void
  {
    var newAngle = (angle + angleOffset) * FlxAngle.TO_RAD;
    var cos = Math.cos(newAngle);
    var sin = Math.sin(newAngle);

    this.setFloatArray("ang", [cos, sin]);
  }

  /**
   * Sets all 4 adjust color values.
   * @param b The brightness value
   * @param h The hue value
   * @param c The contrast value
   * @param s The saturation value
   */
  public function setAdjustColor(b:Float, h:Float, c:Float, s:Float):Void
  {
    baseBrightness = b;
    baseHue = h;
    baseContrast = c;
    baseSaturation = s;
  }

  function set_antialiasing(value:Bool):Bool
  {
    antialiasing = value;

    this.setBool("enable_antialiasing", antialiasing);
    return antialiasing;
  }

  function set_antialiasAmt(value:Float):Float
  {
    antialiasAmt = value;
    antialiasing = antialiasAmt > 1.0;

    return antialiasAmt;
  }

  function set_baseHue(val:Float):Float
  {
    baseHue = val;

    this.setFloatArray("hueMatrix", makeHueMatrix(val * FlxAngle.TO_RAD));
    return baseHue;
  }

  function set_baseSaturation(val:Float):Float
  {
    baseSaturation = val;

    if (val > 0) val *= 3;
    val = 1 + (val / 100);

    this.setFloatArray("saturationMatrix", makeSaturationMatrix(val));
    return baseSaturation;
  }

  function set_baseBrightness(val:Float):Float
  {
    baseBrightness = val;

    this.setFloat("brightness", val / 255);
    return baseBrightness;
  }

  function set_baseContrast(val:Float):Float
  {
    var e:Float = 2.718281828459045;

    baseContrast = val;

    val = 1 + (val / 100);
    if (val > 1.0)
    {
      val = (((0.00852259 * Math.pow(e, 4.76454 * (val - 1.0))) * 1.01) - 0.0086078159) * 10.0; // Just roll with it...
      val += 1.0;
    }

    this.setFloat("contrast", val);
    return baseContrast;
  }

  function set_threshold(val:Float):Float
  {
    threshold = val;
    this.setFloat("thr", val);
    return val;
  }

  function set_color(col:FlxColor):FlxColor
  {
    color = col;
    this.setFloatArray("dropColor", [color.red / 255, color.green / 255, color.blue / 255]);

    return color;
  }

  function set_angle(val:Float):Float
  {
    angle = val;

    updateAngle();

    return val;
  }

  function set_angleOffset(val:Float):Float
  {
    angleOffset = val;

    updateAngle();

    return val;
  }

  function set_distance(val:Float):Float
  {
    distance = val;
    this.setFloat("dist", val);
    return val;
  }

  function set_strength(val:Float):Float
  {
    strength = val;
    this.setFloat("str", val);
    return val;
  }

  function set_attachedSprite(spr:FunkinSprite):FunkinSprite
  {
    attachedSprite = spr;
    updateFrameInfo(attachedSprite.frame);

    // Enable render texture for texture atlas sprites
    // This allows the shader to work properly on them
    if (attachedSprite.isAnimate && !attachedSprite.useRenderTexture)
    {
      attachedSprite.useRenderTexture = true;
    }

    return spr;
  }

  /**
   * Loads an image for the mask.
   * While you *could* directly set the value of the mask, this function works for both HTML5 and native targets.
   *
   * @param path The path to the image to load
   */
  public function loadAltMask(path:String):Void
  {
    altMaskImage = Assets.getBitmapData(path, false);
  }

  /**
   * Should be called on the animation.callback of the attached sprite.
   * TODO: figure out why the reference to the attachedSprite breaks on web??
   *
   * @param name The name of the animation
   * @param frameNum The current frame number
   * @param frameIndex The current frame index
   */
  public function onAttachedFrame(name:String, frameNum:Int, frameIndex:Int):Void
  {
    if (attachedSprite != null) updateFrameInfo(attachedSprite.frame);
  }

  /**
   * Updates the frame bounds and angle offset of the sprite for the shader
   * @param frame The frame to retrieve the information from
   */
  public function updateFrameInfo(frame:FlxFrame):Void
  {
    // NOTE: uv.right is actually the right pos and uv.bottom is the bottom pos
    this.setFloatArray("uFrameBounds", [frame.uv.left, frame.uv.top, frame.uv.right, frame.uv.bottom]);

    // if a frame is rotated the shader will look completely wrong lol
    angleOffset = frame.angle;
  }

  function set_altMaskImage(_bitmapData:BitmapData):BitmapData
  {
    altMaskImage = _bitmapData;
    this.setBitmapData("altMask", _bitmapData);

    return _bitmapData;
  }

  function set_maskThreshold(val:Float):Float
  {
    maskThreshold = val;
    this.setFloat("thr2", maskThreshold);
    return val;
  }

  function set_useAltMask(val:Bool):Bool
  {
    useAltMask = val;
    this.setBool("useMask", useAltMask);
    return val;
  }

  public function new()
  {
    super(Assets.getText(Paths.frag('ui/shaders/drop-shadow')));

    angle = 0;
    angleOffset = 0;
    strength = 1;
    distance = 15;
    threshold = 0.1;

    antialiasing = true;

    baseHue = 0;
    baseSaturation = 0;
    baseBrightness = 0;
    baseContrast = 0;

    useAltMask = false;
  }
}
