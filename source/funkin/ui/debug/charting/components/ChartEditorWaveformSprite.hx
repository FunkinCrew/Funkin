package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import flixel.util.FlxColor;
import funkin.audio.waveform.WaveformData;
import funkin.graphics.rendering.MeshRender;
import funkin.play.character.BaseCharacter.CharacterType;

/**
 * An optimized waveform sprite that renders efficiently in the chart editor.
 */
@:nullSafety
@:access(funkin.Conductor)
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorWaveformSprite extends MeshRender
{
  /**
   * Vertical distance between two rows of vertices, in pixels.
   */
  static final ROW_PIXELS:Float = 1;

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

  var chartEditorState:ChartEditorState;

  // The range of the current mesh in grid-local pixels.
  var chunkTop:Float = 0;
  var chunkBottom:Float = -1;

  // The index of the current segment being processed in the mesh.
  var segmentIndex:Int = 0;

  public function new(chartEditorState:ChartEditorState, waveformData:WaveformData, iconId:CharacterType)
  {
    super(0, 0, FlxColor.WHITE);
    this.chartEditorState = chartEditorState;
    this.iconId = iconId;
    this.waveformData = waveformData;
  }

  /**
   * Rebuild the mesh on the next refresh.
   */
  public function markDirty():Void
  {
    chunkBottom = chunkTop - 1;
  }

  override function set_width(value:Float):Float
  {
    if (width != value) markDirty();
    return super.set_width(value);
  }

  override function set_visible(value:Bool):Bool
  {
    if (visible != value) markDirty();
    return super.set_visible(value);
  }

  /**
   * Follow the grid, and rebuild the mesh if the view left the built chunk.
   * @param gridY The current screen position of the top of the grid.
   */
  public function refresh(gridY:Float):Void
  {
    this.y = gridY;
    if (!visible) return;

    var viewTop:Float = ChartEditorState.MENU_BAR_HEIGHT - gridY;
    var viewBottom:Float = FlxG.height - ChartEditorState.PLAYBAR_HEIGHT - gridY;
    if (viewTop >= chunkTop && viewBottom <= chunkBottom) return;

    // Half a view of margin on each side keeps the vertex count down while scrolling still rarely rebuilds.
    var margin:Float = (viewBottom - viewTop) * 0.5;
    buildChunk(viewTop - margin, viewBottom + margin);
  }

  function buildChunk(top:Float, bottom:Float):Void
  {
    chunkTop = top;
    chunkBottom = bottom;
    vertex_count = 0;
    index_count = 0;
    segmentIndex = 0;

    var data:Null<WaveformData> = waveformData;

    var from:Float = Math.ffloor(Math.max(0, top));
    var to:Float = Math.min(bottom, chartEditorState.songLengthInPixels);

    if (data != null && to > from)
    {
      var stepHeight:Float = ChartEditorState.STEP_HEIGHT;
      var halfWidth:Float = width / 2;
      var maxValue:Int = data.maxSampleValue();
      var pointsPerMs:Float = data.pointsPerSecond() / Constants.MS_PER_SEC;
      var levelCount:Int = data.mipLevelCount();
      var timeOffset:Float = Conductor.instance.instrumentalOffset + audioOffsetMs;

      var rowY:Float = from;
      var startIndex:Float = (stepToMs(rowY / stepHeight) - timeOffset) * pointsPerMs;

      while (rowY < to)
      {
        var nextY:Float = Math.min(rowY + ROW_PIXELS, to);
        var endIndex:Float = (stepToMs(nextY / stepHeight) - timeOffset) * pointsPerMs;

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
        var peak:Float = Math.min(Math.max(max, -min) / maxValue, 1.0) * halfWidth;
        if (peak < 0.5) peak = 0.5;
        var left:Float = halfWidth - peak;
        var right:Float = halfWidth + peak;

        // Every row is its own rectangle, so peaks stay sharp instead of blending into the next row.
        var topLeft:Int = build_vertex(left, rowY);
        var topRight:Int = build_vertex(right, rowY);
        var bottomRight:Int = build_vertex(right, nextY);
        var bottomLeft:Int = build_vertex(left, nextY);
        add_quad(topLeft, topRight, bottomRight, bottomLeft);

        rowY = nextY;
        startIndex = endIndex;
      }
    }

    vertices.length = vertex_count * 2;
    uvtData.length = vertex_count * 2;
    indices.length = index_count;
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
