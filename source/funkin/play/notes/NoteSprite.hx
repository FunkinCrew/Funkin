package funkin.play.notes;

import funkin.play.song.SongData.SongNoteData;
import funkin.play.notes.notestyle.NoteStyle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;

class NoteSprite extends FlxSprite
{
  static final DIRECTION_COLORS:Array<String> = ['purple', 'blue', 'green', 'red'];

  public var holdNoteSprite:SustainTrail;

  /**
   * The time at which the note should be hit, in milliseconds.
   */
  public var strumTime(default, set):Float;

  function set_strumTime(value:Float):Float
  {
    this.strumTime = value;
    return this.strumTime;
  }

  /**
   * The time at which the note should be hit, in steps.
   */
  public var stepTime(get, never):Float;

  function get_stepTime():Float
  {
    // TODO: Account for changes in BPM.
    return this.strumTime / Conductor.stepLengthMs;
  }

  /**
   * An extra attribute for the note.
   * For example, whether the note is an "alt" note, or whether it has custom behavior on hit.
   */
  public var kind(default, set):String;

  function set_kind(value:String):String
  {
    this.kind = value;
    return this.kind;
  }

  /**
   * The data of the note (i.e. the direction.)
   */
  public var direction(default, set):NoteDirection;

  function set_direction(value:Int):Int
  {
    if (frames == null) return value;

    animation.play(DIRECTION_COLORS[value] + 'Scroll');

    this.direction = value;
    return this.direction;
  }

  public var noteData:SongNoteData;

  public var isHoldNote(get, never):Bool;

  function get_isHoldNote():Bool
  {
    return noteData.length > 0;
  }

  /**
   * Set this flag to true when hitting the note to avoid scoring it multiple times.
   */
  public var hasBeenHit:Bool = false;

  /**
   * Register this note as hit only after any other notes
   */
  public var lowPriority:Bool = false;

  /**
   * This is true if the note is later than 10 frames within the strumline,
   * and thus can't be hit by the player.
   * It will be destroyed after it moves offscreen.
   * Managed by PlayState.
   */
  public var hasMissed:Bool;

  /**
   * This is true if the note is earlier than 10 frames within the strumline.
   * and thus can't be hit by the player.
   * Managed by PlayState.
   */
  public var tooEarly:Bool;

  /**
   * This is true if the note is within 10 frames of the strumline,
   * and thus may be hit by the player.
   * Managed by PlayState.
   */
  public var mayHit:Bool;

  /**
   * This is true if the PlayState has performed the logic for missing this note.
   * Subtracting score, subtracting health, etc.
   */
  public var handledMiss:Bool;

  public function new(noteStyle:NoteStyle, strumTime:Float = 0, direction:Int = 0)
  {
    super(0, -9999);
    this.strumTime = strumTime;
    this.direction = direction;

    if (this.strumTime < 0) this.strumTime = 0;

    setupNoteGraphic(noteStyle);

    // Disables the update() function for performance.
    this.active = false;
  }

  function setupNoteGraphic(noteStyle:NoteStyle):Void
  {
    noteStyle.buildNoteSprite(this);

    setGraphicSize(Strumline.STRUMLINE_SIZE);
    updateHitbox();
  }

  public override function revive():Void
  {
    super.revive();
    this.active = false;
    this.tooEarly = false;
    this.hasBeenHit = false;
    this.mayHit = false;
    this.hasMissed = false;
  }

  public override function kill():Void
  {
    super.kill();
  }

  public override function destroy():Void
  {
    // This function should ONLY get called as you leave PlayState entirely.
    // Otherwise, we want the game to keep reusing note sprites to save memory.
    super.destroy();
  }
}
