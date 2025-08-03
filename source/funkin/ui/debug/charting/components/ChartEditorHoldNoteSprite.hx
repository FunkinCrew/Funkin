package funkin.ui.debug.charting.components;

import funkin.play.notes.Strumline;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import flixel.FlxObject;
import funkin.play.notes.SustainTrail;
import funkin.data.song.SongData.SongNoteData;
import flixel.math.FlxMath;

/**
 * A sprite that can be used to display the trail of a hold note in a chart.
 * Designed to be used and reused efficiently. Has no gameplay functionality.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
@:nullSafety
class ChartEditorHoldNoteSprite extends SustainTrail
{
  /**
   * The ChartEditorState this note belongs to.
   */
  public var parentState:ChartEditorState;

  @:isVar
  public var noteStyle(get, set):Null<String>;

  function get_noteStyle():Null<String>
  {
    return this.noteStyle ?? this.parentState.currentSongNoteStyle;
  }

  @:nullSafety(Off)
  function set_noteStyle(value:Null<String>):Null<String>
  {
    @:bypassAccessor final dirty:Bool = this.noteStyle != value;
    this.noteStyle = value;
    if (dirty) this.updateHoldNoteGraphic();
    return value;
  }

  public var overrideStepTime(default, set):Null<Float> = null;

  function set_overrideStepTime(value:Null<Float>):Null<Float>
  {
    if (overrideStepTime == value) return overrideStepTime;

    overrideStepTime = value;
    updateHoldNotePosition();
    return overrideStepTime;
  }

  public var overrideData(default, set):Null<Int> = null;

  function set_overrideData(value:Null<Int>):Null<Int>
  {
    if (overrideData == value) return overrideData;

    overrideData = value;
    if (overrideData != null) this.noteDirection = overrideData;
    updateHoldNoteGraphic();
    updateHoldNotePosition();
    return overrideData;
  }

  public function new(parent:ChartEditorState)
  {
    var noteStyle = NoteStyleRegistry.instance.fetchDefault();

    super(0, 100, noteStyle);

    this.parentState = parent;
  }

  @:nullSafety(Off)
  public function updateHoldNoteGraphic():Void
  {
    var bruhStyle:Null<NoteStyle> = NoteStyleRegistry.instance.fetchEntry(noteStyle);
    if (bruhStyle == null) bruhStyle = NoteStyleRegistry.instance.fetchDefault();
    setupHoldNoteGraphic(bruhStyle);
  }

  override function setupHoldNoteGraphic(noteStyle:NoteStyle):Void
  {
    var graphicPath = noteStyle.getHoldNoteAssetPath();
    if (graphicPath == null) return;
    loadGraphic(graphicPath);

    antialiasing = true;

    this.isPixel = noteStyle.isHoldNotePixel();
    if (isPixel)
    {
      endOffset = bottomClip = 1;
      antialiasing = false;
    }
    else
    {
      endOffset = 0.5;
      bottomClip = 0.9;
    }

    zoom = 1.0;
    zoom *= noteStyle.fetchHoldNoteScale();
    zoom *= 0.7;
    zoom *= ChartEditorState.GRID_SIZE / Strumline.STRUMLINE_SIZE;

    graphicWidth = graphic.width / 8 * zoom; // amount of notes * 2
    graphicHeight = sustainLength * 0.45; // sustainHeight

    flipY = false;

    alpha = 1.0;

    updateColorTransform();

    updateClipping();

    setup();
  }

  public override function updateHitbox():Void
  {
    // Expand the clickable hitbox to the full column width, then nudge to the left to re-center it.
    width = ChartEditorState.GRID_SIZE;
    height = graphicHeight;

    var xOffset = (ChartEditorState.GRID_SIZE - graphicWidth) / 2;
    offset.set(-xOffset, 0);
    origin.set(width * 0.5, height * 0.5);
  }

  /**
   * Set the height directly, to a value in pixels.
   * @param h The desired height in pixels.
   */
  public function setHeightDirectly(h:Float, lerp:Bool = false)
  {
    if (lerp)
    {
      sustainLength = FlxMath.lerp(sustainLength, h / (getBaseScrollSpeed() * Constants.PIXELS_PER_MS), 0.25);
    }
    else
    {
      sustainLength = h / (getBaseScrollSpeed() * Constants.PIXELS_PER_MS);
    }

    fullSustainLength = sustainLength;
  }

  #if FLX_DEBUG
  /**
   * Call this to override how debug bounding boxes are drawn for this sprite.
   */
  public override function drawDebugOnCamera(camera:flixel.FlxCamera):Void
  {
    if (!camera.visible || !camera.exists || !isOnScreen(camera)) return;

    var rect = getBoundingBox(camera);
    trace('hold note bounding box: ' + rect.x + ', ' + rect.y + ', ' + rect.width + ', ' + rect.height);

    var gfx = beginDrawDebug(camera);
    debugBoundingBoxColor = 0xffFF66FF;
    gfx.lineStyle(2, color, 0.5); // thickness, color, alpha
    gfx.drawRect(rect.x, rect.y, rect.width, rect.height);
    endDrawDebug(camera);
  }
  #end

  function setup():Void
  {
    strumTime = 999999999;
    missedNote = false;
    hitNote = false;
    active = true;
    visible = true;
    alpha = 1.0;
    graphicWidth = graphic.width / 8 * zoom; // amount of notes * 2

    updateHitbox();
  }

  public override function revive():Void
  {
    super.revive();

    setup();
  }

  public override function kill():Void
  {
    super.kill();

    active = false;
    visible = false;
    noteData = null;
    strumTime = 999999999;
    noteDirection = 0;
    sustainLength = 0;
    fullSustainLength = 0;
  }

  /**
   * Return whether this note is currently visible.
   */
  public function isHoldNoteVisible(viewAreaBottom:Float, viewAreaTop:Float):Bool
  {
    // True if the note is above the view area.
    var aboveViewArea = (this.y + this.height < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (this.y > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }

  /**
   * Return whether a hold note, if placed in the scene, would be visible.
   */
  public static function wouldHoldNoteBeVisible(viewAreaBottom:Float, viewAreaTop:Float, noteData:SongNoteData, ?origin:FlxObject):Bool
  {
    var noteHeight:Float = noteData.getStepLength() * ChartEditorState.GRID_SIZE;
    var stepTime:Float = inline noteData.getStepTime();
    var notePosY:Float = stepTime * ChartEditorState.GRID_SIZE;
    if (origin != null) notePosY += origin.y;

    // True if the note is above the view area.
    var aboveViewArea = (notePosY + noteHeight < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (notePosY > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }

  public function updateHoldNotePosition(?origin:FlxObject):Void
  {
    if (this.noteData == null) return;

    var cursorColumn:Int = (overrideData != null) ? overrideData : this.noteData.data;

    if (cursorColumn < 0) cursorColumn = 0;
    if (cursorColumn >= (ChartEditorState.STRUMLINE_SIZE * 2 + 1))
    {
      cursorColumn = (ChartEditorState.STRUMLINE_SIZE * 2 + 1);
    }
    else
    {
      // Invert player and opponent columns.
      if (cursorColumn >= ChartEditorState.STRUMLINE_SIZE)
      {
        cursorColumn -= ChartEditorState.STRUMLINE_SIZE;
      }
      else
      {
        cursorColumn += ChartEditorState.STRUMLINE_SIZE;
      }
    }

    this.x = cursorColumn * ChartEditorState.GRID_SIZE;

    // Notes far in the song will start far down, but the group they belong to will have a high negative offset.
    // noteData.getStepTime() returns a calculated value which accounts for BPM changes
    var stepTime:Float = (overrideStepTime != null) ? overrideStepTime :
    inline this.noteData.getStepTime();
    if (stepTime >= 0)
    {
      // Add epsilon to fix rounding issues?
      // var roundedStepTime:Float = Math.floor((stepTime + 0.01) / noteSnapRatio) * noteSnapRatio;
      this.y = stepTime * ChartEditorState.GRID_SIZE;
    }

    this.x += ChartEditorState.GRID_SIZE / 2;
    this.x -= this.graphicWidth / 2;

    this.y += ChartEditorState.GRID_SIZE / 2;

    if (origin != null)
    {
      this.x += origin.x;
      this.y += origin.y;
    }

    // Account for expanded clickable hitbox.
    this.x += this.offset.x;
  }
}
