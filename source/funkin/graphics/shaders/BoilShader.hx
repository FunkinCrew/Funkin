package funkin.graphics.shaders;

import flixel.graphics.tile.FlxGraphicsShader;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

/**
 * Displaces pixels using a noise texture.
 */
class BoilShader extends FlxGraphicsShader
{
  static var DEFAULT_BOIL_TEXTURE:String = 'assets/ui/boil_texture.png';

  public var amount(default, set):Float;
  public var boilTexture(default, set):BitmapData;
  public var isCircleWipe(default, set):Bool = false;
  public var circleColor(default, set):FlxColor = 0;
  public var relativeX(default, set):Float = 0;
  public var relativeY(default, set):Float = 0;
  public var circleRadius(default, set):Float = 0;

  var timer:Int;

  /**
   * Creates a new BoilShader
   * @param circleWipe Makes the boil circular.
   */
  public function new(circleWipe:Bool = false)
  {
    super();
    loadDefaultBoilTexture();

    // Give the circle uniforms safe values without touching the boil timer,
    // so the regular boil mode starts out exactly as before.
    relOffset.value = [0, 0];
    radius.value = [0];
    circleCol.value = [0, 0, 0, 0];

    isCircleWipe = circleWipe;

    if (circleWipe)
    {
      // Old CircleWipeShader defaults
      amount = 3;
      circleRadius = 2.9;
      circleColor = 0xFF000000;
      relativeX = 2.6;
      relativeY = 0.5;
    }
  }

  /**
   * Initalizes our shader with a hardcoded texture we have
   */
  public inline function loadDefaultBoilTexture():Void
  {
    loadBoilTexture(DEFAULT_BOIL_TEXTURE);
  }

  /**
   * Loads a texture to be used as our input for "boiling"
   * @param path asset path for the texture
   */
  public function loadBoilTexture(path:String):Void
  {
    #if html5
    BitmapData.loadFromFile(path).onComplete(function(bmp:BitmapData)
    {
      boilTexture = bmp;
    });
    #else
    boilTexture = Assets.getBitmapData(path, false);
    #end
  }

  /**
   * Jumps the noise offset to a random spot, kindof like a hard re-roll of the boil effect.
   */
  public function bumpTimer():Void
  {
    timer = FlxG.random.int(0, 99999);
  }

  /**
   * Nudges the boil forward by 1 to 2 steps, giving a little jitter to the boil.
   */
  public function updateBoil():Void
  {
    timer += FlxG.random.int(1, 2);
    time.value = [timer];
  }

  @:glFragmentSource('
    #pragma header

    uniform float amt;
    uniform float time;

    uniform sampler2D tex;
    uniform vec2 texResolution;

    uniform bool circleMode;

    uniform vec2 relOffset;
    uniform vec4 circleCol;
    uniform float radius;

    float _mod(float x, float y) {
      return x - y * floor(x/y);
    }

    float rand(vec2 a) {
      return fract(sin(dot(mod(a, vec2(1000.0)).xy, vec2(12.9898, 78.233))) * 43758.5453);
    }

    vec4 texture2D_bilinear(sampler2D t, vec2 uv){
      vec2 texelSize = 1.0/texResolution;
      vec2 f = fract(uv * texResolution);
      uv += (.5 - f) * texelSize;
      vec4 tl = texture2D(t, uv);
      vec4 tr = texture2D(t, uv + vec2(texelSize.x, 0.0));
      vec4 bl = texture2D(t, uv + vec2(0.0, texelSize.y));
      vec4 br = texture2D(t, uv + vec2(texelSize.x, texelSize.y));
      vec4 tA = mix(tl, tr, f.x);
      vec4 tB = mix(bl, br, f.x);
      return mix(tA, tB, f.y);
    }

    vec4 getTexture(vec2 coord){
      vec2 ratio = texResolution.xy / openfl_TextureSize.xy;
      vec2 pixelPosition = coord.xy * openfl_TextureSize.xy;

      //pixelPosition = pixelPosition + (time * rand(vec2(time)));

      pixelPosition = pixelPosition + (time * 40.0);

      vec2 uv = pixelPosition.xy/openfl_TextureSize.xy;
      uv /= ratio;
      uv = vec2(_mod(uv.x, 1.0), _mod(uv.y, 1.0));

      return texture2D_bilinear(tex, uv);
    }

    float circle(vec2 uv, vec2 pos, float rad) {
      float d = length(pos - uv) - rad;
      float t = clamp(d, 0.0, 1.0);
      return 1.0 - t;
    }

    void main()
    {
      // r = x offset, g = y offset, b = amount offset..
      vec4 displaceData = getTexture(openfl_TextureCoordv);
      vec2 imageRatio = vec2(1.0 / openfl_TextureSize.x, 1.0 / openfl_TextureSize.y);
      vec2 displacedPos = openfl_TextureCoordv + (((displaceData.rg * 2.0) - 1.0) * (amt * imageRatio));

      if (circleMode)
      {
        vec4 textureColor = texture2D(bitmap, openfl_TextureCoordv);
        float c = circle(displacedPos * openfl_TextureSize.xy, relOffset * openfl_TextureSize.xy, radius * openfl_TextureSize.y);
        gl_FragColor = mix(textureColor, circleCol, c);
      }
      else
      {
        vec4 col = vec4(0.0);
        if (displacedPos.x > 0.0 && displacedPos.x < 1.0 && displacedPos.y > 0.0 && displacedPos.y < 1.0) {
          col = flixel_texture2D(bitmap, displacedPos);
        }
        gl_FragColor = col;
      }
    }
  ')
  function set_amount(val:Float):Float
  {
    amount = val;
    amt.value = [val];

    return val;
  }

  function set_boilTexture(_bitmapData:BitmapData):BitmapData
  {
    tex.input = _bitmapData;
    texResolution.value = [_bitmapData.width, _bitmapData.height];

    return _bitmapData;
  }

  function set_isCircleWipe(val:Bool):Bool
  {
    isCircleWipe = val;
    circleMode.value = [val];

    return val;
  }

  function set_circleColor(val:FlxColor):FlxColor
  {
    circleColor = val;
    circleCol.value = [circleColor.red / 255, circleColor.green / 255, circleColor.blue / 255, circleColor.alpha / 255];

    return circleColor;
  }

  function set_relativeX(val:Float)
  {
    relativeX = val;
    relOffset.value[0] = relativeX;

    return val;
  }

  function set_relativeY(val:Float)
  {
    relativeY = val;
    relOffset.value[1] = relativeY;

    return val;
  }

  function set_circleRadius(val:Float)
  {
    circleRadius = val;
    radius.value = [circleRadius];

    updateBoil();

    return val;
  }
}
