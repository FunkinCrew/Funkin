package funkin.graphics.shaders;

#if FEATURE_CAMERA_EDITOR
import funkin.ui.haxeui.components.editors.timeline.TimelineViewport;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;

/**
 * One stretch of the song under a single time signature.
 */
typedef TimelineSignatureSegment =
{
  // sooo shaders can't have dynamic arrays, so we have a fixed amount of segments that can be displayed at once.
  // Luckily you can reuse these segments so as long as 8 segments are enough to cover the visible area, it'll be fine.

  // otherwise.... sorry!

  /**
   * Where the stretch begins, in pixels from the start of the song.
   */
  var startPx:Float;

  var numerator:Int;
  var denominator:Int;

  /**
   * How many bars came before this stretch, so bar numbers keep counting across it.
   */
  var barIndex:Int;
}

/**
 * hi this is fabs this shader is satan and writing it was pure evil
 * hi this is pursk this shader is optimized and cooler than ever
 * hi this is kade this shader is now satan v2
 */
class TimelineShader extends FlxShader
{
  /**
   * How many time signature stretches the shader can hold at once.
   * The stretches sent are the one under the left edge of the view and the ones after it.
   */
  public static inline var MAX_SEGMENTS:Int = 8;

  static inline var SEGMENT_FAR:Float = 1.0e30;

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
   * How many grid lines a beat is cut into on the lanes. Below one, the lanes only draw bars.
   * The ruler keeps its own detail.
   */
  public var gridLinesPerBeat(default, set):Float = 4;

