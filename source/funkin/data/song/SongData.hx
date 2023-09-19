package funkin.data.song;

import flixel.util.typeLimit.OneOfTwo;
import funkin.play.song.SongMigrator;
import funkin.play.song.SongValidator;
import funkin.data.song.SongRegistry;
import thx.semver.Version;

class SongMetadata
{
  /**
   * A semantic versioning string for the song data format.
   *
   */
  // @:default(funkin.data.song.SongRegistry.SONG_METADATA_VERSION)
  public var version:Version;

  @:default("Unknown")
  public var songName:String;

  @:default("Unknown")
  public var artist:String;

  @:optional
  @:default(96)
  public var divisions:Null<Int>; // Optional field

  @:optional
  @:default(false)
  public var looped:Bool;

  /**
   * Data relating to the song's gameplay.
   */
  public var playData:SongPlayData;

  // @:default(funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY)
  public var generatedBy:String;

  // @:default(funkin.data.song.SongData.SongTimeFormat.MILLISECONDS)
  public var timeFormat:SongTimeFormat;

  // @:default(funkin.data.song.SongData.SongTimeChange.DEFAULT_SONGTIMECHANGES)
  public var timeChanges:Array<SongTimeChange>;

  /**
   * Defaults to `default` or `''`. Populated later.
   */
  @:jignored
  public var variation:String = 'default';

  public function new(songName:String, artist:String, variation:String = 'default')
  {
    this.version = SongMigrator.CHART_VERSION;
    this.songName = songName;
    this.artist = artist;
    this.timeFormat = 'ms';
    this.divisions = null;
    this.timeChanges = [new SongTimeChange(0, 100)];
    this.looped = false;
    this.playData =
      {
        songVariations: [],
        difficulties: ['normal'],

        playableChars: ['bf' => new SongPlayableChar('gf', 'dad')],

        stage: 'mainStage',
        noteSkin: 'Normal'
      };
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
    // Variation ID.
    this.variation = variation;
  }

  public function clone(?newVariation:String = null):SongMetadata
  {
    var result:SongMetadata = new SongMetadata(this.songName, this.artist, newVariation == null ? this.variation : newVariation);
    result.version = this.version;
    result.timeFormat = this.timeFormat;
    result.divisions = this.divisions;
    result.timeChanges = this.timeChanges;
    result.looped = this.looped;
    result.playData = this.playData;
    result.generatedBy = this.generatedBy;

    return result;
  }

  public function toString():String
  {
    return 'SongMetadata(${this.songName} by ${this.artist}, variation ${this.variation})';
  }
}

enum abstract SongTimeFormat(String) from String to String
{
  var TICKS = 'ticks';
  var FLOAT = 'float';
  var MILLISECONDS = 'ms';
}

class SongTimeChange
{
  public static final DEFAULT_SONGTIMECHANGE:SongTimeChange = new SongTimeChange(0, 100);

  public static final DEFAULT_SONGTIMECHANGES:Array<SongTimeChange> = [DEFAULT_SONGTIMECHANGE];

  static final DEFAULT_BEAT_TUPLETS:Array<Int> = [4, 4, 4, 4];
  static final DEFAULT_BEAT_TIME:Null<Float> = null; // Later, null gets detected and recalculated.

  /**
   * Timestamp in specified `timeFormat`.
   */
  @:alias("t")
  public var timeStamp:Float;

  /**
   * Time in beats (int). The game will calculate further beat values based on this one,
   * so it can do it in a simple linear fashion.
   */
  @:optional
  @:alias("b")
  // @:default(funkin.data.song.SongData.SongTimeChange.DEFAULT_BEAT_TIME)
  public var beatTime:Null<Float>;

  /**
   * Quarter notes per minute (float). Cannot be empty in the first element of the list,
   * but otherwise it's optional, and defaults to the value of the previous element.
   */
  @:alias("bpm")
  public var bpm:Float;

  /**
   * Time signature numerator (int). Optional, defaults to 4.
   */
  @:default(4)
  @:optional
  @:alias("n")
  public var timeSignatureNum:Int;

  /**
   * Time signature denominator (int). Optional, defaults to 4. Should only ever be a power of two.
   */
  @:default(4)
  @:optional
  @:alias("d")
  public var timeSignatureDen:Int;

  /**
   * Beat tuplets (Array<int> or int). This defines how many steps each beat is divided into.
   * It can either be an array of length `n` (see above) or a single integer number.
   * Optional, defaults to `[4]`.
   */
  @:optional
  @:alias("bt")
  public var beatTuplets:Array<Int>;

