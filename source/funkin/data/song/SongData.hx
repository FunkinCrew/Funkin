package funkin.data.song;

import funkin.data.event.SongEventRegistry;
import funkin.play.event.SongEvent;
import funkin.data.event.SongEventSchema;
import funkin.data.song.SongRegistry;
import thx.semver.Version;
import funkin.util.tools.ICloneable;

/**
 * Data containing information about a song.
 * It should contain all the data needed to display a song in the Freeplay menu, or to load the assets required to play its chart.
 * Data which is only necessary in-game should be stored in the SongChartData.
 */
@:nullSafety
class SongMetadata implements ICloneable<SongMetadata>
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
  public var charter:Null<String> = null;

  @:optional
  @:default(96)
  public var divisions:Null<Int>; // Optional field

  @:optional
  @:default(false)
  public var looped:Bool;

  /**
   * Instrumental and vocal offsets.
   * Defaults to an empty SongOffsets object.
   */
  @:optional
  public var offsets:Null<SongOffsets>;

  /**
   * Data relating to the song's gameplay.
   */
  public var playData:SongPlayData;

  @:default(funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY)
  public var generatedBy:String;

  @:optional
  @:default(funkin.data.song.SongData.SongTimeFormat.MILLISECONDS)
  public var timeFormat:SongTimeFormat;

  public var timeChanges:Array<SongTimeChange>;

  /**
   * Defaults to `Constants.DEFAULT_VARIATION`. Populated later.
   */
  @:jignored
  public var variation:String;

  public function new(songName:String, artist:String, ?charter:String, ?variation:String)
  {
    this.version = SongRegistry.SONG_METADATA_VERSION;
    this.songName = songName;
    this.artist = artist;
    this.charter = (charter == null) ? null : charter;
    this.timeFormat = 'ms';
    this.divisions = null;
    this.offsets = new SongOffsets();
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
  public function clone():SongMetadata
  {
    var result:SongMetadata = new SongMetadata(this.songName, this.artist, this.charter, this.variation);
    result.version = this.version;
    result.timeFormat = this.timeFormat;
    result.divisions = this.divisions;
    result.offsets = this.offsets != null ? this.offsets.clone() : new SongOffsets(); // if no song offsets found (aka null), so just create new ones
    result.timeChanges = this.timeChanges.deepClone();
    result.looped = this.looped;
    result.playData = this.playData.clone();
    result.generatedBy = this.generatedBy;

    return result;
  }

  /**
   * Serialize this SongMetadata into a JSON string.
   * @param pretty Whether the JSON should be big ol string (false),
   * or formatted with tabs (true)
   * @return The JSON string.
   */
  public function serialize(pretty:Bool = true):String
  {
    // Update generatedBy and version before writing.
    updateVersionToLatest();

    var ignoreNullOptionals = true;
    var writer = new json2object.JsonWriter<SongMetadata>(ignoreNullOptionals);
    // I believe @:jignored should be ignored by the writer?
    // var output = this.clone();
    // output.variation = null; // Not sure how to make a field optional on the reader and ignored on the writer.
    return writer.write(this, pretty ? '  ' : null);
  }

  public function updateVersionToLatest():Void
  {
    this.version = SongRegistry.SONG_METADATA_VERSION;
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongMetadata(${this.songName} by ${this.artist}, charted by ${this.charter}, variation ${this.variation})';
  }
}

enum abstract SongTimeFormat(String) from String to String
{
  var TICKS = 'ticks';
  var FLOAT = 'float';
  var MILLISECONDS = 'ms';
}