  public function set_gridLinesPerBeat(val:Float):Float
  {
    gridLinesPerBeat = val;
    gridSplits.value = [val];
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
   * Hands the shader the time signature stretches to draw, first one first.
   */
  public function setSegments(segments:Array<TimelineSignatureSegment>):Void
  {
    var slots:Array<Dynamic> = [seg0, seg1, seg2, seg3, seg4, seg5, seg6, seg7];
    for (i in 0...MAX_SEGMENTS)
    {
      var slot = slots[i];
      if (i < segments.length)
      {
        var seg = segments[i];
        slot.value = [seg.startPx, seg.numerator, seg.denominator, seg.barIndex];
      }
      else
      {
        slot.value = [SEGMENT_FAR, 4, 4, 0];
      }
    }
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
      int x = int(u.x * 16.0 * FONT_SPACING);
      int neg = 0;
      if (num_i < 0) {
        if (x == 0) return print_char(45, x, u);
        num_i = -num_i;
        neg = 1;
      }
      int temp = num_i;
      int digits = 0;
      if (temp == 0) digits = 1;
      for (int i = 0; i < 10; i++) {
        if (temp == 0) break;
        digits++;
        temp /= 10;
      }
      int pre = neg + digits;
      if (x >= pre) return 0.0;
      int target_digit_idx = pre - 1 - x;
      int divisor = 1;
      for (int i = 0; i < 10; i++) {
        if (i >= target_digit_idx) break;
        divisor *= 10;
      }
      int current_digit = (num_i / divisor) - (num_i / (divisor * 10)) * 10;
      return print_char(shift + current_digit, x, u);
    }\n" + "uniform float areaWidth;
    uniform float areaHeight;
    uniform vec2 beatSize;
    uniform float beatAmt;
    uniform float lineWidth;
    uniform vec2 offset;
    uniform float layerAmt;
    uniform float topBarSize;
    uniform float detail;
    uniform float gridSplits;
    uniform vec4 seg0;
    uniform vec4 seg1;
    uniform vec4 seg2;
    uniform vec4 seg3;
    uniform vec4 seg4;
    uniform vec4 seg5;
    uniform vec4 seg6;
    uniform vec4 seg7;
    const float MAX_DETAIL = 2.0;
    const float MIN_DETAIL = -1.0;
    vec4 findSegment(float x)
    {
      vec4 s = seg0;
      if (x >= seg1.x) s = seg1;
      if (x >= seg2.x) s = seg2;
      if (x >= seg3.x) s = seg3;
      if (x >= seg4.x) s = seg4;
      if (x >= seg5.x) s = seg5;
      if (x >= seg6.x) s = seg6;
      if (x >= seg7.x) s = seg7;
      return s;
    }\n" + "float getMeasureInterval(float numer, float denom)
    {
      float d = clamp(detail, MIN_DETAIL, MAX_DETAIL);
      if (d < -0.5) return denom * 2.0;
      if (d < 0.5) return denom;
      if (d < 1.5) return 1.0;
      return 1.0 / max(1.0, numer);
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
      vec2 mults = vec2(0.22);
      mults = applyBoundary(mults, divisionNum, beatDivisions, 0.45);
      mults = applyBoundary(mults, divisionNum, barSplits, 0.55);
      return applyBoundary(mults, divisionNum, measureDivisions, 0.80);
    }\n" + "vec2 calculateDecimalText(float num)
    {
      num = max(num, 0.000001);
      float digits = floor(log(num) / log(10.0)) + 1.0;
      return vec2(num / pow(10.0, digits), digits + 1.0);
    }\n" + "vec3 createTopBar(vec3 col, vec2 uv, float localX, float numer, float denom, float barBase, float barWidth, float splitFactor, float barSplits, float beatDivisions, float measureDivisions)
    {
      const vec3 bgColor = vec3(0.12);
      const vec3 textColor = vec3(0.80);
      col = mix(col, bgColor, 1.0 - step(topBarSize, uv.y));
      if (uv.x < 0.0) return col;
      float measureInterval = max(0.0001, getMeasureInterval(numer, denom));
      float measureFactor = barWidth * measureInterval;
      float relLW = lineWidth / splitFactor;
      float relX = mod(localX / splitFactor, 1.0);
      float multLeft = 1.0 - smoothstep(0.0, relLW, relX);
      float multRight = 1.0 - smoothstep(1.0, 1.0 - relLW, relX);
      float divisionNum = floor(localX / splitFactor) + barBase * barSplits;
      vec2 lengths = calculateTickLengths(divisionNum, barSplits, beatDivisions, measureDivisions);
      float tickTop = topBarSize * 0.9;
      float belowTop = 1.0 - step(tickTop, uv.y);
      col = mix(col, textColor, multLeft * step(tickTop - topBarSize * lengths.x, uv.y) * belowTop);
      col = mix(col, textColor, multRight * step(tickTop - topBarSize * lengths.y, uv.y) * belowTop);
      float textMult = 0.0; if (uv.y < topBarSize)
      {
        float globalBar = barBase + localX / barWidth;
        float measureFloor = floor(globalBar / measureInterval + 0.0001);
        vec2 relMeasure = vec2(globalBar / measureInterval - measureFloor, mod(uv.y / topBarSize, 1.0));
        vec2 textUV = vec2(relMeasure.x * (measureFactor / topBarSize), relMeasure.y);
        textUV = textUV * 0.15 - vec2(0.0, 0.01);
        int curMeasure = int(measureFloor * measureInterval + 1.0001);
        int curBeat = int(floor(localX / max(1.0, beatSize.x) + 0.0001) + 1.0);
        if (detail == 2.0)
        {
          float percentage = mod(measureFloor * measureInterval + 0.0001, 1.0);
          float result = (percentage * numer + 1.0) / 10.0;
          vec2 decimalText = calculateDecimalText(result);
          bool isFirstBeat = mod(float(curBeat) - 1.0, max(1.0, numer)) == 0.0;
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
      vec4 seg = findSegment(uv.x);
      float numer = max(1.0, seg.y);
      float denom = max(1.0, seg.z);
      float barBase = seg.w;
      float localX = uv.x - seg.x;
      float barWidth = beatSize.x * numer;
      bool splitBeats = gridSplits >= 1.0;
      float splitFactor = splitBeats ? beatSize.x / gridSplits : barWidth;
      float beatDivisions = splitBeats ? gridSplits : 1.0;
      float barSplits = splitBeats ? gridSplits * numer : 1.0;
      float measureDivisions = barSplits * denom;
      vec2 lw = vec2(lineWidth / splitFactor, lineWidth * 1.5 / max(1.0, beatSize.y));
      vec2 relPos = vec2(mod(localX / splitFactor, 1.0), mod(uv.y / max(1.0, beatSize.y), 1.0));
      float globalBar = barBase + localX / barWidth;
      float measureNum = floor(globalBar / denom + 0.0001);
      vec3 col = mix(bar1Color, bar2Color, mod(measureNum, 2.0));
      float divisionNum = floor(localX / splitFactor) + barBase * barSplits;
      vec2 mults = calculateDivisionOpacity(divisionNum, barSplits, beatDivisions, measureDivisions);
      float multLeft = 1.0 - smoothstep(0.0, lw.x, relPos.x);
      float multRight = 1.0 - smoothstep(1.0, 1.0 - lw.x, relPos.x);
      float multVertical = 1.0 - min(smoothstep(0.0, lw.y, relPos.y), smoothstep(1.0, 1.0 - lw.y, relPos.y));
      col = mix(col, divisionColor, multLeft * mults.x);
      col = mix(col, divisionColor, multRight * mults.y);
      col = mix(col, divisionColor, multVertical);
      if (uv.x < 0.0 || uv.y < 0.0 || uv.y > beatSize.y * layerAmt)
        col = divisionColor;
      col = createTopBar(col, barUv, localX, numer, denom, barBase, barWidth, splitFactor, barSplits, beatDivisions, measureDivisions);
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
    gridSplits.value = [4];

    zoomDetail = 0;
    layerCount = 1;
    beatCount = 100;
    beatLength = 100;

    setSegments([
      {
        startPx: 0,
        numerator: 4,
        denominator: 4,
        barIndex: 0
      }
    ]);

    this.lineWidth.value = [lineWidth];
    topBarSize.value = [TimelineViewport.TOP_BAR_HEIGHT];
    layerHeight = TimelineViewport.LAYER_HEIGHT;
    fontTexture = BitmapData.fromFile('assets/ui/editors/camera-editor/timelineFont.png');
  }
}
#end