  public function new(timeStamp:Float, bpm:Float, timeSignatureNum:Int = 4, timeSignatureDen:Int = 4, ?beatTime:Float, ?beatTuplets:Array<Int>)
  {
    this.timeStamp = timeStamp;
    this.bpm = bpm;

    this.timeSignatureNum = timeSignatureNum;
    this.timeSignatureDen = timeSignatureDen;

    this.beatTime = beatTime == null ? DEFAULT_BEAT_TIME : beatTime;
    this.beatTuplets = beatTuplets == null ? DEFAULT_BEAT_TUPLETS : beatTuplets;
  }

  public function toString():String
  {
    return 'SongTimeChange(${this.timeStamp}ms,${this.bpm}bpm)';
  }
}

/**
 * Metadata for a song only used for the music.
 * For example, the menu music.
 */
class SongMusicData
{
  /**
   * A semantic versioning string for the song data format.
   *
   */
  // @:default(funkin.data.song.SongRegistry.SONG_METADATA_VERSION)
  public var version:Version;

  @:default("Unknown")
  public var songName:String;

  @:default("Unknown")
  public var artist:String;

  @:optional
  @:default(96)
  public var divisions:Null<Int>; // Optional field

  @:optional
  @:default(false)
  public var looped:Bool;

  // @:default(funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY)
  public var generatedBy:String;

  // @:default(funkin.data.song.SongData.SongTimeFormat.MILLISECONDS)
  public var timeFormat:SongTimeFormat;

  // @:default(funkin.data.song.SongData.SongTimeChange.DEFAULT_SONGTIMECHANGES)
  public var timeChanges:Array<SongTimeChange>;

  /**
   * Defaults to `default` or `''`. Populated later.
   */
  @:jignored
  public var variation:String = 'default';

  public function new(songName:String, artist:String, variation:String = 'default')
  {
    this.version = SongMigrator.CHART_VERSION;
    this.songName = songName;
    this.artist = artist;
    this.timeFormat = 'ms';
    this.divisions = null;
    this.timeChanges = [new SongTimeChange(0, 100)];
    this.looped = false;
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
    // Variation ID.
    this.variation = variation;
  }

  public function clone(?newVariation:String = null):SongMusicData
  {
    var result:SongMusicData = new SongMusicData(this.songName, this.artist, newVariation == null ? this.variation : newVariation);
    result.version = this.version;
    result.timeFormat = this.timeFormat;
    result.divisions = this.divisions;
    result.timeChanges = this.timeChanges;
    result.looped = this.looped;
    result.generatedBy = this.generatedBy;

    return result;
  }

  public function toString():String
  {
    return 'SongMusicData(${this.songName} by ${this.artist}, variation ${this.variation})';
  }
}

typedef SongPlayData =
{
  public var songVariations:Array<String>;
  public var difficulties:Array<String>;

  /**
   * Keys are the player characters and the values give info on what opponent/GF/inst to use.
   */
  public var playableChars:Map<String, SongPlayableChar>;

  public var stage:String;
  public var noteSkin:String;
}

class SongPlayableChar
{
  @:alias('g')
  @:optional
  @:default('')
  public var girlfriend:String = '';

  @:alias('o')
  @:optional
  @:default('')
  public var opponent:String = '';

  @:alias('i')
  @:optional
  @:default('')
  public var inst:String = '';

  public function new(girlfriend:String = '', opponent:String = '', inst:String = '')
  {
    this.girlfriend = girlfriend;
    this.opponent = opponent;
    this.inst = inst;
  }

  public function toString():String
  {
    return 'SongPlayableChar(${this.girlfriend}, ${this.opponent}, ${this.inst})';
  }
}

class SongChartData
{
  @:default(funkin.data.song.SongRegistry.SONG_CHART_DATA_VERSION)
  public var version:Version;

  public var scrollSpeed:Map<String, Float>;
  public var events:Array<SongEventData>;
  public var notes:Map<String, Array<SongNoteData>>;

  @:default(funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY)
  public var generatedBy:String;

  public function new(scrollSpeed:Map<String, Float>, events:Array<SongEventData>, notes:Map<String, Array<SongNoteData>>)
  {
    this.version = SongRegistry.SONG_CHART_DATA_VERSION;

    this.events = events;
    this.notes = notes;
    this.scrollSpeed = scrollSpeed;

    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
  }

