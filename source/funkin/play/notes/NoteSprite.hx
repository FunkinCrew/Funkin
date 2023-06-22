package funkin.play.notes;

import funkin.play.song.SongData.SongNoteData;
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
   * The length of the note's sustain, in milliseconds.
   * If 0, the note is a tap note.
   */
  public var length(default, set):Float;

  function set_length(value:Float):Float
  {
    this.length = value;
    this.isSustainNote = (this.length > 0);
    return this.length;
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

  public var isSustainNote:Bool = false;

  /**
   * Set this flag to true when hitting the note to avoid scoring it multiple times.
   */
  public var hasBeenHit:Bool = false;

  /**
   * Register this note as hit only after any other notes
   */
  public var lowPriority:Bool = false;

  /**
   * This is true if the note has been fully missed by the player.
   * It will be destroyed immediately.
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
   * This is true if the note is earlier than 10 frames after the strumline,
   * and thus can't be hit by the player.
   * Managed by PlayState.
   */
  public var tooLate:Bool;

  public function new(strumTime:Float = 0, direction:Int = 0)
  {
    super(0, -9999);
    this.strumTime = strumTime;
    this.direction = direction;

    if (this.strumTime < 0) this.strumTime = 0;

    setupNoteGraphic();

    // Disables the update() function for performance.
    this.active = false;
  }

  public static function buildNoteFrames(force:Bool = false):FlxAtlasFrames
  {
    // static variables inside functions are a cool of Haxe 4.3.0.
    static var noteFrames:FlxAtlasFrames = null;

    if (noteFrames != null && !force) return noteFrames;

    noteFrames = Paths.getSparrowAtlas('NOTE_assets');

    noteFrames.parent.persist = true;

    return noteFrames;
  }

  function setupNoteGraphic():Void
  {
    this.frames = buildNoteFrames();

    animation.addByPrefix('greenScroll', 'green instance');
    animation.addByPrefix('redScroll', 'red instance');
    animation.addByPrefix('blueScroll', 'blue instance');
    animation.addByPrefix('purpleScroll', 'purple instance');

    animation.addByPrefix('purpleholdend', 'pruple end hold');
    animation.addByPrefix('greenholdend', 'green hold end');
    animation.addByPrefix('redholdend', 'red hold end');
    animation.addByPrefix('blueholdend', 'blue hold end');

    animation.addByPrefix('purplehold', 'purple hold piece');
    animation.addByPrefix('greenhold', 'green hold piece');
    animation.addByPrefix('redhold', 'red hold piece');
    animation.addByPrefix('bluehold', 'blue hold piece');

    setGraphicSize(Strumline.STRUMLINE_SIZE);
    updateHitbox();
    antialiasing = true;
  }

  public override function revive():Void
  {
    super.revive();
    this.active = false;
    this.tooEarly = false;
    this.hasBeenHit = false;
    this.mayHit = false;
    this.tooLate = false;
    this.hasMissed = false;
  }
}
