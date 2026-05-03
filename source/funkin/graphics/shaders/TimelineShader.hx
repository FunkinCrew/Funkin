package funkin.graphics.shaders;

#if FEATURE_CAMERA_EDITOR
import funkin.ui.haxeui.components.editors.timeline.TimelineViewport;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;

/**
 * hi this is fabs this shader is satan and writing it was pure evil
 * hi this is pursk this shader is optimized and cooler than ever
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
   * Controls how detailed the grid and ruler are. Controlled by beatLength.
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
   * NOTE: This does not account for zoom or anything.
   */
  public function setOffset(x:Float, y:Float):Void
  {
    offset.value = [x, y];
  }

  /**
   * Sets the resolution/size of the shader.
   */
  public function setViewSize(width:Float, height:Float):Void
  {
    areaWidth.value = [width];
    areaHeight.value = [height];
  }

  /**
   * Okay, there's the fucking thing, that if this frag text was in one string line, it would throw compilation error *src/funkin/graphics/shaders/TimelineShader.cpp(*line*): error C2026*
   * Aka "this line is too long, MVSC can't proceed that".
   * It's the only way :shrugshrug:, got it?
   */
  @:glFragmentSource("
    #pragma header

    vec4 texture2D_bilinear(sampler2D t, vec2 uv, vec2 size)
    {
      vec2 texelSize = 1.0 / size;
      vec2 f = fract(uv * size);
      uv += (0.5 - f) * texelSize;
      vec4 tl = flixel_texture2D(t, uv);
      vec4 tr = flixel_texture2D(t, uv + vec2(texelSize.x, 0.0));
      vec4 bl = flixel_texture2D(t, uv + vec2(0.0, texelSize.y));
      vec4 br = flixel_texture2D(t, uv + texelSize);
      return mix(mix(tl, tr, f.x), mix(bl, br, f.x), f.y);
    }\n" + "#define FONT_SPACING 1.5\n" + "uniform sampler2D font;\n" + "float print_char(int i, int x, vec2 u)
    {
      return texture2D_bilinear(font, mod(u + vec2(float(i)-float(x)/FONT_SPACING + FONT_SPACING/8., (i)/16) / 16., vec2(1.0, 1.0)), vec2(1024.)).a;
      }\n" + "int digitCount(float x)
    {
      x = max(abs(x), 1.0);
      return int(floor(log(x) / log(10.0))) + 1;
    }\n" + "float printFloat(vec2 u, float num, int dec, int shift)
    {
      if (u.x < 0.0 || abs(u.y - 0.03) > 0.03) return 0.0;
      int x = int(u.x * 16.0 * FONT_SPACING);
      int neg = 0; if (num < 0.0) {
        if (x == 0) return print_char(45, x, u);
        num = abs(num); neg = 1;
      }
      int pre = neg + int(max(1.0, float(digitCount(num))));
      int s2 = pre + dec + 1;
      if (x >= s2) return 0.0;
      float d = float(pre - x); if (d == 0.0) return print_char(10, x, u);
      if (d < 0.0) d += 1.0; d = pow(10.0, d);
      return print_char(shift + int(10.0 * fract(num / 0.999999 / d)), x, u);
    }\n" + "float printInt(vec2 u, int num_i, int shift)
    {
      if (u.x < 0.0 || abs(u.y - 0.03) > 0.03) return 0.0;
      float num = float(num_i); int x = int(u.x * 16.0 * FONT_SPACING);
      int neg = 0;
      if (num < 0.0) {
        if (x == 0) return print_char(45, x, u);
        num = abs(num);
        neg = 1;
      }
      int pre = neg + int(max(1.0, float(digitCount(num))));
      int s2 = pre;
      if (x >= s2) return 0.0;
      float d = float(pre - x);
      if (d == 0.0) return print_char(10, x, u);
      if (d < 0.0) d += 1.0;
      d = pow(10.0, d);
      return print_char(shift + int(10.0 * fract(num / 0.999999 / d)), x, u);
    }\n" + "uniform float areaWidth;
    uniform float areaHeight;
    uniform vec2 beatSize;
    uniform float beatAmt;
    uniform float lineWidth;
    uniform vec2 offset;
    uniform float layerAmt;
    uniform float topBarSize;
    uniform float timeSigNumerator;
    uniform float timeSigDenominator;
    uniform float detail;
    const float MAX_DETAIL = 2.0;
    const float MIN_DETAIL = -1.0;
    int getSplits(float change)
    {
      float d = clamp(detail + change, MIN_DETAIL, MAX_DETAIL);
      if (d < -0.5) return 1;
      if (d < 0.5) return 1;
      if (d < 1.5) return int(timeSigNumerator);
      return int(timeSigNumerator * 4.0);
    }\n" + "float getMeasureInterval()
    {
      float d = clamp(detail, MIN_DETAIL, MAX_DETAIL);
      if (d < -0.5) return timeSigDenominator * 2.0;
      if (d < 0.5) return timeSigDenominator;
      if (d < 1.5) return 1.0;
      return 1.0 / max(1.0, timeSigNumerator);
    }\n" + "vec2 applyBoundary(vec2 result, float divNum, float period, float val)
    {
      float m = mod(divNum, period);
      result.x = mix(result.x, val, 1.0 - step(0.5, m));
      result.y = mix(result.y, val, step(period - 1.5, m));
      return result;
    }\n" + "vec2 calculateTickLengths(float divisionNum, float barSplits, float beatDivisions, float measureDivisions)
    {
      vec2 lengths = vec2(0.1);
      if (detail >= 1.0) lengths = applyBoundary(lengths, divisionNum, beatDivisions, 0.2);
      lengths = applyBoundary(lengths, divisionNum, barSplits, 0.3);
      if (detail == -1.0) return vec2(0.3);
      return applyBoundary(lengths, divisionNum, measureDivisions, 0.4);
    }\n" + "vec2 calculateDivisionOpacity(float divisionNum, float barSplits, float beatDivisions, float measureDivisions)
    {
      vec2 mults = vec2(0.1);
      mults = applyBoundary(mults, divisionNum, beatDivisions, 0.25);
      mults = applyBoundary(mults, divisionNum, barSplits, 0.55);
      return applyBoundary(mults, divisionNum, measureDivisions, 0.80);
    }\n" + "vec2 calculateDecimalText(float num)
    {
      num = max(num, 0.000001);
      float digits = floor(log(num) / log(10.0)) + 1.0;
      return vec2(num / pow(10.0, digits), digits + 1.0);
    }\n" + "vec3 createTopBar(vec3 col, vec2 uv, float barWidth)
    {
      const vec3 bgColor = vec3(0.12);
      const vec3 textColor = vec3(0.80);
      col = mix(col, bgColor, 1.0 - step(topBarSize, uv.y));
      if (uv.x < 0.0) return col;
      float barSplits = float(getSplits(1.0));
      float beatDivisions = barSplits / max(1.0, timeSigNumerator);
      float measureDivisions = barSplits * max(1.0, timeSigDenominator);
      float tickFactor = barWidth / max(1.0, barSplits);
      float measureInterval = max(0.0001, getMeasureInterval());
      float measureFactor = barWidth * measureInterval;
      float relLW = lineWidth / tickFactor;
      float relX = mod(uv.x / tickFactor, 1.0);
      float multLeft = 1.0 - smoothstep(0.0, relLW, relX);
      float multRight = 1.0 - smoothstep(1.0, 1.0 - relLW, relX);
      float divisionNum = floor(uv.x / tickFactor);
      vec2 lengths = calculateTickLengths(divisionNum, barSplits, beatDivisions, measureDivisions);
      float tickTop = topBarSize * 0.9;
      float belowTop = 1.0 - step(tickTop, uv.y);
      col = mix(col, textColor, multLeft * step(tickTop - topBarSize * lengths.x, uv.y) * belowTop);
      col = mix(col, textColor, multRight * step(tickTop - topBarSize * lengths.y, uv.y) * belowTop);
      float textMult = 0.0; if (uv.y < topBarSize)
      {
        float measureFloor = floor(uv.x / measureFactor);
        vec2 relMeasure = vec2(mod(uv.x / measureFactor, 1.0), mod(uv.y / topBarSize, 1.0));
        vec2 textUV = vec2(relMeasure.x * (measureFactor / topBarSize), relMeasure.y);
        textUV = textUV * 0.15 - vec2(0.0, 0.01);
        int curMeasure = int(measureFloor * measureInterval + 1.0);
        int curBeat = int(floor(uv.x / max(1.0, beatSize.x)) + 1.0);
        if (detail == 2.0)
        {
          float percentage = mod(measureFloor * measureInterval, 1.0);
          float result = (percentage * timeSigNumerator + 1.0) / 10.0;
          vec2 decimalText = calculateDecimalText(result);
          bool isFirstBeat = mod(float(curBeat) - 1.0, max(1.0, timeSigNumerator)) == 0.0;
          if (isFirstBeat) textMult = printInt(textUV, curMeasure, 0);
          else textMult = printFloat(textUV, float(curMeasure) + decimalText.x, int(decimalText.y), 0) / 2.0;
        } else {
          textMult = printInt(textUV, curMeasure, 0);
        }
      }
      return mix(col, textColor, textMult);
    }\n" + "void main()
    {
      vec2 screenUV = openfl_TextureCoordv * vec2(areaWidth, areaHeight);
      vec2 uv = screenUV + vec2(offset.x, offset.y - topBarSize);
      vec2 barUv = screenUV + vec2(offset.x, 0.0);
      const vec3 bar1Color = vec3(0.23);
      const vec3 bar2Color = vec3(0.27);
      const vec3 divisionColor = vec3(0.07);
      float barWidth = beatSize.x * max(1.0, timeSigNumerator);
      float barSplitsF = max(1.0, float(getSplits(0.0)));
      float splitFactor = barWidth / barSplitsF;
      float beatDivisions = barSplitsF / max(1.0, timeSigNumerator);
      float measureDivisions = barSplitsF * max(1.0, timeSigDenominator);
      vec2 lw = vec2(lineWidth / splitFactor, lineWidth * 1.5 / max(1.0, beatSize.y));
      vec2 relPos = vec2(mod(uv.x / splitFactor, 1.0), mod(uv.y / max(1.0, beatSize.y), 1.0));
      float barNum = floor(uv.x / barWidth);
      float measureNum = floor(barNum / max(1.0, timeSigDenominator));
      vec3 col = mix(bar1Color, bar2Color, mod(measureNum, 2.0));
      float divisionNum = floor(uv.x / splitFactor);
      vec2 mults = calculateDivisionOpacity(divisionNum, barSplitsF, beatDivisions, measureDivisions);
      float multLeft = 1.0 - smoothstep(0.0, lw.x, relPos.x);
      float multRight = 1.0 - smoothstep(1.0, 1.0 - lw.x, relPos.x);
      float multVertical = 1.0 - min(smoothstep(0.0, lw.y, relPos.y), smoothstep(1.0, 1.0 - lw.y, relPos.y));
      col = mix(col, divisionColor, multLeft * mults.x);
      col = mix(col, divisionColor, multRight * mults.y);
      col = mix(col, divisionColor, multVertical);
      if (uv.x < 0.0 || uv.y < 0.0 || uv.y > beatSize.y * layerAmt)
        col = divisionColor;
      col = createTopBar(col, barUv, barWidth);
      if (uv.x > beatSize.x * beatAmt || uv.x < 0.0)
        col *= 0.5;

      gl_FragColor = vec4(col, 1.0);
    }")
  public function new(lineWidth:Float = 1)
  {
    super();

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

    this.lineWidth.value = [lineWidth];
    topBarSize.value = [TimelineViewport.TOP_BAR_HEIGHT];
    layerHeight = TimelineViewport.LAYER_HEIGHT;
    fontTexture = BitmapData.fromFile("assets/shared/images/ui/camera-editor/timelineFont.png");
  }
}
#end
