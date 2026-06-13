package funkin.ui.quickpanel;

import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;

class QuickPanelShader extends FlxShader
{
  public var boilAmount(default, set):Float = 0.2;

  static var DEFAULT_BOIL_TEXTURE:String = "assets/ui/boil_texture.png";

  function set_boilAmount(val:Float):Float
  {
    boilAmount = val;
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

  public static final START_COLOR_NORMAL:FlxColor = 0xffF3E63A;
  public static final END_COLOR_NORMAL:FlxColor = 0xfff5db33;
  public static final START_COLOR_DISABLED:FlxColor = 0xffc7bfbc;
  public static final END_COLOR_DISABLED:FlxColor = 0xffa7a09d;

  public var doLerp:Bool = true;
  public var sliceColorStart:FlxColor = 0xffF3E63A;
  public var sliceColorEnd:FlxColor = 0xfff5db33;
  public var sliceColor(default, set):FlxColor = 0xffF3E63A;
  public var sliceLerp(default, set):Float = 0;

  function set_sliceLerp(val:Float)
  {
    if (!doLerp) return val;

    sliceLerp = val;
    sliceColor = FlxColor.interpolate(sliceColorStart, sliceColorEnd, val);

    return val;
  }

  function set_sliceColor(val:FlxColor):FlxColor
  {
    sliceColor = val;
    sliceCol.value = [sliceColor.red / 255, sliceColor.green / 255, sliceColor.blue / 255];

    return sliceColor;
  }

  public var bgColor(default, set):FlxColor = 0;

  function set_bgColor(val:FlxColor):FlxColor
  {
    bgColor = val;
    bgCol.value = [bgColor.red / 255, bgColor.green / 255, bgColor.blue / 255, bgColor.alpha / 255];

    return bgColor;
  }

  public var outlineColor(default, set):FlxColor = 0;

  function set_outlineColor(val:FlxColor):FlxColor
  {
    outlineColor = val;
    outlineCol.value = [outlineColor.red / 255, outlineColor.green / 255, outlineColor.blue / 255, outlineColor.alpha / 255];

    return outlineColor;
  }

  public var sliceVisible(default, set):Bool = true;

  function set_sliceVisible(val:Bool)
  {
    sliceVisible = val;
    sliceEnabled.value = [sliceVisible];

    return val;
  }

  public var fat(default, set):Float = 0;

  function set_fat(val:Float)
  {
    fat = val;
    angle.value = [fat * FlxAngle.TO_RAD];

    return val;
  }

  public var dir(default, set):Float = 0;

  function set_dir(val:Float)
  {
    dir = val;
    direction.value = [dir * FlxAngle.TO_RAD];

    return val;
  }

  public var dirExtra(default, set):Float = 0;

  function set_dirExtra(val:Float)
  {
    dirExtra = val;
    directionExtra.value = [dirExtra * FlxAngle.TO_RAD];

    return val;
  }

  public var fatExtra(default, set):Float = 0;

  function set_fatExtra(val:Float)
  {
    fatExtra = val;
    angleExtra.value = [fatExtra * FlxAngle.TO_RAD];

    return val;
  }

  /*
    Updates the frame bounds of the sprite for the shader.
   */
  public function updateFrameInfo(frame:FlxFrame)
  {
    uFrameBounds.value = [frame.uv.left, frame.uv.top, frame.uv.right, frame.uv.bottom];
  }

  @:glFragmentSource('
        #pragma header

// angle code adapted from https://www.shadertoy.com/view/MtKcDt

#define PI 3.1415926535897932384626433832795

uniform float angle;
uniform float angleExtra;

uniform float direction;
uniform float directionExtra;

uniform vec2 relOffset;

uniform vec3 sliceCol;
uniform vec4 bgCol;
uniform vec4 outlineCol;

uniform bool sliceEnabled;

// equals (frame.left, frame.top, frame.right, frame.bottom)
uniform vec4 uFrameBounds;

vec2 correctedCoord(vec2 coord){
  float xScaled = (coord.x - uFrameBounds.x) / (uFrameBounds.z - uFrameBounds.x);
  float yScaled = (coord.y - uFrameBounds.w) / (uFrameBounds.y - uFrameBounds.w);

  return vec2(xScaled, yScaled);
}

vec2 correctedRatio(){
  return vec2(openfl_TextureSize.x * (uFrameBounds.z - uFrameBounds.x), openfl_TextureSize.y * (uFrameBounds.w - uFrameBounds.y));
}

float intersect(float d1, float d2)
{
	return max(d1, d2);
}

float merge(float d1, float d2)
{
	return min(d1, d2);
}

float pie(vec2 p, float angle)
{
	vec2 n = vec2(-cos(angle), sin(angle));
	return p.x * n.x + p.y*n.y;
}

vec4 sceneDist(vec2 p, vec4 color)
{
	vec2 center = correctedRatio() * relOffset;
  p = p - center;

  float fullAngle = angle + angleExtra;

  float cc = 0.0;
  float start = (direction + directionExtra) - (fullAngle / 2.0);
  float circle = length(p) - center.y * 0.9;

  float end;
  end = start + fullAngle;

  float c = pie(p, start);
  float c2 = pie(p, end);
  float delta = end - start;

  if(delta < PI)
    cc = intersect(c,1.0 - c2);
  else
    cc = intersect(circle, cc);

	return mix(color, vec4(sliceCol.rgb, 1.0), clamp(1.0-cc,0.0,1.0) );
}

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
  vec4 textureColor = texture2D(bitmap, openfl_TextureCoordv);
  vec3 unpremultipliedColor = textureColor.a > 0.0 ? textureColor.rgb / textureColor.a : textureColor.rgb;

  vec4 recolored = vec4(0.0);

  recolored.a = (unpremultipliedColor.r * bgCol.a) + (unpremultipliedColor.g * bgCol.a) + (unpremultipliedColor.b * outlineCol.a);
  recolored.rgb = min(unpremultipliedColor.r * bgCol.rgb + unpremultipliedColor.g * bgCol.rgb + unpremultipliedColor.b * outlineCol.rgb, vec3(1.0));

  vec4 displaceData = getTexture(openfl_TextureCoordv);

  vec2 correctedPos = correctedCoord(openfl_TextureCoordv.xy) * correctedRatio();
  vec2 displacedPos = correctedPos + (((displaceData.rg * 2.0) - 1.0) * (amt * correctedRatio()));

  vec4 slice = sceneDist(displacedPos, recolored);

  vec4 finalColor;

  if(sliceEnabled){
    finalColor = mix(recolored, slice, unpremultipliedColor.r);
  }else{
    finalColor = recolored;
  }


  gl_FragColor = vec4(finalColor.rgb * (finalColor.a * textureColor.a), (finalColor.a * textureColor.a));
}

    ')
  public function new()
  {
    super();
    loadDefaultBoilTexture();

    sliceColor = 0xffF3E63A;
    bgColor = 0xFF000000;
    outlineColor = 0xFFCCCCCC;

    sliceVisible = true;

    sliceLerp = 0;

    boilAmount = 0.004;

    dir = -90;
    dirExtra = 0;
    fat = 1.88;
    relOffset.value = [7.17, 0.5];
  }

  public function update(elapsed:Float)
  {
    // if (FlxG.keys.pressed.I)
    // {
    //   dir += elapsed * 1;
    // }
    // if (FlxG.keys.pressed.K)
    // {
    //   dir -= elapsed * 1;
    // }

    // if (FlxG.keys.pressed.L)
    // {
    //   fat += elapsed * 1;
    // }
    // if (FlxG.keys.pressed.J)
    // {
    //   fat -= elapsed * 1;
    // }

    // trace(dir, fat);
  }
}