class SongTimeChange implements ICloneable<SongTimeChange>
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
  public var beatTime:Float;

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

  public function clone():SongTimeChange
  {
    return new SongTimeChange(this.timeStamp, this.bpm, this.timeSignatureNum, this.timeSignatureDen, this.beatTime, this.beatTuplets);
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
 * Offsets to apply to the song's instrumental and vocals, relative to the chart.
 * These are intended to correct for issues with the chart, or with the song's audio (for example a 10ms delay before the song starts).
 * This is independent of the offsets applied in the user's settings, which are applied after these offsets and intended to correct for the user's hardware.
 */
class SongOffsets implements ICloneable<SongOffsets>
{
  /**
   * The offset, in milliseconds, to apply to the song's instrumental relative to the chart.
   * For example, setting this to `-10.0` will start the instrumental 10ms earlier than the chart.
   *
   * Setting this to `-5000.0` means the chart start 5 seconds into the song.
   * Setting this to `5000.0` means there will be 5 seconds of silence before the song starts.
   */
  @:optional
  @:default(0)
  public var instrumental:Float;

  /**
   * Apply different offsets to different alternate instrumentals.
   */
  @:optional
  @:default([])
  public var altInstrumentals:Map<String, Float>;

  /**
   * The offset, in milliseconds, to apply to the song's vocals, relative to the song's base instrumental.
   * These are applied ON TOP OF the instrumental offset.
   */
  @:optional
  @:default([])
  public var vocals:Map<String, Float>;

  /**
   * The offset, in milliseconds, to apply to the songs vocals, relative to each alternate instrumental.
   * This is useful for the circumstance where, for example, an alt instrumental has a few seconds of lead in before the song starts.
   */
  @:optional
  @:default([])
  public var altVocals:Map<String, Map<String, Float>>;

  public function new(instrumental:Float = 0.0, ?altInstrumentals:Map<String, Float>, ?vocals:Map<String, Float>, ?altVocals:Map<String, Map<String, Float>>)
  {
    this.instrumental = instrumental;
    this.altInstrumentals = altInstrumentals == null ? new Map<String, Float>() : altInstrumentals;
    this.vocals = vocals == null ? new Map<String, Float>() : vocals;
    this.altVocals = altVocals == null ? new Map<String, Map<String, Float>>() : altVocals;
  }

  public function getInstrumentalOffset(?instrumental:String):Float
  {
    if (instrumental == null || instrumental == '') return this.instrumental;

    if (!this.altInstrumentals.exists(instrumental)) return this.instrumental;

    return this.altInstrumentals.get(instrumental);
  }

  public function setInstrumentalOffset(value:Float, ?instrumental:String):Float
  {
    if (instrumental == null || instrumental == '')
    {
      this.instrumental = value;
    }
    else
    {
      this.altInstrumentals.set(instrumental, value);
    }
    return value;
  }

  public function getVocalOffset(charId:String, ?instrumental:String):Float
  {
    if (instrumental == null)
    {
      if (!this.vocals.exists(charId)) return 0.0;
      return this.vocals.get(charId);
    }
    else
    {
      if (!this.altVocals.exists(instrumental)) return 0.0;
      if (!this.altVocals.get(instrumental).exists(charId)) return 0.0;
      return this.altVocals.get(instrumental).get(charId);
    }
  }

  public function setVocalOffset(charId:String, value:Float):Float
  {
    this.vocals.set(charId, value);
    return value;
  }

  public function clone():SongOffsets
  {
    var result:SongOffsets = new SongOffsets(this.instrumental);
    result.altInstrumentals = this.altInstrumentals.clone();
    result.vocals = this.vocals.clone();

    return result;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongOffsets(${this.instrumental}ms, ${this.altInstrumentals}, ${this.vocals}, ${this.altVocals})';
  }
}

/**
 * Metadata for a song only used for the music.
 * For example, the menu music.
 */
class SongMusicData implements ICloneable<SongMusicData>
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

  public function updateVersionToLatest():Void
  {
    this.version = SongRegistry.SONG_MUSIC_DATA_VERSION;
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
  }

  public function clone():SongMusicData
  {
    var result:SongMusicData = new SongMusicData(this.songName, this.artist, this.variation);
    result.version = this.version;
    result.timeFormat = this.timeFormat;
    result.divisions = this.divisions;
    result.timeChanges = this.timeChanges.clone();
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

class SongPlayData implements ICloneable<SongPlayData>
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
   * Key is a difficulty ID.
   */
  @:optional
  @:default(['normal' => 0])
  public var ratings:Map<String, Int>;

  /**
   * The album ID for the album to display in Freeplay.
   * If `null`, display no album.
   */
  @:optional
  public var album:Null<String>;

  /**
   * The sticker pack for the song to use during transitions.
   * If `null`, display the character's sticker pack.
   */
  @:optional
  public var stickerPack:Null<String>;

  /**
   * The start time for the audio preview in Freeplay.
   * Defaults to 0 seconds in.
   * @since `2.2.2`
   */
  @:optional
  @:default(0)
  public var previewStart:Int;

  /**
   * The end time for the audio preview in Freeplay.
   * Defaults to 15 seconds in.
   * @since `2.2.2`
   */
  @:optional
  @:default(15000)
  public var previewEnd:Int;

  public function new()
  {
    ratings = new Map<String, Int>();
  }

  public function clone():SongPlayData
  {
    // TODO: This sucks! If you forget to update this you get weird behavior.
    var result:SongPlayData = new SongPlayData();
    result.songVariations = this.songVariations.clone();
    result.difficulties = this.difficulties.clone();
    result.characters = this.characters.clone();
    result.stage = this.stage;
    result.noteStyle = this.noteStyle;
    result.ratings = this.ratings.clone();
    result.album = this.album;
    result.previewStart = this.previewStart;
    result.previewEnd = this.previewEnd;

    return result;
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
class SongCharacterData implements ICloneable<SongCharacterData>
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

  @:optional
  public var opponentVocals:Null<Array<String>> = null;

  @:optional
  public var playerVocals:Null<Array<String>> = null;

  public function new(player:String = '', girlfriend:String = '', opponent:String = '', instrumental:String = '', ?altInstrumentals:Array<String>,
      ?opponentVocals:Array<String>, ?playerVocals:Array<String>)
  {
    this.player = player;
    this.girlfriend = girlfriend;
    this.opponent = opponent;
    this.instrumental = instrumental;

    this.altInstrumentals = altInstrumentals;
    this.opponentVocals = opponentVocals;
    this.playerVocals = playerVocals;

    if (opponentVocals == null) this.opponentVocals = [opponent];
    if (playerVocals == null) this.playerVocals = [player];
  }

  public function clone():SongCharacterData
  {
    var result:SongCharacterData = new SongCharacterData(this.player, this.girlfriend, this.opponent, this.instrumental);
    result.altInstrumentals = this.altInstrumentals.clone();

    return result;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongCharacterData(${this.player}, ${this.girlfriend}, ${this.opponent}, ${this.instrumental}, [${this.altInstrumentals.join(', ')}])';
  }
}

class SongChartData implements ICloneable<SongChartData>
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
    // Update generatedBy and version before writing.
    updateVersionToLatest();

    var ignoreNullOptionals = true;
    var writer = new json2object.JsonWriter<SongChartData>(ignoreNullOptionals);
    return writer.write(this, pretty ? '  ' : null);
  }

  public function updateVersionToLatest():Void
  {
    this.version = SongRegistry.SONG_CHART_DATA_VERSION;
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
  }

  public function clone():SongChartData
  {
    // We have to manually perform the deep clone here because Map.deepClone() doesn't work.
    var noteDataClone:Map<String, Array<SongNoteData>> = new Map<String, Array<SongNoteData>>();
    for (key in this.notes.keys())
    {
      noteDataClone.set(key, this.notes.get(key).deepClone());
    }
    var eventDataClone:Array<SongEventData> = this.events.deepClone();

    var result:SongChartData = new SongChartData(this.scrollSpeed.clone(), eventDataClone, noteDataClone);
    result.version = this.version;
    result.generatedBy = this.generatedBy;
    result.variation = this.variation;

    return result;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongChartData(${this.events.length} events, ${this.notes.size()} difficulties, ${generatedBy})';
  }
}

