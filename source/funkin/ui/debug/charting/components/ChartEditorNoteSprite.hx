package funkin.ui.debug.charting.components;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import funkin.data.animation.AnimationData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.NoteDirection;

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
  @:isVar
  public var noteStyle(get, set):Null<String>;

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

    var entries:Array<String> = NoteStyleRegistry.instance.listEntryIds();

    if (noteFrameCollection == null)
    {
      buildEmptyFrameCollection();

      for (entry in entries)
      {
        addNoteStyleFrames(fetchNoteStyle(entry));
      }
    }

    if (noteFrameCollection == null) throw 'ERROR: Could not initialize note sprite animations.';

    this.frames = noteFrameCollection;

    for (entry in entries)
    {
      addNoteStyleAnimations(fetchNoteStyle(entry));
    }
  }

  static var noteFrameCollection:Null<FlxFramesCollection> = null;

  function fetchNoteStyle(noteStyleId:String):NoteStyle
  {
    var result = NoteStyleRegistry.instance.fetchEntry(noteStyleId);
    if (result != null) return result;
    return NoteStyleRegistry.instance.fetchDefault();
  }

  @:access(funkin.play.notes.notestyle.NoteStyle)
  @:nullSafety(Off)
  static function addNoteStyleFrames(noteStyle:NoteStyle):Void
  {
    var prefix:String = noteStyle.id.toTitleCase();

    var frameCollection:FlxAtlasFrames = Paths.getSparrowAtlas(noteStyle.getNoteAssetPath(), noteStyle.getNoteAssetLibrary());
    if (frameCollection == null)
    {
      trace('Could not retrieve frame collection for ${noteStyle}: ${Paths.image(noteStyle.getNoteAssetPath(), noteStyle.getNoteAssetLibrary())}');
      FlxG.log.error('Could not retrieve frame collection for ${noteStyle}: ${Paths.image(noteStyle.getNoteAssetPath(), noteStyle.getNoteAssetLibrary())}');
      return;
    }
    for (frame in frameCollection.frames)
    {
      // cloning the frame because else
      // we will fuck up the frame data used in game
      var clonedFrame:FlxFrame = frame.copyTo();
      clonedFrame.name = '$prefix${clonedFrame.name}';
      noteFrameCollection.pushFrame(clonedFrame);
    }
  }

  @:access(funkin.play.notes.notestyle.NoteStyle)
  @:nullSafety(Off)
  function addNoteStyleAnimations(noteStyle:NoteStyle):Void
  {
    var prefix:String = noteStyle.id.toTitleCase();
    var suffix:String = noteStyle.id.toTitleCase();

    var leftData:AnimationData = noteStyle.fetchNoteAnimationData(NoteDirection.LEFT);
    this.animation.addByPrefix('tapLeft$suffix', '$prefix${leftData.prefix}', leftData.frameRate, leftData.looped, leftData.flipX, leftData.flipY);

    var downData:AnimationData = noteStyle.fetchNoteAnimationData(NoteDirection.DOWN);
    this.animation.addByPrefix('tapDown$suffix', '$prefix${downData.prefix}', downData.frameRate, downData.looped, downData.flipX, downData.flipY);

    var upData:AnimationData = noteStyle.fetchNoteAnimationData(NoteDirection.UP);
    this.animation.addByPrefix('tapUp$suffix', '$prefix${upData.prefix}', upData.frameRate, upData.looped, upData.flipX, upData.flipY);

    var rightData:AnimationData = noteStyle.fetchNoteAnimationData(NoteDirection.RIGHT);
    this.animation.addByPrefix('tapRight$suffix', '$prefix${rightData.prefix}', rightData.frameRate, rightData.looped, rightData.flipX, rightData.flipY);
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

  function get_noteStyle():Null<String>
  {
    if (this.noteStyle == null)
    {
      var result = this.parentState.currentSongNoteStyle;
      return result;
    }
    return this.noteStyle;
  }

  function set_noteStyle(value:Null<String>):Null<String>
  {
    this.noteStyle = value;
    this.playNoteAnimation();
    return value;
  }

  @:nullSafety(Off)
  public function playNoteAnimation():Void
  {
    if (this.noteData == null) return;

    // Decide whether to display a note or a sustain.
    var baseAnimationName:String = 'tap';

    // Play the appropriate animation for the type, direction, and skin.
    var dirName:String = overrideData != null ? SongNoteData.buildDirectionName(overrideData) : this.noteData.getDirectionName();
    var noteStyleSuffix:String = this.noteStyle?.toTitleCase() ?? Constants.DEFAULT_NOTE_STYLE.toTitleCase();
    var animationName:String = '${baseAnimationName}${dirName}${this.noteStyle.toTitleCase()}';

    this.animation.play(animationName);

    // Resize note.

    switch (baseAnimationName)
    {
      case 'tap':
        this.setGraphicSize(ChartEditorState.GRID_SIZE, 0);
        this.updateHitbox();
    }

    var bruhStyle:NoteStyle = fetchNoteStyle(this.noteStyle);
    this.antialiasing = !bruhStyle._data?.assets?.note?.isPixel ?? true;
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
