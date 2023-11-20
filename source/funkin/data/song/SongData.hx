package funkin.data.song;

import funkin.data.song.SongRegistry;
import thx.semver.Version;

/**
 * Data containing information about a song.
 * It should contain all the data needed to display a song in the Freeplay menu, or to load the assets required to play its chart.
 * Data which is only necessary in-game should be stored in the SongChartData.
 */
@:nullSafety
class SongMetadata
{
  /**
   * A semantic versioning string for the song data format.
   *
   */
  // @:default(funkin.data.song.SongRegistry.SONG_METADATA_VERSION)
  @:jcustomparse(funkin.data.DataParse.semverVersion)
  @:jcustomwrite(funkin.data.DataWrite.semverVersion)
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

  @:default(funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY)
  public var generatedBy:String;

  public var timeFormat:SongTimeFormat;

  public var timeChanges:Array<SongTimeChange>;

  /**
   * Defaults to `Constants.DEFAULT_VARIATION`. Populated later.
   */
  @:jignored
  public var variation:String;

  public function new(songName:String, artist:String, ?variation:String)
  {
    this.version = SongRegistry.SONG_METADATA_VERSION;
    this.songName = songName;
    this.artist = artist;
    this.timeFormat = 'ms';
    this.divisions = null;
    this.timeChanges = [new SongTimeChange(0, 100)];
    this.looped = false;
    this.playData = new SongPlayData();
    this.playData.songVariations = [];
    this.playData.difficulties = [];
    this.playData.characters = new SongCharacterData('bf', 'gf', 'dad');
    this.playData.stage = 'mainStage';
    this.playData.noteStyle = Constants.DEFAULT_NOTE_STYLE;
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
    // Variation ID.
    this.variation = (variation == null) ? Constants.DEFAULT_VARIATION : variation;
  }

  /**
   * Create a copy of this SongMetadata with the same information.
   * @param newVariation Set to a new variation ID to change the new metadata.
   * @return The cloned SongMetadata
   */
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

  /**
   * Serialize this SongMetadata into a JSON string.
   * @return The JSON string.
   */
  public function serialize(pretty:Bool = true):String
  {
    var writer = new json2object.JsonWriter<SongMetadata>();
    // I believe @:jignored should be iggnored by the writer?
    // var output = this.clone();
    // output.variation = null; // Not sure how to make a field optional on the reader and ignored on the writer.
    return writer.write(this, pretty ? '  ' : null);
  }

  /**
   * Produces a string representation suitable for debugging.
   */
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

  /**
   * Produces a string representation suitable for debugging.
   */
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
  @:jcustomparse(funkin.data.DataParse.semverVersion)
  @:jcustomwrite(funkin.data.DataWrite.semverVersion)
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
  public var looped:Null<Bool>;

  // @:default(funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY)
  public var generatedBy:String;

  // @:default(funkin.data.song.SongData.SongTimeFormat.MILLISECONDS)
  public var timeFormat:SongTimeFormat;

  // @:default(funkin.data.song.SongData.SongTimeChange.DEFAULT_SONGTIMECHANGES)
  public var timeChanges:Array<SongTimeChange>;

  /**
   * Defaults to `Constants.DEFAULT_VARIATION`. Populated later.
   */
  @:jignored
  public var variation:String;

  public function new(songName:String, artist:String, variation:String = 'default')
  {
    this.version = SongRegistry.SONG_CHART_DATA_VERSION;
    this.songName = songName;
    this.artist = artist;
    this.timeFormat = 'ms';
    this.divisions = null;
    this.timeChanges = [new SongTimeChange(0, 100)];
    this.looped = false;
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
    // Variation ID.
    this.variation = variation == null ? Constants.DEFAULT_VARIATION : variation;
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

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongMusicData(${this.songName} by ${this.artist}, variation ${this.variation})';
  }
}

class SongPlayData
{
  /**
   * The variations this song has. The associated metadata files should exist.
   */
  @:default([])
  @:optional
  public var songVariations:Array<String>;

  /**
   * The difficulties contained in this song's chart file.
   */
  public var difficulties:Array<String>;

  /**
   * The characters used by this song.
   */
  public var characters:SongCharacterData;

  /**
   * The stage used by this song.
   */
  public var stage:String;

  /**
   * The note style used by this song.
   */
  public var noteStyle:String;

  /**
   * The difficulty ratings for this song as displayed in Freeplay.
   * Key is a difficulty ID or `default`.
   */
  @:default(['default' => 1])
  public var ratings:Map<String, Int>;

  /**
   * The album ID for the album to display in Freeplay.
   * If `null`, display no album.
   */
  @:optional
  public var album:Null<String>;

  public function new()
  {
    ratings = new Map<String, Int>();
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongPlayData(${this.songVariations}, ${this.difficulties})';
  }
}

/**
 * Information about the characters used in this variation of the song.
 * Create a new variation if you want to change the characters.
 */
class SongCharacterData
{
  @:optional
  @:default('')
  public var player:String = '';

  @:optional
  @:default('')
  public var girlfriend:String = '';

  @:optional
  @:default('')
  public var opponent:String = '';

  @:optional
  @:default('')
  public var instrumental:String = '';

  @:optional
  @:default([])
  public var altInstrumentals:Array<String> = [];

  public function new(player:String = '', girlfriend:String = '', opponent:String = '', instrumental:String = '')
  {
    this.player = player;
    this.girlfriend = girlfriend;
    this.opponent = opponent;
    this.instrumental = instrumental;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongCharacterData(${this.player}, ${this.girlfriend}, ${this.opponent}, ${this.instrumental}, [${this.altInstrumentals.join(', ')}])';
  }
}