class SongEventDataRaw implements ICloneable<SongEventDataRaw>
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
  public var eventKind:String;

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

  public function new(time:Float, eventKind:String, value:Dynamic = null)
  {
    this.time = time;
    this.eventKind = eventKind;
    this.value = value;
  }

  @:jignored
  var _stepTime:Null<Float> = null;

  public function getStepTime(force:Bool = false):Float
  {
    if (_stepTime != null && !force) return _stepTime;

    return _stepTime = Conductor.instance.getTimeInSteps(this.time);
  }

  public function clone():SongEventDataRaw
  {
    return new SongEventDataRaw(this.time, this.eventKind, this.value);
  }

  public function valueAsStruct(?defaultKey:String = "key"):Dynamic
  {
    if (this.value == null) return {};
    if (Std.isOfType(this.value, Array))
    {
      var result:haxe.DynamicAccess<Dynamic> = {};
      result.set(defaultKey, this.value);
      return cast result;
    }
    else if (Reflect.isObject(this.value))
    {
      // We enter this case if the value is a struct.
      return cast this.value;
    }
    else
    {
      var result:haxe.DynamicAccess<Dynamic> = {};
      result.set(defaultKey, this.value);
      return cast result;
    }
  }

  public function getHandler():Null<SongEvent>
  {
    return SongEventRegistry.getEvent(this.eventKind);
  }

  public function getSchema():Null<SongEventSchema>
  {
    return SongEventRegistry.getEventSchema(this.eventKind);
  }

  public function getDynamic(key:String):Null<Dynamic>
  {
    return this.value == null ? null : Reflect.field(this.value, key);
  }

  public function getBool(key:String):Null<Bool>
  {
    return this.value == null ? null : cast Reflect.field(this.value, key);
  }

  public function getInt(key:String):Null<Int>
  {
    if (this.value == null) return null;
    var result = Reflect.field(this.value, key);
    if (result == null) return null;
    if (Std.isOfType(result, Int)) return result;
    if (Std.isOfType(result, String)) return Std.parseInt(cast result);
    return cast result;
  }

  public function getFloat(key:String):Null<Float>
  {
    if (this.value == null) return null;
    var result = Reflect.field(this.value, key);
    if (result == null) return null;
    if (Std.isOfType(result, Float)) return result;
    if (Std.isOfType(result, String)) return Std.parseFloat(cast result);
    return cast result;
  }

  public function getString(key:String):String
  {
    return this.value == null ? null : cast Reflect.field(this.value, key);
  }

  public function getArray(key:String):Array<Dynamic>
  {
    return this.value == null ? null : cast Reflect.field(this.value, key);
  }

  public function getBoolArray(key:String):Array<Bool>
  {
    return this.value == null ? null : cast Reflect.field(this.value, key);
  }

  public function buildTooltip():String
  {
    var eventHandler = getHandler();
    var eventSchema = getSchema();

    if (eventSchema == null) return 'Unknown Event: ${this.eventKind}';

    var result = '${eventHandler.getTitle()}';

    var defaultKey = eventSchema.getFirstField()?.name;
    var valueStruct:haxe.DynamicAccess<Dynamic> = valueAsStruct(defaultKey);

    for (pair in valueStruct.keyValueIterator())
    {
      var key = pair.key;
      var value = pair.value;

      var title = eventSchema.getByName(key)?.title ?? 'UnknownField';

      // if (eventSchema.stringifyFieldValue(key, value) != null) trace(eventSchema.stringifyFieldValue(key, value));
      var valueStr = eventSchema.stringifyFieldValue(key, value) ?? 'UnknownValue';

      result += '\n- ${title}: ${valueStr}';
    }

    return result;
  }
}

