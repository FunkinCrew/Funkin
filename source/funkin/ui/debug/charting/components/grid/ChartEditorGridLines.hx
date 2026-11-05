package funkin.ui.debug.charting.components.grid;

#if FEATURE_CHART_EDITOR
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import funkin.ui.debug.charting.handlers.editor.ChartEditorThemeHandler;

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
   * The vertical lines between the opponent, player and event columns. Drawn above the waveforms so a centered waveform can't hide them.
   */
  public var dividers(default, null):FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();

  /**
   * BPM/Sig change markers.
   */
  public var markers(default, null):FlxSpriteGroup = new FlxSpriteGroup();

  // FlxText has no background here, so each tag is a solid box with the text drawn over it.
  var markerBacks:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();
  var markerTexts:FlxTypedSpriteGroup<FlxText> = new FlxTypedSpriteGroup<FlxText>();

  static final MARKER_PADDING:Float = 4;

  /**
   * Which time change each shown tag belongs to.
   */
  var markerIndexes:Map<FlxSprite, Int> = [];

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
    for (i in 0...4)
    {
      var edge:FlxSprite = new FunkinSprite().makeSolidColor(2, 2, FlxColor.WHITE);
      edge.visible = false;
      selectionEdges.push(edge);
      markers.add(edge);
    }

    for (i in 1...ChartEditorThemeHandler.TOTAL_COLUMN_COUNT)
    {
      if (i % ChartEditorState.STRUMLINE_SIZE == 0) dividers.add(new FunkinSprite().makeSolidColor(2, 2, FlxColor.WHITE));
    }
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

    var dividerColor:FlxColor = ChartEditorThemeHandler.getSideDividerColor(chartEditorState.currentTheme);
    dividers.forEach(divider -> divider.color = dividerColor);
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

    var dividerWidth:Int = ChartEditorThemeHandler.GRID_SIDE_DIVIDER_WIDTH;
    for (i in 0...dividers.members.length)
    {
      var divider:FlxSprite = dividers.members[i];
      divider.setGraphicSize(dividerWidth, viewBottomScreen - viewTopScreen);
      divider.updateHitbox();
      divider.setPosition(grid.x + ChartEditorState.GRID_SIZE * ChartEditorState.STRUMLINE_SIZE * (i + 1) - dividerWidth / 2, viewTopScreen);
    }

    lines.setPosition(grid.x, grid.y);
    markers.setPosition(grid.x, grid.y);

    var viewTop:Float = viewTopScreen - grid.y;
    var viewBottom:Float = viewBottomScreen - grid.y;
    if (force || viewTop < builtTop || viewBottom > builtBottom)
    {
      var margin:Float = FlxG.height * 0.5;
      rebuild(viewTop - margin, viewBottom + margin);
    }

    refreshSelectionOutline();
  }

  /**
   * The box drawn around the tags of the time change picked in the Timing panel.
   */
  var selectionEdges:Array<FlxSprite> = [];

  static final SELECTION_EDGE:Float = 2;

  function refreshSelectionOutline():Void
  {
    var selected:Int = chartEditorState.selectedTimeChangeIndex;
    var left:Float = Math.POSITIVE_INFINITY;
    var top:Float = Math.POSITIVE_INFINITY;
    var right:Float = Math.NEGATIVE_INFINITY;
    var bottom:Float = Math.NEGATIVE_INFINITY;
    if (selected >= 0)
    {
      for (back in markerIndexes.keys())
      {
        if (!back.alive || markerIndexes.get(back) != selected) continue;
        left = Math.min(left, back.x);
        top = Math.min(top, back.y);
        right = Math.max(right, back.x + back.width);
        bottom = Math.max(bottom, back.y + back.height);
      }
    }

    var show:Bool = left != Math.POSITIVE_INFINITY;
    for (edge in selectionEdges) edge.visible = show;
    if (!show) return;

    var pad:Float = SELECTION_EDGE;
    left -= pad;
    top -= pad;
    right += pad;
    bottom += pad;
    placeEdge(selectionEdges[0], left, top, right - left, SELECTION_EDGE);
    placeEdge(selectionEdges[1], left, bottom - SELECTION_EDGE, right - left, SELECTION_EDGE);
    placeEdge(selectionEdges[2], left, top, SELECTION_EDGE, bottom - top);
    placeEdge(selectionEdges[3], right - SELECTION_EDGE, top, SELECTION_EDGE, bottom - top);
  }

  static function placeEdge(edge:FlxSprite, x:Float, y:Float, width:Float, height:Float):Void
  {
    edge.setGraphicSize(Std.int(Math.max(1, width)), Std.int(Math.max(1, height)));
    edge.updateHitbox();
    edge.setPosition(x, y);
  }

  function rebuild(top:Float, bottom:Float):Void
  {
    lines.forEachAlive(line -> line.kill());
    markerBacks.forEachAlive(back -> back.kill());
    markerIndexes.clear();
    markerTexts.forEachAlive(text -> text.kill());

    builtTop = top;
    builtBottom = bottom;

    // Not clamped to the song, the first time change carries on before it and the last one after it.
    var topStep:Float = ChartEditorTimeScale.pixelsToStep(top);
    var bottomStep:Float = ChartEditorTimeScale.pixelsToStep(bottom);
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
    var lineY:Float = markers.y + ChartEditorTimeScale.stepToPixels(step);

    // Stacked instead of side by side, so the tags stay narrow enough to fit between the note preview and the grid.
    var top:Null<Float> = null;

    if (previous == null || previous.bpm != timeChange.bpm)
    {
      top = addMarker(formatBpm(timeChange.bpm), BPM_MARKER_COLOR, right, top, lineY, index);
    }

    if (previous == null || previous.timeSignatureNum != timeChange.timeSignatureNum || previous.timeSignatureDen != timeChange.timeSignatureDen)
    {
      addMarker('${timeChange.timeSignatureNum}/${timeChange.timeSignatureDen}', SIGNATURE_MARKER_COLOR, right, top, lineY, index);
    }
  }

  /**
   * Add one tag with its right edge at `right`.
   * Placed at `top` if given, otherwise centered on `centerY`.
   * @return Where the next tag below this one should start.
   */
  function addMarker(text:String, color:FlxColor, right:Float, top:Null<Float>, centerY:Float, index:Int):Float
  {
    var label:FlxText = markerTexts.recycle(makeMarkerText);
    label.text = text;

    var back:FlxSprite = markerBacks.recycle(makeMarkerBack);
    back.setGraphicSize(label.width + MARKER_PADDING * 2, label.height);
    back.updateHitbox();
    back.color = color;
    back.setPosition(right - back.width, top ?? (centerY - back.height / 2));

    label.setPosition(back.x + MARKER_PADDING, back.y);
    markerIndexes.set(back, index);
    return back.y + back.height + MARKER_GAP;
  }

  /**
   * The time change whose BPM or time signature tag is under the mouse, or -1.
   */
  public function timeChangeUnderMouse():Int
  {
    for (back in markerIndexes.keys())
    {
      if (back.alive && back.visible && FlxG.mouse.overlaps(back)) return markerIndexes.get(back) ?? -1;
    }
    return -1;
  }

  function makeMarkerText():FlxText
  {
    var label:FlxText = new haxe.ui.backend.flixel.HiResFlxText(0, 0, 0, '', 14);
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
    if (ChartEditorTimeScale.stepToPixels(from + beatSteps) - ChartEditorTimeScale.stepToPixels(from) < ChartEditorThemeHandler.GRID_MIN_BEAT_PIXELS) return;

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
    line.setPosition(lines.x, Math.round(lines.y + ChartEditorTimeScale.stepToPixels(step)) - Std.int(thickness / 2));
  }

  function makeLine():FlxSprite
  {
    return new FunkinSprite().makeSolidColor(2, 2, FlxColor.WHITE);
  }
}
#end