class SongChartData
{
  @:default(funkin.data.song.SongRegistry.SONG_CHART_DATA_VERSION)
  @:jcustomparse(funkin.data.DataParse.semverVersion)
  @:jcustomwrite(funkin.data.DataWrite.semverVersion)
  public var version:Version;

  public var scrollSpeed:Map<String, Float>;
  public var events:Array<SongEventData>;
  public var notes:Map<String, Array<SongNoteData>>;

  @:default(funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY)
  public var generatedBy:String;

  /**
   * Defaults to `Constants.DEFAULT_VARIATION`. Populated later.
   */
  @:jignored
  public var variation:String;

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

  /**
   * Convert this SongChartData into a JSON string.
   */
  public function serialize(pretty:Bool = true):String
  {
    var writer = new json2object.JsonWriter<SongChartData>();
    return writer.write(this, pretty ? '  ' : null);
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongChartData(${this.events.length} events, ${this.notes.size()} difficulties, ${generatedBy})';
  }
}

class SongEventDataRaw
{
  /**
   * The timestamp of the event. The timestamp is in the format of the song's time format.
   */
  @:alias("t")
  public var time(default, set):Float;

  function set_time(value:Float):Float
  {
    _stepTime = null;
    return time = value;
  }

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
  @:jcustomwrite(funkin.data.DataWrite.dynamicValue)
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
  var _stepTime:Null<Float> = null;

  public function getStepTime(force:Bool = false):Float
  {
    if (_stepTime != null && !force) return _stepTime;

    return _stepTime = Conductor.getTimeInSteps(this.time);
  }
}

/**
 * Wrap SongEventData in an abstract so we can overload operators.
 */
@:forward(time, event, value, activated, getStepTime)
abstract SongEventData(SongEventDataRaw) from SongEventDataRaw to SongEventDataRaw
{
  public function new(time:Float, event:String, value:Dynamic = null)
  {
    this = new SongEventDataRaw(time, event, value);
  }

  public inline function getDynamic(key:String):Null<Dynamic>
  {
    return this.value == null ? null : Reflect.field(this.value, key);
  }

  public inline function getBool(key:String):Null<Bool>
  {
    return this.value == null ? null : cast Reflect.field(this.value, key);
  }

  public inline function getInt(key:String):Null<Int>
  {
    if (this.value == null) return null;
    var result = Reflect.field(this.value, key);
    if (result == null) return null;
    if (Std.isOfType(result, Int)) return result;
    if (Std.isOfType(result, String)) return Std.parseInt(cast result);
    return cast result;
  }

  public inline function getFloat(key:String):Null<Float>
  {
    if (this.value == null) return null;
    var result = Reflect.field(this.value, key);
    if (result == null) return null;
    if (Std.isOfType(result, Float)) return result;
    if (Std.isOfType(result, String)) return Std.parseFloat(cast result);
    return cast result;
  }

  public inline function getString(key:String):String
  {
    return this.value == null ? null : cast Reflect.field(this.value, key);
  }

  public inline function getArray(key:String):Array<Dynamic>
  {
    return this.value == null ? null : cast Reflect.field(this.value, key);
  }

  public inline function getBoolArray(key:String):Array<Bool>
  {
    return this.value == null ? null : cast Reflect.field(this.value, key);
  }

  public function clone():SongEventData
  {
    return new SongEventData(this.time, this.event, this.value);
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

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongEventData(${this.time}ms, ${this.event}: ${this.value})';
  }
}

class SongNoteDataRaw
{
  /**
   * The timestamp of the note. The timestamp is in the format of the song's time format.
   */
  @:alias("t")
  public var time(default, set):Float;

  function set_time(value:Float):Float
  {
    _stepTime = null;
    return time = value;
  }

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
    return SongNoteData.buildDirectionName(this.data, strumlineSize);
  }

  @:jignored
  var _stepTime:Null<Float> = null;

  /**
   * @param force Set to `true` to force recalculation (good after BPM changes)
   * @return The position of the note in the song, in steps.
   */
  public function getStepTime(force:Bool = false):Float
  {
    if (_stepTime != null && !force) return _stepTime;

    return _stepTime = Conductor.getTimeInSteps(this.time);
  }

  @:jignored
  var _stepLength:Null<Float> = null;

  /**
   * @param force Set to `true` to force recalculation (good after BPM changes)
   * @return The length of the hold note in steps, or `0` if this is not a hold note.
   */
  public function getStepLength(force = false):Float
  {
    if (this.length <= 0) return 0.0;

    if (_stepLength != null && !force) return _stepLength;

    return _stepLength = Conductor.getTimeInSteps(this.time + this.length) - getStepTime();
  }

  public function setStepLength(value:Float):Void
  {
    if (value <= 0)
    {
      this.length = 0.0;
    }
    else
    {
      var lengthMs:Float = Conductor.getStepTimeInMs(value) - this.time;
      this.length = lengthMs;
    }
    _stepLength = null;
  }
}

/**
 * Wrap SongNoteData in an abstract so we can overload operators.
 */
@:forward
abstract SongNoteData(SongNoteDataRaw) from SongNoteDataRaw to SongNoteDataRaw
{
  public function new(time:Float, data:Int, length:Float = 0, kind:String = '')
  {
    this = new SongNoteDataRaw(time, data, length, kind);
  }

  public static function buildDirectionName(data:Int, strumlineSize:Int = 4):String
  {
    switch (data % strumlineSize)
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

  public function clone():SongNoteData
  {
    return new SongNoteData(this.time, this.data, this.length, this.kind);
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongNoteData(${this.time}ms, ' + (this.length > 0 ? '[${this.length}ms hold]' : '') + ' ${this.data}'
      + (this.kind != '' ? ' [kind: ${this.kind}])' : ')');
  }
}