/**
 * Wrap SongEventData in an abstract so we can overload operators.
 */
@:forward(time, eventKind, value, activated, getStepTime, clone, getHandler, getSchema, getDynamic, getBool, getInt, getFloat, getString, getArray,
  getBoolArray, buildTooltip, valueAsStruct)
abstract SongEventData(SongEventDataRaw) from SongEventDataRaw to SongEventDataRaw
{
  public function new(time:Float, eventKind:String, value:Dynamic = null)
  {
    this = new SongEventDataRaw(time, eventKind, value);
  }

  public function clone():SongEventData
  {
    return new SongEventData(this.time, this.eventKind, this.value);
  }

  @:op(A == B)
  public function op_equals(other:SongEventData):Bool
  {
    return this.time == other.time && this.eventKind == other.eventKind && this.value == other.value;
  }

  @:op(A != B)
  public function op_notEquals(other:SongEventData):Bool
  {
    return this.time != other.time || this.eventKind != other.eventKind || this.value != other.value;
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
    return 'SongEventData(${this.time}ms, ${this.eventKind}: ${this.value})';
  }
}

class SongNoteDataRaw implements ICloneable<SongNoteDataRaw>
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
  public var length(default, set):Float;

  function set_length(value:Float):Float
  {
    _stepLength = null;
    return length = value;
  }

  /**
   * The kind of the note.
   * This can allow the note to include information used for custom behavior.
   * Defaults to `null` for no kind.
   */
  @:alias("k")
  @:optional
  @:isVar
  public var kind(get, set):Null<String> = null;

  function get_kind():Null<String>
  {
    if (this.kind == null || this.kind == '') return null;

    return this.kind;
  }

  function set_kind(value:Null<String>):Null<String>
  {
    if (value == '') value = null;
    return this.kind = value;
  }

  @:alias("p")
  @:default([])
  @:optional
  public var params:Array<NoteParamData>;

  public function new(time:Float, data:Int, length:Float = 0, kind:String = '', ?params:Array<NoteParamData>)
  {
    this.time = time;
    this.data = data;
    this.length = length;
    this.kind = kind;
    this.params = params ?? [];
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

  /**
   * The strumline index of the note, if applicable.
   * Strips the direction from the data.
   *
   * 0 = player, 1 = opponent, etc.
   */
  public function getStrumlineIndex(strumlineSize:Int = 4):Int
  {
    return Math.floor(this.data / strumlineSize);
  }

  /**
   * Returns true if the note is one that Boyfriend should try to hit (i.e. it's on his side).
   * TODO: The name of this function is a little misleading; what about mines?
   * @param strumlineSize Defaults to 4.
   * @return True if it's Boyfriend's note.
   */
  public function getMustHitNote(strumlineSize:Int = 4):Bool
  {
    return getStrumlineIndex(strumlineSize) == 0;
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

    return _stepTime = Conductor.instance.getTimeInSteps(this.time);
  }

  /**
   * The length of the note, if applicable, in steps.
   * Calculated from the length and the BPM.
   * Cached for performance. Set to `null` to recalculate.
   */
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

    return _stepLength = Conductor.instance.getTimeInSteps(this.time + this.length) - getStepTime();
  }

  public function setStepLength(value:Float):Void
  {
    if (value <= 0)
    {
      this.length = 0.0;
    }
    else
    {
      var endStep:Float = getStepTime() + value;
      var endMs:Float = Conductor.instance.getStepTimeInMs(endStep);
      var lengthMs:Float = endMs - this.time;

      this.length = lengthMs;
    }

    // Recalculate the step length next time it's requested.
    _stepLength = null;
  }

  public function cloneParams():Array<NoteParamData>
  {
    var params:Array<NoteParamData> = [];
    for (param in this.params)
    {
      params.push(param.clone());
    }
    return params;
  }

  public function clone():SongNoteDataRaw
  {
    return new SongNoteDataRaw(this.time, this.data, this.length, this.kind, cloneParams());
  }

  public function toString():String
  {
    return 'SongNoteData(${this.time}ms, ' + (this.length > 0 ? '[${this.length}ms hold]' : '') + ' ${this.data}'
      + (this.kind != '' ? ' [kind: ${this.kind}])' : ')');
  }
}

