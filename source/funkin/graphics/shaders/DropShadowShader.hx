package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import flixel.math.FlxAngle;
import flixel.graphics.frames.FlxFrame;
import openfl.display.BitmapData;

import Math;

/**
 * A shader that aims to *mostly recreate how Adobe Animate/Flash handles drop shadows, but its main use here is for rim lighting.
 *
 * Has options for color, angle, distance, and a threshold to not cast the shadow on parts like outlines.
 * Can also be supplied a secondary mask which can then have an alternate threshold, for when sprites have too many conflicting colors
 * for the drop shadow to look right (e.g. the tankmen on GF's speakers).
 *
 * Also has an Adjust Color shader in here so they can work together when needed.
 */
class DropShadowShader extends FlxShader
{
  /**
   * The color of the drop shadow.
   */
  public var color(default, set):FlxColor;

  /**
   * The angle of the drop shadow.
   *
   * for reference, depending on the angle, the affected side will be:
   * 0 = RIGHT
   * 90 = UP
   * 180 = LEFT
   * 270 = DOWN
   */
  public var angle(default, set):Float;

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
   * The amount of antialias samples per-pixel,
   * used to smooth out any hard edges the brightness thresholding creates.
   * Defaults to 2, and 0 will remove any smoothing.
   */
  public var antialiasAmt(default, set):Float;

  /**
   * Whether the shader should try and use the alternate mask.
   * False by default.
   */
  public var useAltMask(default, set):Bool;

