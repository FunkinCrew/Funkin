package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.tweens.FlxTween;

class BlueFade extends FlxShader
{
  public var fadeVal(default, set):Float = 1;

  function set_fadeVal(val:Float):Float
  {
    fadeAmt.value = [val];
    fadeVal = val;
    // trace(fadeVal);

    return val;
  }

  public function fade(startAmt:Float = 0, targetAmt:Float = 1, duration:Float, _options:TweenOptions):Void
  {
    fadeVal = startAmt;
    FlxTween.tween(this, {fadeVal: targetAmt}, duration, _options);
  }

  @:glFragmentSource('
       #pragma header

        // Value from (0, 1)
        uniform float fadeAmt;

        // fade the image to blue as it fades to black

        void main()
        {
          vec4 tex = flixel_texture2D(bitmap, openfl_TextureCoordv);

          vec4 finalColor = mix(vec4(vec4(0.0, 0.0, tex.b, tex.a) * fadeAmt), vec4(tex * fadeAmt), fadeAmt);

          // Output to screen
          gl_FragColor = finalColor;
        }

    ')
  public function new()
  {
    super();

    this.fadeVal = 1;
  }
}
