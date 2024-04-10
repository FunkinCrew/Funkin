package funkin.ui.debug.charting.components;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import funkin.data.song.SongData.SongNoteData;

/**
 * A sprite that can be used to display a note in a chart.
 * Designed to be used and reused efficiently. Has no gameplay functionality.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorNoteSprite extends FlxSprite
{
  /**
   * The list of available note skin to validate against.
   */
  public static final NOTE_STYLES:Array<String> = ['funkin', 'pixel'];

  /**
   * The ChartEditorState this note belongs to.
   */
  public var parentState:ChartEditorState;

  /**
   * The note data that this sprite represents.
   * You can set this to null to kill the sprite and flag it for recycling.
   */
  public var noteData(default, set):Null<SongNoteData>;

  /**
   * The name of the note style currently in use.
   */
  public var noteStyle(get, never):String;

  public var overrideStepTime(default, set):Null<Float> = null;

  function set_overrideStepTime(value:Null<Float>):Null<Float>
  {
    if (overrideStepTime == value) return overrideStepTime;

    overrideStepTime = value;
    updateNotePosition();
    return overrideStepTime;
  }

  public var overrideData(default, set):Null<Int> = null;

  function set_overrideData(value:Null<Int>):Null<Int>
  {
    if (overrideData == value) return overrideData;

    overrideData = value;
    playNoteAnimation();
    return overrideData;
  }

  public function new(parent:ChartEditorState)
  {
    super();

    this.parentState = parent;

    if (noteFrameCollection == null)
    {
      initFrameCollection();
    }

    if (noteFrameCollection == null) throw 'ERROR: Could not initialize note sprite animations.';

    this.frames = noteFrameCollection;

    // Initialize all the animations, not just the one we're going to use immediately,
    // so that later we can reuse the sprite without having to initialize more animations during scrolling.
    this.animation.addByPrefix('tapLeftFunkin', 'purple instance');
    this.animation.addByPrefix('tapDownFunkin', 'blue instance');
    this.animation.addByPrefix('tapUpFunkin', 'green instance');
    this.animation.addByPrefix('tapRightFunkin', 'red instance');

    this.animation.addByPrefix('holdLeftFunkin', 'LeftHoldPiece');
    this.animation.addByPrefix('holdDownFunkin', 'DownHoldPiece');
    this.animation.addByPrefix('holdUpFunkin', 'UpHoldPiece');
    this.animation.addByPrefix('holdRightFunkin', 'RightHoldPiece');

    this.animation.addByPrefix('holdEndLeftFunkin', 'LeftHoldEnd');
    this.animation.addByPrefix('holdEndDownFunkin', 'DownHoldEnd');
    this.animation.addByPrefix('holdEndUpFunkin', 'UpHoldEnd');
    this.animation.addByPrefix('holdEndRightFunkin', 'RightHoldEnd');

    this.animation.addByPrefix('tapLeftPixel', 'pixel4');
    this.animation.addByPrefix('tapDownPixel', 'pixel5');
    this.animation.addByPrefix('tapUpPixel', 'pixel6');
    this.animation.addByPrefix('tapRightPixel', 'pixel7');
  }

  static var noteFrameCollection:Null<FlxFramesCollection> = null;

  /**
   * We load all the note frames once, then reuse them.
   */
  static function initFrameCollection():Void
  {
    buildEmptyFrameCollection();
    if (noteFrameCollection == null) return;

    // TODO: Automatically iterate over the list of note skins.

    // Normal notes
    var frameCollectionNormal:FlxAtlasFrames = Paths.getSparrowAtlas('NOTE_assets');

    for (frame in frameCollectionNormal.frames)
    {
      noteFrameCollection.pushFrame(frame);
    }

    // Pixel notes
    var graphicPixel = FlxG.bitmap.add(Paths.image('weeb/pixelUI/arrows-pixels', 'week6'), false, null);
    if (graphicPixel == null) trace('ERROR: Could not load graphic: ' + Paths.image('weeb/pixelUI/arrows-pixels', 'week6'));
    var frameCollectionPixel = FlxTileFrames.fromGraphic(graphicPixel, new FlxPoint(17, 17));
    for (i in 0...frameCollectionPixel.frames.length)
    {
      var frame:Null<FlxFrame> = frameCollectionPixel.frames[i];
      if (frame == null) continue;

      frame.name = 'pixel' + i;
      noteFrameCollection.pushFrame(frame);
    }
  }

  @:nullSafety(Off)
  static function buildEmptyFrameCollection():Void
  {
    noteFrameCollection = new FlxFramesCollection(null, ATLAS, null);
  }

  function set_noteData(value:Null<SongNoteData>):Null<SongNoteData>
  {
    this.noteData = value;

    if (this.noteData == null)
    {
      this.kill();
      return this.noteData;
    }

    this.visible = true;

    // Update the animation to match the note data.
    // Animation is updated first so size is correct before updating position.
    playNoteAnimation();

    // Update the position to match the note data.
    updateNotePosition();

    return this.noteData;
  }

  public function updateNotePosition(?origin:FlxObject):Void
  {
    if (this.noteData == null) return;

    var cursorColumn:Int = (overrideData != null) ? overrideData : this.noteData.data;

    cursorColumn = ChartEditorState.noteDataToGridColumn(cursorColumn);

    this.x = cursorColumn * ChartEditorState.GRID_SIZE;

    // Notes far in the song will start far down, but the group they belong to will have a high negative offset.
    // noteData.getStepTime() returns a calculated value which accounts for BPM changes
    var stepTime:Float = (overrideStepTime != null) ? overrideStepTime : noteData.getStepTime();
    if (stepTime >= 0)
    {
      this.y = stepTime * ChartEditorState.GRID_SIZE;
    }

    if (origin != null)
    {
      this.x += origin.x;
      this.y += origin.y;
    }
  }

  function get_noteStyle():String
  {
    // Fall back to Funkin' if it's not a valid note style.
    return if (NOTE_STYLES.contains(this.parentState.currentSongNoteStyle)) this.parentState.currentSongNoteStyle else 'funkin';
  }

  public function playNoteAnimation():Void
  {
    if (this.noteData == null) return;

    // Decide whether to display a note or a sustain.
    var baseAnimationName:String = 'tap';

    // Play the appropriate animation for the type, direction, and skin.
    var dirName:String = overrideData != null ? SongNoteData.buildDirectionName(overrideData) : this.noteData.getDirectionName();
    var animationName:String = '${baseAnimationName}${dirName}${this.noteStyle.toTitleCase()}';

    this.animation.play(animationName);

    // Resize note.

    switch (baseAnimationName)
    {
      case 'tap':
        this.setGraphicSize(0, ChartEditorState.GRID_SIZE);
    }
    this.updateHitbox();

    // TODO: Make this an attribute of the note skin.
    this.antialiasing = (this.parentState.currentSongNoteStyle != 'Pixel');
  }

  /**
   * Return whether this note (or its parent) is currently visible.
   */
  public function isNoteVisible(viewAreaBottom:Float, viewAreaTop:Float):Bool
  {
    // True if the note is above the view area.
    var aboveViewArea = (this.y + this.height < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (this.y > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }

  /**
   * Return whether a note, if placed in the scene, would be visible.
   * This function should be made HYPER EFFICIENT because it's called a lot.
   */
  public static function wouldNoteBeVisible(viewAreaBottom:Float, viewAreaTop:Float, noteData:SongNoteData, ?origin:FlxObject):Bool
  {
    var noteHeight:Float = ChartEditorState.GRID_SIZE;
    var stepTime:Float = inline noteData.getStepTime();
    var notePosY:Float = stepTime * ChartEditorState.GRID_SIZE;
    if (origin != null) notePosY += origin.y;

    // True if the note is above the view area.
    var aboveViewArea = (notePosY + noteHeight < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (notePosY > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }
}
