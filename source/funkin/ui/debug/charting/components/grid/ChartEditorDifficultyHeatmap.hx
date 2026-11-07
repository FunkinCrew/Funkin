package funkin.ui.debug.charting.components.grid;

#if FEATURE_CHART_EDITOR
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.data.song.SongData.SongNoteData;
import funkin.util.DiffCalcUtil;
import haxe.ui.backend.flixel.HiResFlxText;

/**
 * Puts information on the player side regarding what the diff calc thinks is hard.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorDifficultyHeatmap extends FlxTypedGroup<FlxSprite>
{
  static final EASY_COLOR:FlxColor = 0xFF63BE7B;
  static final MEDIUM_COLOR:FlxColor = 0xFFFFEB84;
  static final HARD_COLOR:FlxColor = 0xFFF8696B;

  /**
   * The rating that shows fully red and strongest.
   */
  static final HARDEST_RATING:Float = 12;

  static final MIN_ALPHA:Float = 0.06;
  static final MAX_ALPHA:Float = 0.4;

  /**
   * How many of the hardest spots get a label.
   */
  static final LABEL_COUNT:Int = 12;

  /**
   * How far apart labelled spots have to be, in milliseconds.
   */
  static final LABEL_MIN_GAP_MS:Float = 4000;

  static final LABEL_WIDTH:Int = 220;

  var chartEditorState:ChartEditorState;

  var sections:Array<DiffCalcSection> = [];
  var ratings:Array<Float> = [];

  /**
   * Indexes into `sections` that get a label.
   */
  var hotSpots:Array<Int> = [];

  var bands:Array<FlxSprite> = [];
  var labels:Array<FlxText> = [];
  var hoverText:FlxText;

  public function new(chartEditorState:ChartEditorState)
  {
    super();
    this.chartEditorState = chartEditorState;

    hoverText = makeText();
    hoverText.fieldWidth = LABEL_WIDTH;
    hoverText.wordWrap = true;
  }

  function makeText():FlxText
  {
    var text:FlxText = new HiResFlxText(0, 0, LABEL_WIDTH, '', 14);
    text.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 14, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    text.visible = false;
    add(text);
    return text;
  }

  /**
   * Work out the strain for a chart.
   */
  public function setChart(notes:Array<SongNoteData>, scrollSpeed:Float, opponentShown:Bool = true):Void
  {
    var conductor:Conductor = Conductor.instance;
    sections = DiffCalcUtil.sectionStrains(notes, time -> Math.floor(conductor.getTimeInSteps(time) / Constants.STEPS_PER_BEAT + 0.001),
      beat -> conductor.getBeatTimeInMs(beat), opponentShown) ?? [];
    ratings = [for (section in sections) DiffCalcUtil.strainToRating(section.strain, scrollSpeed)];

    // The hardest spots, kept apart so the labels spread over the song.
    var order:Array<Int> = [for (i in 0...sections.length) i];
    order.sort((a, b) -> ratings[a] > ratings[b] ? -1 : (ratings[a] < ratings[b] ? 1 : 0));
    hotSpots = [];
    for (i in order)
    {
      if (hotSpots.length >= LABEL_COUNT) break;
      var crowded:Bool = false;
      for (other in hotSpots) if (Math.abs(sections[other].time - sections[i].time) < LABEL_MIN_GAP_MS) crowded = true;
      if (!crowded) hotSpots.push(i);
    }
  }

  /**
   * Place the bands and labels for the part of the grid on screen, and the readout for the spot under the mouse.
   * @param gridX The left edge of the grid.
   * @param gridY Where the top of the song is on screen.
   * @param viewTop The top of the visible grid area on screen.
   * @param viewBottom The bottom of the visible grid area on screen.
   */
  public function refresh(gridX:Float, gridY:Float, viewTop:Float, viewBottom:Float):Void
  {
    var size:Int = ChartEditorState.GRID_SIZE;
    var strumline:Int = ChartEditorState.STRUMLINE_SIZE;

    // The player's lanes sit to the right of the opponent's.
    var bandX:Float = gridX + size * strumline;
    var bandWidth:Float = size * strumline;
    var labelX:Float = gridX + size * (strumline * 2 + 1) + 8;

    var used:Int = 0;
    for (i in 0...sections.length)
    {
      var top:Float = gridY + ChartEditorTimeScale.msToPixels(sections[i].time);
      var bottom:Float = gridY + ChartEditorTimeScale.msToPixels(sections[i].end);
      if (bottom < viewTop || top > viewBottom) continue;

      var band:FlxSprite = getBand(used++);
      band.color = ratingColor(ratings[i]);
      band.alpha = MIN_ALPHA + (MAX_ALPHA - MIN_ALPHA) * Math.min(1, Math.max(0, ratings[i]) / HARDEST_RATING);
      band.setGraphicSize(Std.int(bandWidth), Std.int(Math.max(1, bottom - top)));
      band.updateHitbox();
      band.x = bandX;
      band.y = top;
      band.visible = true;
    }
    for (i in used...bands.length) bands[i].visible = false;

    var shown:Int = 0;
    for (i in hotSpots)
    {
      var y:Float = gridY + ChartEditorTimeScale.msToPixels((sections[i].time + sections[i].end) / 2);
      if (y < viewTop || y > viewBottom) continue;
      var label:FlxText = getLabel(shown++);
      label.text = '${format(ratings[i])} ${causeName(DiffCalcUtil.mainCause(sections[i]))}';
      label.color = ratingColor(ratings[i]);
      label.x = labelX;
      label.y = y - label.height / 2;
      label.visible = true;
    }
    for (i in shown...labels.length) labels[i].visible = false;

    refreshHover(bandX, bandWidth, gridY, labelX, viewTop, viewBottom);
  }

  function refreshHover(bandX:Float, bandWidth:Float, gridY:Float, labelX:Float, viewTop:Float, viewBottom:Float):Void
  {
    hoverText.visible = false;
    var mouseX:Float = FlxG.mouse.viewX;
    var mouseY:Float = FlxG.mouse.viewY;
    if (mouseX < bandX || mouseX > bandX + bandWidth || mouseY < viewTop || mouseY > viewBottom) return;
    if (chartEditorState.isCursorOverHaxeUI) return;

    var ms:Float = ChartEditorTimeScale.pixelsToMs(mouseY - gridY);
    var index:Int = sectionAt(ms);
    if (index < 0) return;

    var section:DiffCalcSection = sections[index];
    var total:Float = 0;
    for (part in section.causes) total += part;
    var parts:Array<String> = [];
    var names:Array<String> = ['Speed', 'Patterns', 'Rhythm', 'Chords', 'Jacks'];
    for (c in 0...section.causes.length)
    {
      var percent:Int = total > 0 ? Math.round(section.causes[c] / total * 100) : 0;
      if (percent > 0) parts.push('${names[c]} $percent%');
    }
    hoverText.text = '${format(ratings[index])} ${causeName(DiffCalcUtil.mainCause(section))}\n${parts.join('\n')}';
    hoverText.color = FlxColor.WHITE;
    hoverText.x = labelX;
    hoverText.y = Math.min(Math.max(mouseY - 10, viewTop), viewBottom - hoverText.height);
    hoverText.visible = true;

    for (label in labels)
    {
      if (label.visible && label.y + label.height > hoverText.y && label.y < hoverText.y + hoverText.height) label.visible = false;
    }
  }

  /**
   * The section covering a time.
   */
  function sectionAt(ms:Float):Int
  {
    var low:Int = 0;
    var high:Int = sections.length - 1;
    while (low <= high)
    {
      var mid:Int = (low + high) >> 1;
      var start:Float = sections[mid].time;
      if (ms < start) high = mid - 1;
      else if (ms >= sections[mid].end) low = mid + 1;
      else
        return mid;
    }
    return -1;
  }

  function getBand(index:Int):FlxSprite
  {
    while (bands.length <= index)
    {
      var band:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
      band.visible = false;
      bands.push(band);

      // Bands go under the labels.
      insert(bands.length - 1, band);
    }
    return bands[index];
  }

  function getLabel(index:Int):FlxText
  {
    while (labels.length <= index) labels.push(makeText());
    return labels[index];
  }

  public function hideAll():Void
  {
    for (band in bands) band.visible = false;
    for (label in labels) label.visible = false;
    hoverText.visible = false;
  }

  static function format(rating:Float):String
  {
    return '${Math.round(rating * 10) / 10}';
  }

  static function ratingColor(rating:Float):FlxColor
  {
    var half:Float = HARDEST_RATING / 2;
    if (rating <= half) return FlxColor.interpolate(EASY_COLOR, MEDIUM_COLOR, Math.max(0, rating) / half);
    return FlxColor.interpolate(MEDIUM_COLOR, HARD_COLOR, Math.min(1, (rating - half) / half));
  }

  static function causeName(cause:DiffCalcCause):String
  {
    return switch (cause)
    {
      case Speed: 'Speed';
      case PatternBreaks: 'Patterns';
      case RhythmChanges: 'Rhythm';
      case Chords: 'Chords';
      case Jacks: 'Jacks';
    }
  }
}
#end
