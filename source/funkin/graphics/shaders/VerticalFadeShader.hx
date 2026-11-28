package funkin.graphics.shaders;

import flixel.graphics.frames.FlxFrame;
import flixel.system.FlxAssets.FlxShader;

/**
 * The type of fade
 */
enum abstract VerticalFadeType(Int) from Int to Int
{
  /**
   * Fade from the top.
   */
  public var TOP = 0;

  /**
   * Fade from the bottom.
   */
  public var BOTTOM = 1;

  /**
   * Fade from both the top and bottom.
   */
  public var BOTH = 2;
}

/**
 * Fades out the top or bottom of a sprite.
 */
class VerticalFadeShader extends FlxShader
{
  /**
   * The type of fade to apply.
   */
  public var fadeType(default, set):VerticalFadeType;

  function set_fadeType(value:VerticalFadeType):VerticalFadeType
  {
    fadeType = value;

    switch (value)
    {
      case TOP:
        fadeTop.value = [true];
        fadeBottom.value = [false];
      case BOTTOM:
        fadeTop.value = [false];
        fadeBottom.value = [true];
      case BOTH:
        fadeTop.value = [true];
        fadeBottom.value = [true];
    }

    return value;
  }

  /**
   * The threshold value for the fade effect.
   * Default is 0.5, which will fade out the top or bottom half of the image.
   */
  public var fadeThreshold(default, set):Float = 0.5;

  function set_fadeThreshold(value:Float):Float
  {
    threshold.value = [value];
    return value;
  }

  /**
   * The size of the fade effect.
   * Larger values will spread out the fade effect more.
   * Default is 0.25.
   */
  public var fadeSize(default, set):Float = 0.25;

  function set_fadeSize(value:Float):Float
  {
    fadeSpread.value = [value];
    return value;
  }

  /**
   * Updates the frame bounds of the sprite for the shader.
   * @param frame The frame to retrieve the information from
   */
  public function updateFrameInfo(frame:Null<FlxFrame>):Void
  {
    if (frame == null)
    {
      uFrameBounds.value = [0, 0, 1, 1];
      uFrameRotated.value = [false];
      uFrameTrim.value = [1, 0];
      return;
    }

    var rotated:Bool = frame.angle != 0;
    var trimmedHeight:Float = rotated ? frame.frame.width : frame.frame.height;
    uFrameBounds.value = [frame.uv.left, frame.uv.top, frame.uv.right, frame.uv.bottom];
    uFrameRotated.value = [rotated];
    uFrameTrim.value = [trimmedHeight / frame.sourceSize.y, frame.offset.y / frame.sourceSize.y];
  }

  @:glFragmentSource('
    #pragma header

    uniform float threshold;
    uniform float fadeSpread;
    uniform bool fadeTop;
    uniform bool fadeBottom;
    uniform vec4 uFrameBounds;
    uniform bool uFrameRotated;
    uniform vec2 uFrameTrim;

    void main()
    {
      vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

      vec2 frameUV = (openfl_TextureCoordv - uFrameBounds.xy) / (uFrameBounds.zw - uFrameBounds.xy);
      float fadeY = frameUV.y;
      if (uFrameRotated) fadeY = 1.0 - frameUV.x;
      fadeY = fadeY * uFrameTrim.x + uFrameTrim.y;

      float fade = 1.0;
      float halfSpread = fadeSpread * 0.5;

      if (fadeTop)
      {
        fade *= smoothstep(threshold - halfSpread, threshold + halfSpread, fadeY);
      }

      if (fadeBottom)
      {
        float bottomThreshold = 1.0 - threshold;
        fade *= 1.0 - smoothstep(bottomThreshold - halfSpread, bottomThreshold + halfSpread, fadeY);
      }

      color.rgb *= fade;
      color.a *= fade;

      if (color.a <= 0.0)
      {
        discard;
      }

      gl_FragColor = color;
    }
	')
  public function new(threshold:Float = 0.5, type:VerticalFadeType = TOP, fadeSize:Float = 0.25)
  {
    super();

    this.fadeThreshold = threshold;
    this.fadeType = type;
    this.fadeSize = fadeSize;
    updateFrameInfo(null);
  }
}
