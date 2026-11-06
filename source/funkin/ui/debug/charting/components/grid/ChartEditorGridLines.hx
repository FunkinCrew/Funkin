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
   * The vertical lines between the opponent, player and event columns.
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

  /**
   * Sub-beat lines and their tags. Drawn above the beat lines, since a sub-beat can sit right on a beat.
   */
  public var subBeats(default, null):FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();

  static final SUB_BEAT_COLOR:FlxColor = 0xFF4FC3F7;

  static final SUB_BEAT_ALPHA:Float = 0.9;

  static final SUB_BEAT_LINE_WIDTH:Int = 3;

  /**
   * The size of the tag right of the grid that marks each sub-beat.
   */
  static final SUB_BEAT_TAG_WIDTH:Int = 12;

  static final SUB_BEAT_TAG_HEIGHT:Int = 8;

  /**
   * Measure lines closer than this, in pixels, are thinned out to every few measures.
   */
  static final MIN_MEASURE_PIXELS:Float = 6;

  /**
   * How many lines of the pool are used. Reused by index, recycling searched the group for every line.
   */
  var usedLines:Int = 0;

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
    subBeats.setPosition(grid.x, grid.y);
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
    // Four edges per picked time change, made as needed.
    var used:Int = 0;
    for (selected in chartEditorState.timeChangeItems.selectedIndexes())
    {
      var left:Float = Math.POSITIVE_INFINITY;
      var top:Float = Math.POSITIVE_INFINITY;
      var right:Float = Math.NEGATIVE_INFINITY;
      var bottom:Float = Math.NEGATIVE_INFINITY;
      for (back in markerIndexes.keys())
      {
        if (!back.alive || markerIndexes.get(back) != selected) continue;
        left = Math.min(left, back.x);
        top = Math.min(top, back.y);
        right = Math.max(right, back.x + back.width);
        bottom = Math.max(bottom, back.y + back.height);
      }
      if (left == Math.POSITIVE_INFINITY) continue;

      while (selectionEdges.length < used + 4)
      {
        var edge:FlxSprite = new FunkinSprite().makeSolidColor(2, 2, FlxColor.WHITE);
        selectionEdges.push(edge);
        markers.add(edge);
      }

      var pad:Float = SELECTION_EDGE;
      left -= pad;
      top -= pad;
      right += pad;
      bottom += pad;
      placeEdge(selectionEdges[used], left, top, right - left, SELECTION_EDGE);
      placeEdge(selectionEdges[used + 1], left, bottom - SELECTION_EDGE, right - left, SELECTION_EDGE);
      placeEdge(selectionEdges[used + 2], left, top, SELECTION_EDGE, bottom - top);
      placeEdge(selectionEdges[used + 3], right - SELECTION_EDGE, top, SELECTION_EDGE, bottom - top);
      for (i in used...used + 4) selectionEdges[i].visible = true;
      used += 4;
    }
    for (i in used...selectionEdges.length) selectionEdges[i].visible = false;
  }

  /**
   * The time changes a selection box covers. The box has to reach the tags left of the grid.
   */
  public function timeChangesInBox(boxLeft:Float, startMs:Float, endMs:Float):Array<Int>
  {
    var result:Array<Int> = [];
    if (boxLeft > markers.x - ChartEditorState.GRID_SIZE - MARKER_GAP) return result;
    var timeChanges = Conductor.instance.timeChanges;
    for (i in 0...timeChanges.length)
    {
      if (timeChanges[i].timeStamp >= startMs && timeChanges[i].timeStamp <= endMs) result.push(i);
    }
    return result;
  }

  static function placeEdge(edge:FlxSprite, x:Float, y:Float, width:Float, height:Float):Void
  {
    edge.setGraphicSize(Std.int(Math.max(1, width)), Std.int(Math.max(1, height)));
    edge.updateHitbox();
    edge.setPosition(x, y);
  }

  function rebuild(top:Float, bottom:Float):Void
  {
    usedLines = 0;
    markerBacks.forEachAlive(back -> back.kill());
    markerIndexes.clear();
    markerTexts.forEachAlive(text -> text.kill());

    builtTop = top;
    builtBottom = bottom;

    // Not clamped to the song, the first time change carries on before it and the last one after it.
    var topStep:Float = ChartEditorTimeScale.pixelsToStep(top);
    var bottomStep:Float = ChartEditorTimeScale.pixelsToStep(bottom);
    if (bottomStep <= topStep)
    {
      killUnusedLines();
      return;
    }
    buildSubBeats(topStep, bottomStep);

    var conductor:Conductor = Conductor.instance;
    var timeChanges = conductor.timeChanges;

    if (timeChanges.length == 0)
    {
      buildSegment(topStep, bottomStep, 0, 0, conductor.timeSignatureNumerator);
      killUnusedLines();
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
    killUnusedLines();
  }

  function killUnusedLines():Void
  {
    for (i in usedLines...lines.members.length)
    {
      var line:Null<FlxSprite> = lines.members[i];
      if (line != null && line.alive) line.kill();
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
    var measurePixels:Float = ChartEditorTimeScale.stepToPixels(from + measureSteps) - ChartEditorTimeScale.stepToPixels(from);
    var stride:Int = (measurePixels > 0 && measurePixels < MIN_MEASURE_PIXELS) ? Math.ceil(MIN_MEASURE_PIXELS / measurePixels) : 1;
    while (measureStep < to - EPSILON)
    {
      if (stride == 1 || ((measure % stride) + stride) % stride == 0)
      {
        addLine(measureStep, ChartEditorThemeHandler.GRID_MEASURE_LINE_WIDTH, ChartEditorThemeHandler.GRID_MEASURE_LINE_ALPHA);
      }
      measure++;
      measureStep = start + (measure - measureStart) * measureSteps;
    }

    var showBeats:Bool = chartEditorState.showBeatLines
      && ChartEditorTimeScale.stepToPixels(from + beatSteps) - ChartEditorTimeScale.stepToPixels(from) >= ChartEditorThemeHandler.GRID_MIN_BEAT_PIXELS;

    if (showBeats)
    {
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

    buildSnapLines(from, to, start, measureStart, measureSteps, showBeats);
  }

  /**
   * Dim lines on every snap of the current note snap.
   */
  function buildSnapLines(from:Float, to:Float, start:Float, measureStart:Float, measureSteps:Float, showBeats:Bool):Void
  {
    if (!chartEditorState.showSnapLines) return;
    var snapSteps:Float = chartEditorState.noteSnapRatio;
    if (snapSteps <= 0) return;
    if (ChartEditorTimeScale.stepToPixels(from + snapSteps) - ChartEditorTimeScale.stepToPixels(from) < ChartEditorThemeHandler.GRID_MIN_SNAP_PIXELS) return;

    var beatSteps:Float = Constants.STEPS_PER_BEAT;

    var snap:Int = Math.ceil(from / snapSteps - EPSILON);
    while (snap * snapSteps < to - EPSILON)
    {
      var snapStep:Float = snap * snapSteps;
      snap++;
      var measurePosition:Float = measureStart + (snapStep - start) / measureSteps;
      if (Math.abs(measurePosition - Math.round(measurePosition)) < EPSILON) continue;
      if (showBeats && Math.abs(snapStep / beatSteps - Math.round(snapStep / beatSteps)) < EPSILON) continue;
      addLine(snapStep, ChartEditorThemeHandler.GRID_SNAP_LINE_WIDTH, ChartEditorThemeHandler.GRID_SNAP_LINE_ALPHA);
    }
  }

  function addLine(step:Float, thickness:Int, alpha:Float):Void
  {
    var line:FlxSprite;
    if (usedLines < lines.members.length && lines.members[usedLines] != null)
    {
      line = lines.members[usedLines];
      if (!line.alive) line.revive();
    }
    else
    {
      line = makeLine();
      lines.add(line);
    }
    usedLines++;
    line.setGraphicSize(ChartEditorState.GRID_SIZE * ChartEditorThemeHandler.TOTAL_COLUMN_COUNT, thickness);
    line.updateHitbox();
    line.color = lineColor;
    line.alpha = alpha;
    line.setPosition(lines.x, Math.round(lines.y + ChartEditorTimeScale.stepToPixels(step)) - Std.int(thickness / 2));
  }

  function buildSubBeats(topStep:Float, bottomStep:Float):Void
  {
    subBeats.forEachAlive(sprite -> sprite.kill());
    var gridWidth:Int = ChartEditorState.GRID_SIZE * ChartEditorThemeHandler.TOTAL_COLUMN_COUNT;
    var subBeatTimes:Array<Float> = chartEditorState.currentSubBeats();
    for (i in 0...subBeatTimes.length)
    {
      var step:Float = Conductor.instance.getTimeInSteps(subBeatTimes[i]);
      if (step < topStep || step > bottomStep) continue;

      var color:FlxColor = chartEditorState.subBeatItems.contains(i) ? FlxColor.WHITE : SUB_BEAT_COLOR;
      var y:Float = Math.round(subBeats.y + ChartEditorTimeScale.stepToPixels(step));

      var line:FlxSprite = subBeats.recycle(makeLine);
      line.setGraphicSize(gridWidth, SUB_BEAT_LINE_WIDTH);
      line.updateHitbox();
      line.color = color;
      line.alpha = SUB_BEAT_ALPHA;
      line.setPosition(subBeats.x, y - Std.int(SUB_BEAT_LINE_WIDTH / 2));

      var tag:FlxSprite = subBeats.recycle(makeLine);
      tag.setGraphicSize(SUB_BEAT_TAG_WIDTH, SUB_BEAT_TAG_HEIGHT);
      tag.updateHitbox();
      tag.color = color;
      tag.alpha = 1;
      tag.setPosition(subBeats.x + gridWidth, y - SUB_BEAT_TAG_HEIGHT / 2);
    }
  }

  function makeLine():FlxSprite
  {
    return new FunkinSprite().makeSolidColor(2, 2, FlxColor.WHITE);
  }
}
#end
