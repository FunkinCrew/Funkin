package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import funkin.ui.debug.charting.handlers.ChartEditorThemeHandler;

/**
 * Draws some grid lines for the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
@:access(funkin.Conductor)
class ChartEditorGridLines
{
  static final EPSILON:Float = 0.0001;

  /**
   * Backing for contrast on the waveforms.
   */
  public var backing(default, null):FlxSprite = new FlxSprite();

  /**
   * The lines dictating the measures and beats.
   */
  public var lines(default, null):FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();

  /**
   * BPM/Sig change markers.
   */
  public var markers(default, null):FlxSpriteGroup = new FlxSpriteGroup();

  // FlxText has no background here, so each tag is a solid box with the text drawn over it.
  var markerBacks:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();
  var markerTexts:FlxTypedSpriteGroup<FlxText> = new FlxTypedSpriteGroup<FlxText>();

  static final MARKER_PADDING:Float = 4;

  static final MARKER_GAP:Float = 2;
  static final BPM_MARKER_COLOR:FlxColor = 0xFF8C1C1C;
  static final SIGNATURE_MARKER_COLOR:FlxColor = 0xFF7A6414;

  var chartEditorState:ChartEditorState;

  var lineColor:FlxColor = FlxColor.WHITE;

  // The range of the grid that has been built.
  var builtTop:Float = 0;
  var builtBottom:Float = -1;

  public function new(chartEditorState:ChartEditorState)
  {
    this.chartEditorState = chartEditorState;
    backing.antialiasing = false;
    backing.alpha = chartEditorState.gridBackingAlpha;
    // Backs first, so the text draws over them.
    markers.add(markerBacks);
    markers.add(markerTexts);
    updateTheme();
  }

  /**
   * Reload the backing graphic and line color after the theme changes.
   */
  public function updateTheme():Void
  {
    var bitmap = chartEditorState.gridBitmap;
    if (bitmap != null) backing.loadGraphic(bitmap);

    lineColor = ChartEditorThemeHandler.getGridLineColor(chartEditorState.currentTheme);
    lines.forEach(line -> line.color = lineColor);
  }

  /**
   * Refresh the grid lines, rebuilding them if necessary.
   * @param force Rebuild even if the view is still inside the built range.
   */
  public function refresh(force:Bool = false):Void
  {
    var grid = chartEditorState.gridTiledSprite;
    if (grid == null) return;

    var viewTopScreen:Float = ChartEditorState.MENU_BAR_HEIGHT;
    var viewBottomScreen:Float = FlxG.height - ChartEditorState.PLAYBAR_HEIGHT;

    // Adjust the backing to cover the visible portion of the grid.
    backing.scale.set(1, (viewBottomScreen - viewTopScreen) / ChartEditorThemeHandler.BACKING_PIXELS);
    backing.updateHitbox();
    backing.setPosition(grid.x, viewTopScreen);

    lines.setPosition(grid.x, grid.y);
    markers.setPosition(grid.x, grid.y);

    var viewTop:Float = viewTopScreen - grid.y;
    var viewBottom:Float = viewBottomScreen - grid.y;
    if (!force && viewTop >= builtTop && viewBottom <= builtBottom) return;

    var margin:Float = FlxG.height * 0.5;
    rebuild(viewTop - margin, viewBottom + margin);
  }

  function rebuild(top:Float, bottom:Float):Void
  {
    lines.forEachAlive(line -> line.kill());
    markerBacks.forEachAlive(back -> back.kill());
    markerTexts.forEachAlive(text -> text.kill());

    builtTop = top;
    builtBottom = bottom;

    // Not clamped to the song, the first time change carries on before it and the last one after it.
    var stepHeight:Float = ChartEditorState.STEP_HEIGHT;
    var topStep:Float = top / stepHeight;
    var bottomStep:Float = bottom / stepHeight;
    if (bottomStep <= topStep) return;

    var conductor:Conductor = Conductor.instance;
    var timeChanges = conductor.timeChanges;

    if (timeChanges.length == 0)
    {
      buildSegment(topStep, bottomStep, 0, 0, conductor.timeSignatureNumerator);
      return;
    }

    for (i in 0...timeChanges.length)
    {
      var timeChange = timeChanges[i];
      var start:Float = timeChange.beatTime * Constants.STEPS_PER_BEAT;
      var rangeStart:Float = (i == 0) ? topStep : start;
      var rangeEnd:Float = (i + 1 < timeChanges.length) ? timeChanges[i + 1].beatTime * Constants.STEPS_PER_BEAT : bottomStep;
      if (rangeEnd <= topStep || rangeStart >= bottomStep) continue;

      var measureStart:Float = conductor.getTimeInMeasures(timeChange.timeStamp);
      buildSegment(Math.max(rangeStart, topStep), Math.min(rangeEnd, bottomStep), start, measureStart, timeChange.timeSignatureNum);

      if (start >= topStep && start <= bottomStep) addTimeChangeMarkers(timeChanges, i, start);
    }
  }

  /**
   * Add the BPM and time signature markers for a specific time change.
   */
  function addTimeChangeMarkers(timeChanges:Array<funkin.data.song.SongData.SongTimeChange>, index:Int, step:Float):Void
  {
    var timeChange = timeChanges[index];
    var previous = (index > 0) ? timeChanges[index - 1] : null;

    var right:Float = markers.x - ChartEditorState.GRID_SIZE - MARKER_GAP;
    var lineY:Float = markers.y + step * ChartEditorState.STEP_HEIGHT;

    // Stacked instead of side by side, so the tags stay narrow enough to fit between the note preview and the grid.
    var top:Null<Float> = null;

    if (previous == null || previous.bpm != timeChange.bpm)
    {
      top = addMarker(formatBpm(timeChange.bpm), BPM_MARKER_COLOR, right, top, lineY);
    }

    if (previous == null || previous.timeSignatureNum != timeChange.timeSignatureNum || previous.timeSignatureDen != timeChange.timeSignatureDen)
    {
      addMarker('${timeChange.timeSignatureNum}/${timeChange.timeSignatureDen}', SIGNATURE_MARKER_COLOR, right, top, lineY);
    }
  }

  /**
   * Add one tag with its right edge at `right`.
   * Placed at `top` if given, otherwise centered on `centerY`.
   * @return Where the next tag below this one should start.
   */
  function addMarker(text:String, color:FlxColor, right:Float, top:Null<Float>, centerY:Float):Float
  {
    var label:FlxText = markerTexts.recycle(makeMarkerText);
    label.text = text;

    var back:FlxSprite = markerBacks.recycle(makeMarkerBack);
    back.setGraphicSize(label.width + MARKER_PADDING * 2, label.height);
    back.updateHitbox();
    back.color = color;
    back.setPosition(right - back.width, top ?? (centerY - back.height / 2));

    label.setPosition(back.x + MARKER_PADDING, back.y);
    return back.y + back.height + MARKER_GAP;
  }

  function makeMarkerText():FlxText
  {
    var label:FlxText = new FlxText(0, 0, 0, '', 14);
    label.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 14, FlxColor.WHITE);
    return label;
  }

  function makeMarkerBack():FlxSprite
  {
    return new FunkinSprite().makeSolidColor(2, 2, FlxColor.WHITE);
  }

  /**
   * BPM with three decimals, like `150.000`.
   */
  static function formatBpm(bpm:Float):String
  {
    var thousandths:Int = Math.round(bpm * 1000);
    var whole:Int = Std.int(thousandths / 1000);
    var fraction:String = Std.string(Std.int(Math.abs(thousandths % 1000)));
    while (fraction.length < 3)
      fraction = '0' + fraction;
    return '${whole}.${fraction}';
  }

  /**
   * Build the lines between two steps inside one time change.
   */
  function buildSegment(from:Float, to:Float, start:Float, measureStart:Float, numerator:Int):Void
  {
    var beatSteps:Float = Constants.STEPS_PER_BEAT;
    var measureSteps:Float = numerator * Constants.STEPS_PER_BEAT;

    // Measures are counted the same way as the measure numbers, so the two always line up.
    var measure:Int = Math.ceil(measureStart + (from - start) / measureSteps - EPSILON);
    var measureStep:Float = start + (measure - measureStart) * measureSteps;
    while (measureStep < to - EPSILON)
    {
      addLine(measureStep, ChartEditorThemeHandler.GRID_MEASURE_LINE_WIDTH, ChartEditorThemeHandler.GRID_MEASURE_LINE_ALPHA);
      measure++;
      measureStep = start + (measure - measureStart) * measureSteps;
    }

    if (!chartEditorState.showBeatLines) return;
    if (beatSteps * ChartEditorState.STEP_HEIGHT < ChartEditorThemeHandler.GRID_MIN_BEAT_PIXELS) return;

    // Beats are counted from the start of the segment.
    var beat:Int = Math.ceil(from / beatSteps - EPSILON);
    while (beat * beatSteps < to - EPSILON)
    {
      var beatStep:Float = beat * beatSteps;
      var measurePosition:Float = measureStart + (beatStep - start) / measureSteps;
      if (Math.abs(measurePosition - Math.round(measurePosition)) >= EPSILON)
      {
        addLine(beatStep, ChartEditorThemeHandler.GRID_BEAT_LINE_WIDTH, ChartEditorThemeHandler.GRID_BEAT_LINE_ALPHA);
      }
      beat++;
    }
  }

  function addLine(step:Float, thickness:Int, alpha:Float):Void
  {
    var line:FlxSprite = lines.recycle(makeLine);
    line.setGraphicSize(ChartEditorState.GRID_SIZE * ChartEditorThemeHandler.TOTAL_COLUMN_COUNT, thickness);
    line.updateHitbox();
    line.color = lineColor;
    line.alpha = alpha;
    line.setPosition(lines.x, Math.round(lines.y + step * ChartEditorState.STEP_HEIGHT) - Std.int(thickness / 2));
  }

  function makeLine():FlxSprite
  {
    return new FunkinSprite().makeSolidColor(2, 2, FlxColor.WHITE);
  }
}
#end
