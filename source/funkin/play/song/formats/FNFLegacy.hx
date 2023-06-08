package funkin.play.song.formats;

typedef FNFLegacy =
{
  var song:LegacySongData;
}

typedef LegacySongData =
{
  var player1:String; // Boyfriend
  var player2:String; // Opponent

  var speed:LegacyScrollSpeeds;
  var stageDefault:String;
  var bpm:Float;
  var notes:LegacyNoteData;
  var song:String; // Song name
};

typedef LegacyScrollSpeeds =
{
  var easy:Float;
  var normal:Float;
  var hard:Float;
};

typedef LegacyNoteData =
{
  /**
   * The easy difficulty.
   */
  var ?easy:Array<LegacyNoteSection>;

  /**
   * The normal difficulty.
   */
  var ?normal:Array<LegacyNoteSection>;

  /**
   * The hard difficulty.
   */
  var ?hard:Array<LegacyNoteSection>;
};

typedef LegacyNoteSection =
{
  /**
   * Whether the section is a must-hit section.
   * If true, 0-3 are boyfriends notes, 4-7 are opponents notes.
   * If false, 0-3 are opponents notes, 4-7 are boyfriends notes.
   */
  var mustHitSection:Bool;

  /**
   * Array of note data:
   * - Direction
   * - Time (ms)
   * - Sustain Duration (ms)
   * - Note kind (true = "alt", or string)
   */
  var sectionNotes:Array<LegacyNote>;

  var typeOfSection:Int;
  var lengthInSteps:Int;
}

/**
 * Notes in the old format are stored as an Array<Dynamic>
 */
abstract LegacyNote(Array<Dynamic>)
{
  public var time(get, set):Float;

  function get_time():Float
  {
    return this[0];
  }

  function set_time(value:Float):Float
  {
    return this[0] = value;
  }

  public var data(get, set):Int;

  function get_data():Int
  {
    return this[1];
  }

  function set_data(value:Int):Int
  {
    return this[1] = value;
  }

  public function getData(mustHitSection:Bool):Int
  {
    if (mustHitSection) return this[1];

    return (this[1] + 4) % 8;
  }

  public var length(get, set):Float;

  function get_length():Float
  {
    if (this.length < 3) return 0.0;
    return this[2];
  }

  function set_length(value:Float):Float
  {
    return this[2] = value;
  }

  public var kind(get, set):String;

  function get_kind():String
  {
    if (this.length < 4) return 'normal';

    if (Std.isOfType(this[3], Bool)) return this[3] ? 'alt' : 'normal';

    return this[3];
  }

  function set_kind(value:String):String
  {
    return this[3] = value;
  }
}