/**
 * Wrap SongNoteData in an abstract so we can overload operators.
 */
@:forward
abstract SongNoteData(SongNoteDataRaw) from SongNoteDataRaw to SongNoteDataRaw
{
  public function new(time:Float, data:Int, length:Float = 0, kind:String = '', ?params:Array<NoteParamData>)
  {
    this = new SongNoteDataRaw(time, data, length, kind, params);
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

  @:jignored
  public var isHoldNote(get, never):Bool;

  public function get_isHoldNote():Bool
  {
    return this.length > 0;
  }

  @:op(A == B)
  public function op_equals(other:SongNoteData):Bool
  {
    // Handle the case where one value is null.
    if (this == null) return other == null;
    if (other == null) return false;

    if (this.kind == null || this.kind == '')
    {
      if (other.kind != '' && this.kind != null) return false;
    }
    else
    {
      if (other.kind == '' || this.kind == null) return false;
    }

    return this.time == other.time && this.data == other.data && this.length == other.length && this.params == other.params;
  }

  @:op(A != B)
  public function op_notEquals(other:SongNoteData):Bool
  {
    // Handle the case where one value is null.
    if (this == null) return other == null;
    if (other == null) return false;

    if (this.kind == '')
    {
      if (other.kind != '') return true;
    }
    else
    {
      if (other.kind == '') return true;
    }

    return this.time != other.time || this.data != other.data || this.length != other.length || this.params != other.params;
  }

  @:op(A > B)
  public function op_greaterThan(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.time > other.time;
  }

  @:op(A < B)
  public function op_lessThan(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.time < other.time;
  }

  @:op(A >= B)
  public function op_greaterThanOrEquals(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.time >= other.time;
  }

  @:op(A <= B)
  public function op_lessThanOrEquals(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.time <= other.time;
  }

  public function clone():SongNoteData
  {
    return new SongNoteData(this.time, this.data, this.length, this.kind, this.params);
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

class NoteParamData implements ICloneable<NoteParamData>
{
  @:alias("n")
  public var name:String;

  @:alias("v")
  @:jcustomparse(funkin.data.DataParse.dynamicValue)
  @:jcustomwrite(funkin.data.DataWrite.dynamicValue)
  public var value:Dynamic;

  public function new(name:String, value:Dynamic)
  {
    this.name = name;
    this.value = value;
  }

  public function clone():NoteParamData
  {
    return new NoteParamData(this.name, this.value);
  }

  public function toString():String
  {
    return 'NoteParamData(${this.name}, ${this.value})';
  }
}