  /**
   * The image for the alternate mask.
   * At the moment, it uses the blue channel to specify what is or isnt going to use the alternate threshold.
   * (its kinda sloppy rn i need to make it work a little nicer)
   * TODO: maybe have a sort of "threshold intensity texture" as well? where higher/lower values indicate threshold strength..
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
      wR + (1 - wR)*c - wR*s,   wG - wG*c - wG*s,          wB - wB*c + (1 - wB)*s,
      wR - wR*c + 0.143*s,      wG + (1 - wG)*c + 0.140*s, wB - wB*c - 0.283*s,
      wR - wR*c - (1 - wR)*s,   wG - wG*c + wG*s,          wB + (1 - wB)*c + wB*s
    ];
  }

  function makeSaturationMatrix(s:Float):Array<Float>
  {
    var lr = 0.2126;
    var lg = 0.7152;
    var lb = 0.0722;

    var inv = 1.0 - s;

    return [
        lr*inv + s, lg*inv,     lb*inv,
        lr*inv,     lg*inv + s, lb*inv,
        lr*inv,     lg*inv,     lb*inv + s
    ];
  }

  function updateAng()
  {
    var newAngle = (angle + angleOffset) * FlxAngle.TO_RAD;
    var cos = Math.cos(newAngle);
    var sin = Math.sin(newAngle);

    angCos.value = [cos];
    angSin.value = [sin];
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

  function set_baseHue(val:Float):Float
  {
    baseHue = val;

    hueMatrix.value = makeHueMatrix(val * FlxAngle.TO_RAD);
    return baseHue;
  }

  function set_baseSaturation(val:Float):Float
  {
    baseSaturation = val;

    if (val > 0)
      val *= 3;
    val = 1 + (val / 100);

    saturationMatrix.value = makeSaturationMatrix(val);
    return baseSaturation;
  }

  function set_baseBrightness(val:Float):Float
  {
    baseBrightness = val;

    brightness.value = [val / 255];
    return baseBrightness;
  }

  function set_baseContrast(val:Float):Float
  {
    var e:Float = 2.718281828459045;

    baseContrast = val;

    val = 1 + (val / 100);
    if(val > 1.0){
		  val = (((0.00852259 * Math.pow(e, 4.76454 * (val - 1.0))) * 1.01) - 0.0086078159) * 10.0; //Just roll with it...
		  val += 1.0;
		}

    contrast.value = [val];
    return baseContrast;
  }

  function set_threshold(val:Float):Float
  {
    threshold = val;
    thr.value = [val];
    return val;
  }

  function set_antialiasAmt(val:Float):Float
  {
    antialiasAmt = val;
    AA_STAGES.value = [val];
    return val;
  }

  function set_color(col:FlxColor):FlxColor
  {
    color = col;
    dropColor.value = [color.red / 255, color.green / 255, color.blue / 255];

    return color;
  }

  function set_angle(val:Float):Float
  {
    angle = val;

    updateAng();
    return val;
  }

  function set_angleOffset(val:Float):Float
  {
    angleOffset = val;

    updateAng();
    return val;
  }

  function set_distance(val:Float):Float
  {
    distance = val;
    dist.value = [val];
    return val;
  }

  function set_strength(val:Float):Float
  {
    strength = val;
    str.value = [val];
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
    uFrameBounds.value = [frame.uv.left, frame.uv.top, frame.uv.right, frame.uv.bottom];

    // if a frame is rotated the shader will look completely wrong lol
    angleOffset = frame.angle;
  }

  function set_altMaskImage(_bitmapData:BitmapData):BitmapData
  {
    altMask.input = _bitmapData;

    return _bitmapData;
  }

  function set_maskThreshold(val:Float):Float
  {
    maskThreshold = val;
    thr2.value = [val];
    return val;
  }

  function set_useAltMask(val:Bool):Bool
  {
    useAltMask = val;
    useMask.value = [val];
    return val;
  }

  @:glFragmentSource('
      #pragma header

      #ifdef GL_ES
        #ifdef GL_OES_standard_derivatives
          #define HAS_DERIVATIVES
        #endif
      #else
        #if __VERSION__ >= 130
          #define HAS_DERIVATIVES
        #endif
      #endif

      // This shader aims to mostly recreate how Adobe Animate/Flash handles drop shadows, but its main use here is for rim lighting.

      // this shader also includes a recreation of the Animate/Flash "Adjust Color" filter,
      // which was kindly provided and written by Rozebud https://github.com/ThatRozebudDude ( thank u rozebud :) )
      // Adapted from Andrey-Postelzhuks shader found here: https://forum.unity.com/threads/hue-saturation-brightness-contrast-shader.260649/
      // Hue rotation stuff is from here: https://www.w3.org/TR/filter-effects/#feColorMatrixElement

      // equals (frame.left, frame.top, frame.right, frame.bottom)
      uniform vec4 uFrameBounds;

      uniform float dist;
      uniform float str;
      uniform float thr;

      // need to account for rotated frames... oops
      uniform float angOffset;

      uniform float angCos;
      uniform float angSin;

      uniform sampler2D altMask;
      uniform bool useMask;
      uniform float thr2;

      uniform vec3 dropColor;

      uniform mat3 hueMatrix;
      uniform float contrast;
      uniform mat3 saturationMatrix;
      uniform float brightness;

      uniform float AA_STAGES; // unused!

      const vec3 lumaValue = vec3(0.2126, 0.7152, 0.0722);

      vec3 applyHSBCEffect(vec3 color)
      {
        vec3 bh = (brightness + color) * hueMatrix;
        vec3 c = (bh - 0.25) * contrast + 0.25;
        vec3 s = c * saturationMatrix;

        return s;
      }

      float getLumaRGB(vec3 color)
      {
        return dot(color.rgb, lumaValue);
      }

      vec4 getTexRGBA(vec2 uv)
      {
        return texture2D(bitmap, uv);
      }

      float getLumaTex(vec2 uv)
      {
        return getLumaRGB(getTexRGBA(uv).rgb);
      }

      // Used as Difference Based AA.
      // Return value range (0.0, 2.0)
      float lwidth_manual(float center, vec2 uv, vec2 px)
      {
        if (AA_STAGES <= 1.0)
          return 0.0;

        vec3 p2x1 = getTexRGBA(uv + vec2( 1.0,  0.0) * px).rgb;
        vec3 p1x2 = getTexRGBA(uv + vec2( 0.0,  1.0) * px).rgb;
        vec3 p2x2 = getTexRGBA(uv + vec2( 1.0,  1.0) * px).rgb;

        float right     = getLumaRGB(p2x1);
        float down      = getLumaRGB(p1x2);
        float diagonal  = getLumaRGB(p2x2);

        float dx = abs(right - center);
        float dy = abs(down - center);
        float dd = abs(diagonal - center);

        return ((dx + dy + dd * 0.7) / (1.0 + 1.0 + 0.7)) * 2.0;
      }

      // ============================
      // THRESHOLD
      // ============================

      float getThreshold(vec2 uv)
      {
        float threshold = thr;
        float maskIntensity = 0.0;

        if (useMask)
        {
          maskIntensity = texture2D(altMask, uv).b;
          if (maskIntensity > 0.0)
            threshold = thr2;
        }

        return threshold;
      }

      // ============================
      // DROP SHADOW / RIM
      // ============================

      vec4 createDropShadowEx(vec2 uv, vec2 ratio, vec2 size)
      {
        vec4 color4 = texture2D(bitmap, uv);

      #ifdef HAS_DERIVATIVES
        // Increase the pixel distance if the screen is smaller than the sprite!
        vec2 px = max(ratio, fwidth(uv));
      #else
        vec2 px = ratio;
      #endif

        float color3_light = getLumaRGB(color4.rgb);

        float delta = lwidth_manual(color3_light, uv, px);

        // FIXME: Threshold now uses Luma instead of Gray.
        // The -0.05 offset is a temporary hack and does NOT accurately match
        // the old behavior, since the difference varies per color.
        // Proper fix: adjust thresholds in scripts/mods to account for Luma.
        float threshold = getThreshold(uv) - 0.05;

        float intensity = smoothstep(threshold - delta, threshold + delta, color3_light);

        float shadowAlpha = 0.0;

        vec3 color3_no_effect = color4.a > 0.0 ? color4.rgb / color4.a : color4.rgb;
        vec3 color3 = applyHSBCEffect(color3_no_effect);

        vec2 checked = vec2(
          uv.x + (dist * angCos * ratio.x),
          uv.y - (dist * angSin * ratio.y)
        );

        if (checked.x > uFrameBounds.x &&
            checked.y > uFrameBounds.y &&
            checked.x < uFrameBounds.z &&
            checked.y < uFrameBounds.w)
        {
          shadowAlpha = texture2D(bitmap, checked).a;
        }

        float rim = (1.0 - (shadowAlpha * str)) * intensity;

        color3 += dropColor * rim;

        return vec4(color3 * color4.a, color4.a);
      }

      void main()
      {
        gl_FragColor = createDropShadowEx(openfl_TextureCoordv, 1.0 / openfl_TextureSize.xy, openfl_TextureSize.xy);
      }

    ')
  public function new()
  {
    super();

    angle = 0;
    angleOffset = 0;
    strength = 1;
    distance = 15;
    threshold = 0.1;

    baseHue = 0;
    baseSaturation = 0;
    baseBrightness = 0;
    baseContrast = 0;

    antialiasAmt = 2;

    useAltMask = false;

    angOffset.value = [0];
  }
}
