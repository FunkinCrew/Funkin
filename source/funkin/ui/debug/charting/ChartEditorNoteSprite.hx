package funkin.ui.debug.charting;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import funkin.play.song.SongData.SongNoteData;

/**
 * A note sprite that can be used to display a note in a chart.
 * Designed to be used and reused efficiently. Has no gameplay functionality.
 */
class ChartEditorNoteSprite extends FlxSprite
{
  /**
   * The list of available note skin to validate against.
   */
  public static final NOTE_STYLES:Array<String> = ['Normal', 'Pixel'];

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
  public var noteStyle(get, null):String;

  public function new(parent:ChartEditorState)
  {
    super();

    this.parentState = parent;

    if (noteFrameCollection == null)
    {
      initFrameCollection();
    }

    this.frames = noteFrameCollection;

    // Initialize all the animations, not just the one we're going to use immediately,
    // so that later we can reuse the sprite without having to initialize more animations during scrolling.
    this.animation.addByPrefix('tapLeftNormal', 'purple instance');
    this.animation.addByPrefix('tapDownNormal', 'blue instance');
    this.animation.addByPrefix('tapUpNormal', 'green instance');
    this.animation.addByPrefix('tapRightNormal', 'red instance');

    this.animation.addByPrefix('holdLeftNormal', 'LeftHoldPiece');
    this.animation.addByPrefix('holdDownNormal', 'DownHoldPiece');
    this.animation.addByPrefix('holdUpNormal', 'UpHoldPiece');
    this.animation.addByPrefix('holdRightNormal', 'RightHoldPiece');

    this.animation.addByPrefix('holdEndLeftNormal', 'LeftHoldEnd');
    this.animation.addByPrefix('holdEndDownNormal', 'DownHoldEnd');
    this.animation.addByPrefix('holdEndUpNormal', 'UpHoldEnd');
    this.animation.addByPrefix('holdEndRightNormal', 'RightHoldEnd');

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
    noteFrameCollection = new FlxFramesCollection(null, ATLAS, null);

    // TODO: Automatically iterate over the list of note skins.

    // Normal notes
    var frameCollectionNormal = Paths.getSparrowAtlas('NOTE_assets');

    for (frame in frameCollectionNormal.frames)
    {
      noteFrameCollection.pushFrame(frame);
    }
    var frameCollectionNormal2 = Paths.getSparrowAtlas('NoteHoldNormal');

    for (frame in frameCollectionNormal2.frames)
    {
      noteFrameCollection.pushFrame(frame);
    }

    // Pixel notes
    var graphicPixel = FlxG.bitmap.add(Paths.image('weeb/pixelUI/arrows-pixels', 'week6'), false, null);
    if (graphicPixel == null) trace('ERROR: Could not load graphic: ' + Paths.image('weeb/pixelUI/arrows-pixels', 'week6'));
    var frameCollectionPixel = FlxTileFrames.fromGraphic(graphicPixel, new FlxPoint(17, 17));
    for (i in 0...frameCollectionPixel.frames.length)
    {
      var frame = frameCollectionPixel.frames[i];

      frame.name = 'pixel' + i;
      noteFrameCollection.pushFrame(frame);
    }
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

  public function updateNotePosition(?origin:FlxObject)
  {
    var cursorColumn:Int = this.noteData.data;

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
    if (this.noteData.stepTime >= 0)
    {
      // noteData.stepTime is a calculated value which accounts for BPM changes
      var stepTime:Float = this.noteData.stepTime;
      var roundedStepTime:Float = Math.floor(stepTime + 0.01); // Add epsilon to fix rounding issues
      this.y = roundedStepTime * ChartEditorState.GRID_SIZE;
    }

    if (origin != null)
    {
      this.x += origin.x;
      this.y += origin.y;
    }
  }

  function get_noteStyle():String
  {
    // Fall back to 'Normal' if it's not a valid note style.
    return if (NOTE_STYLES.contains(this.parentState.currentSongNoteSkin)) this.parentState.currentSongNoteSkin else 'Normal';
  }

  public function playNoteAnimation():Void
  {
    // Decide whether to display a note or a sustain.
    var baseAnimationName:String = 'tap';

    // Play the appropriate animation for the type, direction, and skin.
    var animationName:String = '${baseAnimationName}${this.noteData.getDirectionName()}${this.noteStyle}';

    this.animation.play(animationName);

    // Resize note.

    switch (baseAnimationName)
    {
      case 'tap':
        this.setGraphicSize(0, ChartEditorState.GRID_SIZE);
    }
    this.updateHitbox();

    // TODO: Make this an attribute of the note skin.
    this.antialiasing = (this.parentState.currentSongNoteSkin != 'Pixel');
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
   */
  public static function wouldNoteBeVisible(viewAreaBottom:Float, viewAreaTop:Float, noteData:SongNoteData, ?origin:FlxObject):Bool
  {
    var noteHeight:Float = ChartEditorState.GRID_SIZE;
    var notePosY:Float = noteData.stepTime * ChartEditorState.GRID_SIZE;
    if (origin != null) notePosY += origin.y;

    // True if the note is above the view area.
    var aboveViewArea = (notePosY + noteHeight < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (notePosY > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }
}
