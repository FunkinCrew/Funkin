package funkin.graphics.shaders;

import funkin.ui.haxeui.components.editors.timeline.TimelineViewport;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import flixel.math.FlxMath;

/**
 * hi this is fabs this shader is satan and writing it was pure evil
 */
class TimelineShader extends FlxShader
{
  /**
   * The numerator for the current time signature (the `3` in `3/4`).
   */
  public var timeSignatureNumerator(default, set):Int;

  public function set_timeSignatureNumerator(val:Int):Int
  {
    timeSignatureNumerator = val;
    timeSigNumerator.value = [val];
    return val;
  }

  /**
   * The denominator for the current time signature (the `4` in `3/4`).
   */
  public var timeSignatureDenominator(default, set):Int;

  public function set_timeSignatureDenominator(val:Int):Int
  {
    timeSignatureDenominator = val;
    timeSigDenominator.value = [val];
    return val;
  }

  /**
   * The image used for rendering text in the shader.
   */
  public var fontTexture(default, set):BitmapData;

  function set_fontTexture(_bitmapData:BitmapData):BitmapData
  {
    font.input = _bitmapData;

    return _bitmapData;
  }

  /**
   * The amount of vertical layers to show on the timeline.
   */
  public var layerCount(default, set):Float = 0;

  public function set_layerCount(val:Float):Float
  {
    layerCount = val;
    layerAmt.value = [val];
    return val;
  }

  /**
   * Controls how detialed the grid and ruler are. Controlled by beatLength.
   */
  public var zoomDetail(default, set):Float = 0;

  public function set_zoomDetail(val:Float):Float
  {
    zoomDetail = val;
    detail.value = [val];
    return val;
  }

  /**
   * The length (in pixels) of one beat of the song.
   * This value is used to correctly size the entire timeline horizontally.
   */
  public var beatLength(default, set):Float = 0;

  /**
   * These values control what detail levels should be shown based on the beatLength,
   * from smallest (-1 detail) to largest (2 detail)
   * the array goes as follows: (-1, 0, 1, 2 ...)
   */
  var zoomThresholds:Array<Float> = [0, 4, 20, 100];

  public function set_beatLength(val:Float):Float
  {
    beatLength = val;
    beatSize.value[0] = val;

    var targetZoom:Int = -1;
    for (i in 0...zoomThresholds.length)
    {
      if (val > zoomThresholds[i])
      {
        targetZoom = i - 1;
      }
    }
    zoomDetail = targetZoom;

    return val;
  }

  /**
   * The height (in pixels) of an individual layer.
   */
  public var layerHeight(default, set):Float = 0;

  public function set_layerHeight(val:Float):Float
  {
    layerHeight = val;
    beatSize.value[1] = val;

    return val;
  }

  /**
   * The amount of beats in the current song.
   * This value is used to control the region where the timeline will darken (after the song is complete).
   */
  public var beatCount(default, set):Float = 0;

  public function set_beatCount(val:Float):Float
  {
    beatCount = val;
    beatAmt.value = [val];
    return val;
  }

  /**
   * Sets the pixel offset of the timeline.
   * NOTE: THIS DOES NOT ACCOUNT FOR ZOOM OR ANYTHING
   */
  public function setOffset(x:Float, y:Float)
  {
    offset.value = [x, y];
  }

  /**
   * Sets the resolution/size of the shader.
   */
  public function setViewSize(width:Float, height:Float)
  {
    // trace(width, height);
    areaWidth.value = [width];
    areaHeight.value = [height];
  }

