package funkin.play.notes;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.NoteParamData;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.HSVShader;

class NoteSprite extends FunkinSprite
{
  static final DIRECTION_COLORS:Array<String> = ['purple', 'blue', 'green', 'red'];

  public var holdNoteSprite:SustainTrail;

  var hsvShader:HSVShader;

  /**
   * The strum time at which the note should be hit, in milliseconds.
   */
  public var strumTime(get, set):Float;

  function get_strumTime():Float
  {
    return this.noteData?.time ?? 0.0;
  }

  function set_strumTime(value:Float):Float
  {
    if (this.noteData == null) return value;
    return this.noteData.time = value;
  }

  /**
   * The length for which the note should be held, in milliseconds.
   * Defaults to 0 for single notes.
   */
  public var length(get, set):Float;

  function get_length():Float
  {
    return this.noteData?.length ?? 0.0;
  }

  function set_length(value:Float):Float
  {
    if (this.noteData == null) return value;
    return this.noteData.length = value;
  }

  /**
   * An extra attribute for the note.
   * For example, whether the note is an "alt" note, or whether it has custom behavior on hit.
   */
  public var kind(get, set):Null<String>;

  function get_kind():Null<String>
  {
    return this.noteData?.kind;
  }

  function set_kind(value:String):String
  {
    if (this.noteData == null) return value;
    return this.noteData.kind = value;
  }

  /**
   * An array of custom parameters for this note
   */
  public var params(get, set):Array<NoteParamData>;

  function get_params():Array<NoteParamData>
  {
    return this.noteData?.params ?? [];
  }

  function set_params(value:Array<NoteParamData>):Array<NoteParamData>
  {
    if (this.noteData == null) return value;
    return this.noteData.params = value;
  }

  /**
   * The data of the note (i.e. the direction.)
   */
  public var direction(default, set):NoteDirection;

  function set_direction(value:Int):Int
  {
    if (frames == null) return value;

    playNoteAnimation(value);

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
   * The Y Offset of the note.
   */
  public var yOffset:Float = 0.0;

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

  public function new(noteStyle:NoteStyle, direction:Int = 0)
  {
    super(0, -9999);
    this.direction = direction;

    this.hsvShader = new HSVShader();

    this.alpha = 1;

    setupNoteGraphic(noteStyle);
  }

  /**
   * Creates frames and animations
   * @param noteStyle The `NoteStyle` instance
   */
  public function setupNoteGraphic(noteStyle:NoteStyle):Void
  {
    noteStyle.buildNoteSprite(this);

    this.shader = hsvShader;

    // `false` disables the update() function for performance.
    this.active = noteStyle.isNoteAnimated();
  }

  /**
   * Retrieve the value of the param with the given name
   * @param name Name of the param
   * @return Null<Dynamic>
   */
  public function getParam(name:String):Null<Dynamic>
  {
    for (param in params)
    {
      if (param.name == name)
      {
        return param.value;
      }
    }
    return null;
  }

  #if FLX_DEBUG
  /**
   * Call this to override how debug bounding boxes are drawn for this sprite.
   */
  public override function drawDebugOnCamera(camera:flixel.FlxCamera):Void
  {
    if (!camera.visible || !camera.exists || !isOnScreen(camera)) return;

    var gfx = beginDrawDebug(camera);

    var rect = getBoundingBox(camera);
    trace('note sprite bounding box: ' + rect.x + ', ' + rect.y + ', ' + rect.width + ', ' + rect.height);

    gfx.lineStyle(2, 0xFFFF66FF, 0.5); // thickness, color, alpha
    gfx.drawRect(rect.x, rect.y, rect.width, rect.height);

    gfx.lineStyle(2, 0xFFFFFF66, 0.5); // thickness, color, alpha
    gfx.drawRect(rect.x, rect.y + rect.height / 2, rect.width, 1);

    endDrawDebug(camera);
  }
  #end

  function playNoteAnimation(value:Int):Void
  {
    animation.play(DIRECTION_COLORS[value] + 'Scroll');
  }

  public function desaturate():Void
  {
    this.hsvShader.saturation = 0.2;
  }

  public function setHue(hue:Float):Void
  {
    this.hsvShader.hue = hue;
  }

  public override function revive():Void
  {
    super.revive();
    this.visible = true;
    this.alpha = 1.0;
    this.active = false;
    this.tooEarly = false;
    this.hasBeenHit = false;
    this.mayHit = false;
    this.hasMissed = false;

    this.hsvShader.hue = 1.0;
    this.hsvShader.saturation = 1.0;
    this.hsvShader.value = 1.0;
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
