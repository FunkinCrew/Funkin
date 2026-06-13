package funkin.graphics.shaders;

import flixel.graphics.tile.FlxGraphicsShader;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

class BoilShader extends FlxGraphicsShader
{
  public var amount(default, set):Float;

  static var DEFAULT_BOIL_TEXTURE:String = "assets/ui/boil_texture.png";

  function set_amount(val:Float):Float
  {
    amount = val;
    amt.value = [val];

    return val;
  }

  public var boilTexture(default, set):BitmapData;

  function set_boilTexture(_bitmapData:BitmapData):BitmapData
  {
    tex.input = _bitmapData;
    texResolution.value = [_bitmapData.width, _bitmapData.height];

    return _bitmapData;
  }

  /**
   * Initalizes our shader with a hardcoded texture we have
   * @see DEFAULT_BOIL_TEXTURE static var in BoilShader
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

  // TODO: Document the differences between bumpTimer() and updateBoil()?
  var timer:Int;

  public function bumpTimer():Void
  {
    timer = FlxG.random.int(0, 99999);
  }

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

      return texture2D_bilinear(tex, uv);;
    }

    void main()
    {
      // r = x offset, g = y offset, b = amount offset..
      vec4 displaceData = getTexture(openfl_TextureCoordv);
      vec2 imageRatio = vec2(1.0 / openfl_TextureSize.x, 1.0 / openfl_TextureSize.y);
      vec2 displacedPos = openfl_TextureCoordv + (((displaceData.rg * 2.0) - 1.0) * (amt * imageRatio));

      vec4 col = vec4(0.0);
      if(displacedPos.x > 0.0 && displacedPos.x < 1.0 && displacedPos.y > 0.0 && displacedPos.y < 1.0){
        col = flixel_texture2D(bitmap, displacedPos);
      }

      gl_FragColor = vec4(col);
    }
  ')
  public function new()
  {
    super();
    loadDefaultBoilTexture();
  }
}
