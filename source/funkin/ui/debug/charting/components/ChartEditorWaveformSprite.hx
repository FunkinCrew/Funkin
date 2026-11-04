package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import funkin.audio.waveform.WaveformData;
import funkin.play.character.BaseCharacter.CharacterType;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

/**
 * An optimized waveform sprite that renders efficiently in the chart editor.
 */
@:nullSafety
@:access(funkin.Conductor)
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorWaveformSprite extends FlxSprite
{
  public var waveformData(default, set):Null<WaveformData> = null;

  function set_waveformData(value:Null<WaveformData>):Null<WaveformData>
  {
    if (waveformData != value) markDirty();
    return waveformData = value;
  }

  public var iconId:CharacterType;

  /**
   * The audio offset in milliseconds for this waveform sprite.
   */
  public var audioOffsetMs(default, set):Float = 0;

  function set_audioOffsetMs(value:Float):Float
  {
    if (audioOffsetMs != value) markDirty();
    return audioOffsetMs = value;
  }

  /**
   * How wide the waveform is drawn, in pixels. Separate from `width` because loading the bitmap sets that.
   */
  public var waveformWidth(default, set):Int = ChartEditorState.GRID_SIZE * 4;

  function set_waveformWidth(value:Int):Int
  {
    if (waveformWidth != value) markDirty();
    return waveformWidth = value;
  }

  /**
   * A filtered copy of the waveform, drawn on top in `overlayColor`. `null` for no overlay.
   */
  public var overlayData(default, set):Null<WaveformData> = null;

  function set_overlayData(value:Null<WaveformData>):Null<WaveformData>
  {
    if (overlayData != value) markDirty();
    return overlayData = value;
  }

  public var baseColor(default, set):FlxColor = FlxColor.WHITE;

  function set_baseColor(value:FlxColor):FlxColor
  {
    if (baseColor != value) markDirty();
    return baseColor = value;
  }

  /**
   * The brighter band in the middle of the base waveform.
   */
  public var coreColor(default, set):Null<FlxColor> = null;

  function set_coreColor(value:Null<FlxColor>):Null<FlxColor>
  {
    if (coreColor != value) markDirty();
    return coreColor = value;
  }

  public var overlayColor(default, set):FlxColor = FlxColor.WHITE;

  function set_overlayColor(value:FlxColor):FlxColor
  {
    if (overlayColor != value) markDirty();
    return overlayColor = value;
  }

  /**
   * The decoded audio this waveform came from, kept so filtered overlays can be made from it.
   */
  public var audioBuffer:Null<lime.media.AudioBuffer> = null;

  var chartEditorState:ChartEditorState;

  var chunkBitmap:Null<BitmapData> = null;
  var rowRect:Rectangle = new Rectangle();

  // The range of the current bitmap in grid-local pixels.
  var chunkTop:Float = 0;
  var chunkBottom:Float = -1;

  // The index of the current segment being processed.
  var segmentIndex:Int = 0;

  public function new(chartEditorState:ChartEditorState, waveformData:WaveformData, iconId:CharacterType)
  {
    super(0, 0);
    this.chartEditorState = chartEditorState;
    this.iconId = iconId;
    makeGraphic(1, 1, 0);
    this.waveformData = waveformData;
    antialiasing = false;
  }

  /**
   * Redraw the bitmap on the next refresh.
   */
  public function markDirty():Void
  {
    chunkBottom = chunkTop - 1;
  }

  override function set_visible(value:Bool):Bool
  {
    if (visible != value) markDirty();
    return super.set_visible(value);
  }

  /**
   * Follow the grid, and redraw the bitmap if the view left the built chunk.
   * @param gridY The current screen position of the top of the grid.
   */
  public function refresh(gridY:Float):Void
  {
    if (!visible) return;

    var viewTop:Float = ChartEditorState.MENU_BAR_HEIGHT - gridY;
    var viewBottom:Float = FlxG.height - ChartEditorState.PLAYBAR_HEIGHT - gridY;
    if (viewTop < chunkTop || viewBottom > chunkBottom)
    {
      // Half a view of margin on each side keeps the vertex count down while scrolling still rarely rebuilds.
      var margin:Float = (viewBottom - viewTop) * 0.5;
      buildChunk(Math.ffloor(viewTop - margin), Math.fceil(viewBottom + margin));
    }

    this.y = gridY + chunkTop;
  }

  function buildChunk(top:Float, bottom:Float):Void
  {
    chunkTop = top;
    chunkBottom = bottom;
    segmentIndex = 0;

    var bitmapWidth:Int = Std.int(Math.max(1, waveformWidth));
    var bitmapHeight:Int = Std.int(Math.max(1, bottom - top));

    var bitmap:Null<BitmapData> = chunkBitmap;
    if (bitmap == null || bitmap.width != bitmapWidth || bitmap.height != bitmapHeight)
    {
      bitmap = new BitmapData(bitmapWidth, bitmapHeight, true, 0);
      chunkBitmap = bitmap;
      loadGraphic(FlxGraphic.fromBitmapData(bitmap, false, null, false));
    }
    else
    {
      bitmap.fillRect(bitmap.rect, 0);
    }

    var from:Float = Math.max(0, top);
    var to:Float = Math.min(bottom, chartEditorState.songLengthInPixels);
    if (to <= from) return;

    bitmap.lock();
    var base:Null<WaveformData> = waveformData;
    var overlay:Null<WaveformData> = overlayData;
    if (base != null)
    {
      var layerBase:FlxColor = baseColor;
      var layerCore:Null<FlxColor> = coreColor;
      if (overlay != null)
      {
        layerBase.alphaFloat = UNDER_OVERLAY_ALPHA;
        if (layerCore != null)
        {
          var faded:FlxColor = layerCore;
          faded.alphaFloat = UNDER_OVERLAY_ALPHA;
          layerCore = faded;
        }
      }
      drawLayer(bitmap, base, layerBase, layerCore, from, to);
    }

    if (overlay != null) drawLayer(bitmap, overlay, overlayColor, null, from, to);
    bitmap.unlock();
  }

  /**
   * How wide the core is, compared to the full waveform in each row.
   */
  static final CORE_WIDTH:Float = 0.4;

  /**
   * How much of the width the loudest point of the track reaches, leaving a little room at the edges.
   */
  static final FIT_WIDTH:Float = 0.9;

  /**
   * How opaque the original waveform is while a filtered overlay is drawn over it.
   */
  static final UNDER_OVERLAY_ALPHA:Float = 0.6;

  /**
   * Draw one waveform into the chunk bitmap, one pixel row at a time.
   * @param core If set, a narrower band of this color is drawn in the middle of each row.
   */
  function drawLayer(bitmap:BitmapData, data:WaveformData, color:FlxColor, core:Null<FlxColor>, from:Float, to:Float):Void
  {
    segmentIndex = 0;

    var stepHeight:Float = ChartEditorTimeScale.STEP_HEIGHT;
    var halfWidth:Float = bitmap.width / 2;
    var maxValue:Int = data.maxSampleValue();
    var fitValue:Float = data.peakValue();
    var pointsPerMs:Float = data.pointsPerSecond() / Constants.MS_PER_SEC;
    var levelCount:Int = data.mipLevelCount();
    var timeOffset:Float = Conductor.instance.instrumentalOffset + audioOffsetMs;

    var rowY:Float = from;
    var startIndex:Float = (rowToMs(rowY, stepHeight) - timeOffset) * pointsPerMs;

    while (rowY < to)
    {
      var nextY:Float = Math.min(rowY + 1, to);
      var endIndex:Float = (rowToMs(nextY, stepHeight) - timeOffset) * pointsPerMs;

      // Pick the level where this row covers at most two points.
      var level:Int = 0;
      var count:Float = endIndex - startIndex;
      while (count >= 2 && level < levelCount - 1)
      {
        count *= 0.5;
        level++;
      }

      var mip = data.getMipLevel(level);
      var mipLength:Int = mip.length >> 1;
      var low:Int = Math.floor(startIndex) >> level;
      var high:Int = Math.floor(endIndex) >> level;

      var min:Int = 0;
      var max:Int = 0;
      if (high >= 0 && low < mipLength)
      {
        if (low < 0) low = 0;
        if (high >= mipLength) high = mipLength - 1;
        min = maxValue;
        max = -maxValue;
        for (i in low...high + 1)
        {
          if (mip[i * 2] < min) min = mip[i * 2];
          if (mip[i * 2 + 1] > max) max = mip[i * 2 + 1];
        }
      }

      // Mirrored around the center using the peak size, so both edges match.
      var peak:Float = Math.min(Math.max(max, -min) / fitValue, 1.0) * halfWidth * FIT_WIDTH;
      var left:Int = Std.int(halfWidth - Math.max(peak, 0.5));
      var right:Int = Std.int(Math.fceil(halfWidth + Math.max(peak, 0.5)));

      rowRect.setTo(left, rowY - chunkTop, right - left, 1);
      bitmap.fillRect(rowRect, color);

      var corePeak:Float = peak * CORE_WIDTH;
      if (core != null && corePeak >= 1)
      {
        var coreLeft:Int = Std.int(halfWidth - corePeak);
        var coreRight:Int = Std.int(Math.fceil(halfWidth + corePeak));
        rowRect.setTo(coreLeft, rowY - chunkTop, coreRight - coreLeft, 1);
        bitmap.fillRect(rowRect, core);
      }

      rowY = nextY;
      startIndex = endIndex;
    }
  }

  /**
   * The song time at a grid row.
   */
  inline function rowToMs(rowY:Float, stepHeight:Float):Float
  {
    return ChartEditorTimeScale.pixelsToMs(rowY);
  }

  /**
   * Same result as `Conductor.getStepTimeInMs`, but walks forward from the last time change instead of searching from the start.
   */
  function stepToMs(step:Float):Float
  {
    var timeChanges = Conductor.instance.timeChanges;
    if (timeChanges.length == 0) return step * Conductor.instance.stepLengthMs;

    while (segmentIndex + 1 < timeChanges.length && step >= timeChanges[segmentIndex + 1].beatTime * Constants.STEPS_PER_BEAT)
    {
      segmentIndex++;
    }

    var timeChange = timeChanges[segmentIndex];
    var stepLengthMs:Float = ((Constants.SECS_PER_MIN / timeChange.bpm) * Constants.MS_PER_SEC * (4 / timeChange.timeSignatureDen)) / Constants.STEPS_PER_BEAT;
    return timeChange.timeStamp + (step - timeChange.beatTime * Constants.STEPS_PER_BEAT) * stepLengthMs;
  }
}
#end