  public function getScrollSpeed(diff:String = 'default'):Float
  {
    var result:Float = this.scrollSpeed.get(diff);

    if (result == 0.0 && diff != 'default') return getScrollSpeed('default');

    return (result == 0.0) ? 1.0 : result;
  }

  public function setScrollSpeed(value:Float, diff:String = 'default'):Float
  {
    this.scrollSpeed.set(diff, value);
    return value;
  }

  public function getNotes(diff:String):Array<SongNoteData>
  {
    var result:Array<SongNoteData> = this.notes.get(diff);

    if (result == null && diff != 'normal') return getNotes('normal');

    return (result == null) ? [] : result;
  }

  public function setNotes(value:Array<SongNoteData>, diff:String):Array<SongNoteData>
  {
    this.notes.set(diff, value);
    return value;
  }

  public function getEvents():Array<SongEventData>
  {
    return this.events;
  }

  public function setEvents(value:Array<SongEventData>):Array<SongEventData>
  {
    return this.events = value;
  }
}

class SongEventData
{
  /**
   * The timestamp of the event. The timestamp is in the format of the song's time format.
   */
  @:alias("t")
  public var time:Float;

  /**
   * The kind of the event.
   * Examples include "FocusCamera" and "PlayAnimation"
   * Custom events can be added by scripts with the `ScriptedSongEvent` class.
   */
  @:alias("e")
  public var event:String;

  /**
   * The data for the event.
   * This can allow the event to include information used for custom behavior.
   * Data type depends on the event kind. It can be anything that's JSON serializable.
   */
  @:alias("v")
  @:optional
  @:jcustomparse(funkin.data.DataParse.dynamicValue)
  public var value:Dynamic = null;

  /**
   * Whether this event has been activated.
   * This is only used internally by the game. It should not be serialized.
   */
  @:jignored
  public var activated:Bool = false;

  public function new(time:Float, event:String, value:Dynamic = null)
  {
    this.time = time;
    this.event = event;
    this.value = value;
  }

  @:jignored
  public var stepTime(get, never):Float;

  function get_stepTime():Float
  {
    return Conductor.getTimeInSteps(this.time);
  }

  public inline function getDynamic(key:String):Null<Dynamic>
  {
    return value == null ? null : Reflect.field(value, key);
  }

  public inline function getBool(key:String):Null<Bool>
  {
    return value == null ? null : cast Reflect.field(value, key);
  }

  public inline function getInt(key:String):Null<Int>
  {
    return value == null ? null : cast Reflect.field(value, key);
  }

  public inline function getFloat(key:String):Null<Float>
  {
    return value == null ? null : cast Reflect.field(value, key);
  }

  public inline function getString(key:String):String
  {
    return value == null ? null : cast Reflect.field(value, key);
  }

  public inline function getArray(key:String):Array<Dynamic>
  {
    return value == null ? null : cast Reflect.field(value, key);
  }

  public inline function getBoolArray(key:String):Array<Bool>
  {
    return value == null ? null : cast Reflect.field(value, key);
  }

  @:op(A == B)
  public function op_equals(other:SongEventData):Bool
  {
    return this.time == other.time && this.event == other.event && this.value == other.value;
  }

  @:op(A != B)
  public function op_notEquals(other:SongEventData):Bool
  {
    return this.time != other.time || this.event != other.event || this.value != other.value;
  }

  @:op(A > B)
  public function op_greaterThan(other:SongEventData):Bool
  {
    return this.time > other.time;
  }

  @:op(A < B)
  public function op_lessThan(other:SongEventData):Bool
  {
    return this.time < other.time;
  }

  @:op(A >= B)
  public function op_greaterThanOrEquals(other:SongEventData):Bool
  {
    return this.time >= other.time;
  }

  @:op(A <= B)
  public function op_lessThanOrEquals(other:SongEventData):Bool
  {
    return this.time <= other.time;
  }

  public function toString():String
  {
    return 'SongEventData(${this.time}ms, ${this.event}: ${this.value})';
  }
}

class SongNoteData
{
  /**
   * The timestamp of the note. The timestamp is in the format of the song's time format.
   */
  @:alias("t")
  public var time:Float;

  /**
   * Data for the note. Represents the index on the strumline.
   * 0 = left, 1 = down, 2 = up, 3 = right
   * `floor(direction / strumlineSize)` specifies which strumline the note is on.
   * 0 = player, 1 = opponent, etc.
   */
  @:alias("d")
  public var data:Int;