  @:glFragmentSource('
        #pragma header

// bililear sampling function from rozebud thank u thank u thank u

vec4 texture2D_bilinear(sampler2D t, vec2 uv, vec2 size){
    vec2 texelSize = 1.0/size;
    vec2 f = fract(uv * size);
    uv += (.5 - f) * texelSize;
    vec4 tl = flixel_texture2D(t, uv);
    vec4 tr = flixel_texture2D(t, uv + vec2(texelSize.x, 0.0));
    vec4 bl = flixel_texture2D(t, uv + vec2(0.0, texelSize.y));
    vec4 br = flixel_texture2D(t, uv + vec2(texelSize.x, texelSize.y));
    vec4 tA = mix(tl, tr, f.x);
    vec4 tB = mix(bl, br, f.x);
    return mix(tA, tB, f.y);
}

#define FONT_SPACING 1.5

uniform sampler2D font;

// text rendering code from https://www.shadertoy.com/view/43t3WX (I DIDNT MAKE THIS!!! its super fucking cool though and it saved me so thank you)

// #define print_char(i) texture(font, mod(u + vec2(float(i)-float(x)/FONT_SPACING + FONT_SPACING/8., (i)/16) / 16., vec2(1.0, 1.0))).a
#define print_char(i) texture2D_bilinear(font, mod(u + vec2(float(i)-float(x)/FONT_SPACING + FONT_SPACING/8., (i)/16) / 16., vec2(1.0, 1.0)), vec2(1024.)).a

#define log10(x) int(ceil(.4342944819 * log(x + x*1e-5)))

// fuck you mac glsl i thought the on the fly code stuff was cool
float printFloat(vec2 u, float num, int dec, int shift) {
    if (u.x < 0. || abs(u.y - .03) > .03) return 0.;
    const int[] str1 = int[](0);
    const int[] str2 = int[](0);

    const int l1 = str1.length() - 1;
    int x = int(u.x * 16. * FONT_SPACING);
    if (x < l1) return print_char(str1[x]);
    int neg = 0;
    if (num < 0.) {
        if (x == l1)
        return print_char(45);
        num = abs(num); neg = 1;
    }
    int pre = neg + max(1, log10(num));
    int s2 = l1 + pre + dec + 1;
    if (x >= s2) {
        if (x >= s2+str2.length()-1) return 0.;
        int n2 = str2[x - s2];
        return print_char(n2);
    }
    float d = float(l1 + pre - x);
    if (d == 0.) return print_char(10);
    d = pow(10., d < 0.  ? ++d : d);
    int n = shift + int(10.*fract(num/.999999/d));
    return print_char(n);
}

float printInt(vec2 u, int num_i, int shift)   {
    if (u.x < 0. || abs(u.y - .03) > .03)
        return 0.;
    float num = float(num_i);
    const int dec = -1;
    const int[] str1 = int[](0);
    const int[] str2 = int[](0);

    const int l1 = str1.length() - 1;
    int x = int(u.x * 16. * FONT_SPACING);
    if (x < l1) return print_char(str1[x]);
    int neg = 0;
    if (num < 0.) {
        if (x == l1)
        return print_char(45);
        num = abs(num); neg = 1;
    }
    int pre = neg + max(1, log10(num));
    int s2 = l1 + pre + dec + 1;
    if (x >= s2) {
        if (x >= s2+str2.length()-1) return 0.;
        int n2 = str2[x - s2];
        return print_char(n2);
    }
    float d = float(l1 + pre - x);
    if (d == 0.) return print_char(10);
    d = pow(10., d < 0.  ? ++d : d);
    int n = shift + int(10.*fract(num/.999999/d));
    return print_char(n);
}

uniform float areaWidth;
uniform float areaHeight;

uniform vec2 beatSize;
uniform float beatAmt;

uniform float lineWidth;
uniform vec2 offset;

uniform float layerAmt;

uniform float topBarSize;

uniform float timeSigNumerator;
uniform float timeSigDenominator;

const float MAX_DETAIL = 2;
const float MIN_DETAIL = -1;
uniform float detail;

// find amount of times to split bars based on detail level
// change lets you specify a higher or lower detail level, if supported.
int getSplits(float change)
{
    // detail levels as follows:
    // -1, 0, 1, 2
    float definedSplits[4] = float[4](0., 1., timeSigNumerator, timeSigNumerator * 4.);

    // get amount of splits:
    // clamped between MIN_DETAIL and MAX_DETAIL but adds 1 so it fits nicely in the array! yaaaay!
    float splits = definedSplits[int(clamp(detail + change, MIN_DETAIL, MAX_DETAIL) + 1.)];

    // TODO: if higher detail than defined splits, start computing the amount of splits automatically?

    return int(splits);
}

// find amount of times to split bars based on detail level
// change lets you specify a higher or lower detail level, if supported.
float getMeasureIntervals()
{
    // detail levels as follows:
    // -1, 0, 1, 2
    float definedIntervals[4] = float[4](timeSigDenominator * 2., timeSigDenominator, 1., 1. / timeSigNumerator);

    float splits = definedIntervals[int(clamp(detail, MIN_DETAIL, MAX_DETAIL) + 1.)];

    // TODO: if higher detail than defined splits, start computing the amount of splits automatically?

    return splits;
}

// find length for left and right lines for each tick.
vec2 calculateTickLength(vec2 lengths, float divisionNum, float barSplits){

    // divisions for beats, when detail is high enough
    if(detail >= 1.){
        float beatDivisions = barSplits / timeSigNumerator;
        if(mod(divisionNum, beatDivisions) == 0.0){
            lengths.x = 0.2;
        }else if(mod(divisionNum, beatDivisions) == beatDivisions - 1.0){
            lengths.y = 0.2;
        }
    }

    // length for BARS
    if(mod(divisionNum, barSplits) == 0.0){
        lengths.x = 0.3;
    }else if(mod(divisionNum, barSplits) == barSplits - 1.0){
        lengths.y = 0.3;
    }

    // sorry this is gross but i cant think of an elegant fix
    // just force ticks to be bar length on -1 detail because they get confused on their position
    if(detail == -1.){
        lengths = vec2(0.3);
    }

    // length for MEASURES
    float measureDivisions = barSplits * timeSigDenominator;
    if(mod(divisionNum, measureDivisions) == 0.0){
        lengths.x = 0.4;
    }else if(mod(divisionNum, measureDivisions) == measureDivisions - 1.0){
        lengths.y = 0.4;
    }

    return lengths;
}

// calculates number of digits and decimal of the number given
// x : normalized number, y: amount of digits
vec2 calculateDecimalText(float num){
    float digits = floor(log(num) / log(10.0)) + 1.0;

    num = num / pow(10.0, digits);

    return vec2(num, digits + 1.);
}

// creates the top bar that displays bar numbers and ticks
vec3 createTopBar(vec3 col, vec2 uv, float factor, float barLength)
{
    vec3 bgColor = vec3(0.12, 0.12, 0.12);
    vec3 textColor = vec3(0.8, 0.8, 0.8);

    float multBG = 1.0 - step(topBarSize,uv.y);
    col = mix(col, bgColor, multBG);

    // return early if were outside of where this should be drawn
    if(uv.x < 0.0){
        return col;
    }

    // find out how many times to split ticks
    float barSplits = float(getSplits(1.));

    // find how big each box should be
    float tickFactor = (beatSize.x * timeSigNumerator) / barSplits;

    float measureInterval = float(getMeasureIntervals());
    float measureFactor = (beatSize.x * timeSigNumerator) * measureInterval;

    // find correct line width and relative position in tick area
    float lineWidth = lineWidth / tickFactor;
    float relativePosTick = mod(uv.x / tickFactor, 1.0);

    float multLeft = 1.0 - smoothstep(0.0, lineWidth,relativePosTick);
    float multRight = 1.0 - smoothstep(1.0, 1.0 - lineWidth, relativePosTick);

    // default left right lenghts for ticks
    vec2 lengths = vec2(0.1, 0.1);

    // the current tick we are on. again this is NOT relative to the beat or anything.
    float divisionNum = floor(uv.x / tickFactor);

    lengths = calculateTickLength(lengths, divisionNum, barSplits);

    // draw the lines
    if(uv.y > topBarSize * 0.9 - (topBarSize * lengths.x) && uv.y < topBarSize * 0.9){
        col = mix(col, textColor, multLeft);

    }
    if(uv.y > topBarSize * 0.9 - (topBarSize * lengths.y) && uv.y < topBarSize * 0.9){
        col = mix(col, textColor, multRight);
    }

    vec2 relativePosMeasure = vec2(mod(uv.x / measureFactor, 1.0), mod(uv.y / topBarSize, 1.0));

    vec2 textUV = vec2(relativePosMeasure.x * (measureFactor/topBarSize), relativePosMeasure.y);
    textUV = textUV * 0.15 - vec2(0.0, 0.01); // Font size + padding

    float textMult = 0.;

    if(uv.y < topBarSize){
        int curMeasure = int((floor(uv.x / measureFactor) * measureInterval) + 1.);
        int curBeat = int((floor(uv.x / beatSize.x)) + 1.);

        if(detail == 2.){
            // a little confusing so ill try and break it down
            // essentially, if were zoomed in, we want the text to show a decimal-like value to show
            // the amount of beats through a bar we are.
            // so we take the current measure, as well as a value of beats through and turn that into
            // a number to be passed into the text. this probably breaks somewhere but i havent
            // found it yet!

            float percentage = mod(floor(uv.x / measureFactor) * measureInterval, 1.);
            float result = ((percentage * timeSigNumerator) + 1.) / 10.;

            vec2 decimalText = calculateDecimalText(result);

            if(mod(float(curBeat) - 1.0, timeSigNumerator) == 0.0){
                // kinda nasty, but if we are on the first measure we dont want the decimal.
                textMult = printInt(textUV, curMeasure, 0);
            }else{
                textMult = printFloat(textUV, float(curMeasure) + decimalText.x, int(decimalText.y), 16) / 2.;
            }
        }else{
            textMult = printInt(textUV, curMeasure, 0);
        }

    }

    // draw the text
    col = mix(col, textColor, textMult);

    return col;
}

// find opacity for left and right lines for each box.
vec2 calculateDivisionOpacity(vec2 mults, float divisionNum, float barSplits){

    // divisions for beats, when split further
    float beatDivisions = barSplits / timeSigNumerator;
    if(mod(divisionNum, beatDivisions) == 0.0){
        mults.x = 0.25;
    }else if(mod(divisionNum, beatDivisions) == beatDivisions - 1.0){
        mults.y = 0.25;
    }

    // divisions for BARS
    if(mod(divisionNum, barSplits) == 0.0){
        mults.x = 0.55;
    }else if(mod(divisionNum, barSplits) == barSplits - 1.0){
        mults.y = 0.55;
    }

    // divisions for MEASURES
    float measureDivisions = barSplits * timeSigDenominator;
    if(mod(divisionNum, measureDivisions) == 0.0){
        mults.x = 0.8;
    }else if(mod(divisionNum, measureDivisions) == measureDivisions - 1.0){
        mults.y = 0.8;
    }

    return mults;
}

void main()
{
    vec2 uv = vec2(openfl_TextureCoordv.x * areaWidth, openfl_TextureCoordv.y * areaHeight) + vec2(offset.x, offset.y - topBarSize);
    vec2 barUv = vec2(openfl_TextureCoordv.x * areaWidth, openfl_TextureCoordv.y * areaHeight) + vec2(offset.x, 0.0);

    vec3 bar1Color = vec3(0.23, 0.23, 0.23);
    vec3 bar2Color = vec3(0.27, 0.27, 0.27);
    vec3 divisionColor = vec3(0.07, 0.07, 0.07);

    // find out how many times to split the bar
    float barSplits = float(getSplits(0.));

    // find how big each box should be
    float splitFactor = (beatSize.x * timeSigNumerator) / barSplits;

    // target width for lines, relative to box
    vec2 lineWidth = vec2(lineWidth / splitFactor, (lineWidth * 1.5) / beatSize.y);

    // relative UV coordinates inside each box
    vec2 relativePos = vec2(mod(uv.x / splitFactor, 1.0), mod(uv.y / beatSize.y, 1.0));

    // find our current beat, bar, and measure
    float beatNum = floor(uv / beatSize.x).x;
    float barNum = floor(beatNum / timeSigNumerator);
    float measureNum = floor(barNum / timeSigDenominator);

    // flip between two colors based on bar count.
    float barColorVal = mod(measureNum, 2.0);
    vec3 col = mix(bar1Color, bar2Color, barColorVal);

    // the current box we are on. NOT the current beat.
    float divisionNum = floor(uv.x / splitFactor);

    // --- CALCULATE LINES ---

    // x: left side darkness, y: right side darkness
    vec2 mults = vec2(0.1, 0.1);

    mults = calculateDivisionOpacity(mults, divisionNum, barSplits);

    // calculate smooth line falloff based on box size
    float multLeft = 1.0 - smoothstep(0.0, lineWidth.x,relativePos.x);
    float multRight = 1.0 - smoothstep(1.0, 1.0 - lineWidth.x, relativePos.x);
    // slightly thicker lines for the top and bottom
    float multVertical = 1.0 - min(smoothstep(0.0, lineWidth.y,relativePos.y), smoothstep(1.0, 1.0 - lineWidth.y, relativePos.y));

    // apply division color
    col = mix(col, divisionColor, multLeft * mults.x);
    col = mix(col, divisionColor, multRight * mults.y);
    col = mix(col, divisionColor, multVertical);

    // --- CREATE TOP BAR ---

    // trim any shit outside the bounds
    if(uv.x < 0.0 || uv.y < 0.0 || uv.y > beatSize.y * layerAmt){
        col = divisionColor;
    }

    col = createTopBar(col, barUv, splitFactor, 1.);

    // darken anything further than the song end
    if(uv.x > beatSize.x * beatAmt || uv.x < 0.0){
        col *= 0.5;
    }

    // were done... phew!
    gl_FragColor = vec4(col,1.0);
}

    ')
  public function new(_lineWidth:Float = 1)
  {
    super();
    // temporary values just in case the shader breaks
    areaWidth.value = [100];
    areaHeight.value = [100];
    beatSize.value = [100, 100];

    zoomDetail = 0;
    layerCount = 1;
    beatCount = 100;
    beatLength = 100;

    // setting these to 4/4 for now, but they COULD be anything! i just don't know exactly how i should set that up rn in the editor
    timeSignatureNumerator = 4;
    timeSignatureDenominator = 4;

    lineWidth.value = [_lineWidth];
    topBarSize.value = [TimelineViewport.TOP_BAR_HEIGHT];
    layerHeight = TimelineViewport.LAYER_HEIGHT;
    fontTexture = BitmapData.fromFile("assets/shared/images/ui/camera-editor/timelineFont.png");
  }
}