  /**
   * Length of the note, if applicable.
   * Defaults to 0 for single notes.
   */
  @:alias("l")
  @:default(0)
  @:optional
  public var length:Float;

  /**
   * The kind of the note.
   * This can allow the note to include information used for custom behavior.
   * Defaults to blank or `"normal"`.
   */
  @:alias("k")
  @:default("normal")
  @:optional
  public var kind(get, default):String = '';

  function get_kind():String
  {
    if (this.kind == null || this.kind == '') return 'normal';

    return this.kind;
  }

  public function new(time:Float, data:Int, length:Float = 0, kind:String = '')
  {
    this.time = time;
    this.data = data;
    this.length = length;
    this.kind = kind;
  }

  /**
   * The timestamp of the note, in steps.
   */
  @:jignored
  public var stepTime(get, never):Float;

  function get_stepTime():Float
  {
    return Conductor.getTimeInSteps(this.time);
  }

  /**
   * The direction of the note, if applicable.
   * Strips the strumline index from the data.
   *
   * 0 = left, 1 = down, 2 = up, 3 = right
   */
  public inline function getDirection(strumlineSize:Int = 4):Int
  {
    return this.data % strumlineSize;
  }

  public function getDirectionName(strumlineSize:Int = 4):String
  {
    switch (this.data % strumlineSize)
    {
      case 0:
        return 'Left';
      case 1:
        return 'Down';
      case 2:
        return 'Up';
      case 3:
        return 'Right';
      default:
        return 'Unknown';
    }
  }

  /**
   * The strumline index of the note, if applicable.
   * Strips the direction from the data.
   *
   * 0 = player, 1 = opponent, etc.
   */
  public inline function getStrumlineIndex(strumlineSize:Int = 4):Int
  {
    return Math.floor(this.data / strumlineSize);
  }

  /**
   * Returns true if the note is one that Boyfriend should try to hit (i.e. it's on his side).
   * TODO: The name of this function is a little misleading; what about mines?
   * @param strumlineSize Defaults to 4.
   * @return True if it's Boyfriend's note.
   */
  public inline function getMustHitNote(strumlineSize:Int = 4):Bool
  {
    return getStrumlineIndex(strumlineSize) == 0;
  }

  /**
   * If this is a hold note, this is the length of the hold note in steps.
   * @default 0 (not a hold note)
   */
  public var stepLength(get, set):Float;

  function get_stepLength():Float
  {
    return Conductor.getTimeInSteps(this.time + this.length) - this.stepTime;
  }

  function set_stepLength(value:Float):Float
  {
    return this.length = Conductor.getStepTimeInMs(value) - this.time;
  }

  @:jignored
  public var isHoldNote(get, never):Bool;

  public function get_isHoldNote():Bool
  {
    return this.length > 0;
  }

  @:op(A == B)
  public function op_equals(other:SongNoteData):Bool
  {
    if (this.kind == '')
    {
      if (other.kind != '' && other.kind != 'normal') return false;
    }
    else
    {
      if (other.kind == '' || other.kind != this.kind) return false;
    }

    return this.time == other.time && this.data == other.data && this.length == other.length;
  }

  @:op(A != B)
  public function op_notEquals(other:SongNoteData):Bool
  {
    if (this.kind == '')
    {
      if (other.kind != '' && other.kind != 'normal') return true;
    }
    else
    {
      if (other.kind == '' || other.kind != this.kind) return true;
    }

    return this.time != other.time || this.data != other.data || this.length != other.length;
  }

  @:op(A > B)
  public function op_greaterThan(other:SongNoteData):Bool
  {
    return this.time > other.time;
  }

  @:op(A < B)
  public function op_lessThan(other:SongNoteData):Bool
  {
    return this.time < other.time;
  }

  @:op(A >= B)
  public function op_greaterThanOrEquals(other:SongNoteData):Bool
  {
    return this.time >= other.time;
  }

  @:op(A <= B)
  public function op_lessThanOrEquals(other:SongNoteData):Bool
  {
    return this.time <= other.time;
  }

  public function toString():String
  {
    return 'SongNoteData(${this.time}ms, ' + (this.length > 0 ? '[${this.length}ms hold]' : '') + ' ${this.data}'
      + (this.kind != '' ? ' [kind: ${this.kind}])' : ')');
  }
}
