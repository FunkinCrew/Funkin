package funkin.play.song;

import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import flixel.util.typeLimit.OneOfTwo;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.song.ScriptedSong;
import funkin.util.assets.DataAssets;
import haxe.DynamicAccess;
import haxe.Json;
import openfl.utils.Assets;
import thx.semver.Version;

/**
 * Contains utilities for loading and parsing stage data.
 */
class SongDataParser
{
  /**
   * A list containing all the songs available to the game.
   */
  static final songCache:Map<String, Song> = new Map<String, Song>();

  static final DEFAULT_SONG_ID:String = 'UNKNOWN';
  static final SONG_DATA_PATH:String = 'songs/';
  static final MUSIC_DATA_PATH:String = 'music/';
  static final SONG_DATA_SUFFIX:String = '-metadata.json';

  /**
   * Parses and preloads the game's song metadata and scripts when the game starts.
   *
   * If you want to force song metadata to be reloaded, you can just call this function again.
   */
  public static function loadSongCache():Void
  {
    clearSongCache();
    trace('Loading song cache...');

    //
    // SCRIPTED SONGS
    //
    var scriptedSongClassNames:Array<String> = ScriptedSong.listScriptClasses();
    trace('  Instantiating ${scriptedSongClassNames.length} scripted songs...');
    for (songCls in scriptedSongClassNames)
    {
      var song:Song = ScriptedSong.init(songCls, DEFAULT_SONG_ID);
      if (song != null)
      {
        trace('    Loaded scripted song: ${song.songId}');
        songCache.set(song.songId, song);
      }
      else
      {
        trace('    Failed to instantiate scripted song class: ${songCls}');
      }
    }

    //
    // UNSCRIPTED SONGS
    //
    var songIdList:Array<String> = DataAssets.listDataFilesInPath(SONG_DATA_PATH, SONG_DATA_SUFFIX).map(function(songDataPath:String):String {
      return songDataPath.split('/')[0];
    });
    var unscriptedSongIds:Array<String> = songIdList.filter(function(songId:String):Bool {
      return !songCache.exists(songId);
    });
    trace('  Instantiating ${unscriptedSongIds.length} non-scripted songs...');
    for (songId in unscriptedSongIds)
    {
      try
      {
        var song:Song = new Song(songId);
        if (song != null)
        {
          trace('    Loaded song data: ${song.songId}');
          songCache.set(song.songId, song);
        }
      }
      catch (e)
      {
        trace('    An error occurred while loading song data: ${songId}');
        trace(e);
        // Assume error was already logged.
        continue;
      }
    }

    trace('  Successfully loaded ${Lambda.count(songCache)} stages.');
  }

  /**
   * Retrieves a particular song from the cache.
   * @param songId The ID of the song to retrieve.
   * @return The song, or null if it was not found.
   */
  public static function fetchSong(songId:String):Null<Song>
  {
    if (songCache.exists(songId))
    {
      var song:Song = songCache.get(songId);
      trace('Successfully fetch song: ${songId}');

      var event:ScriptEvent = new ScriptEvent(ScriptEvent.CREATE, false);
      ScriptEventDispatcher.callEvent(song, event);
      return song;
    }
    else
    {
      trace('Failed to fetch song, not found in cache: ${songId}');
      return null;
    }
  }

  static function clearSongCache():Void
  {
    if (songCache != null)
    {
      songCache.clear();
    }
  }

  public static function listSongIds():Array<String>
  {
    return songCache.keys().array();
  }

  public static function parseSongMetadata(songId:String):Array<SongMetadata>
  {
    var result:Array<SongMetadata> = [];

    var rawJson:String = loadSongMetadataFile(songId);
    var jsonData:Dynamic = null;
    try
    {
      jsonData = Json.parse(rawJson);
    }
    catch (e) {}

    var songMetadata:SongMetadata = SongMigrator.migrateSongMetadata(jsonData, songId);
    songMetadata = SongValidator.validateSongMetadata(songMetadata, songId);

    if (songMetadata == null)
    {
      return result;
    }

    result.push(songMetadata);

    var variations = songMetadata.playData.songVariations;

    for (variation in variations)
    {
      var variationJsonStr:String = loadSongMetadataFile(songId, variation);
      var variationJsonData:Dynamic = null;
      try
      {
        variationJsonData = Json.parse(variationJsonStr);
      }
      catch (e) {}
      var variationSongMetadata:SongMetadata = SongMigrator.migrateSongMetadata(variationJsonData, '${songId}-${variation}');
      variationSongMetadata = SongValidator.validateSongMetadata(variationSongMetadata, '${songId}-${variation}');
      if (variationSongMetadata != null)
      {
        variationSongMetadata.variation = variation;
        result.push(variationSongMetadata);
      }
    }

    return result;
  }

  static function loadSongMetadataFile(songPath:String, variation:String = ''):String
  {
    var songMetadataFilePath:String = (variation != '') ? Paths.json('$SONG_DATA_PATH$songPath/$songPath-metadata-$variation') : Paths.json('$SONG_DATA_PATH$songPath/$songPath-metadata');

    var rawJson:String = Assets.getText(songMetadataFilePath).trim();

    while (!rawJson.endsWith("}"))
    {
      rawJson = rawJson.substr(0, rawJson.length - 1);
    }

    return rawJson;
  }

  public static function parseMusicMetadata(musicId:String):SongMetadata
  {
    var rawJson:String = loadMusicMetadataFile(musicId);
    var jsonData:Dynamic = null;
    try
    {
      jsonData = Json.parse(rawJson);
    }
    catch (e) {}

    var musicMetadata:SongMetadata = SongMigrator.migrateSongMetadata(jsonData, musicId);
    musicMetadata = SongValidator.validateSongMetadata(musicMetadata, musicId);

    return musicMetadata;
  }

  static function loadMusicMetadataFile(musicPath:String, variation:String = ''):String
  {
    var musicMetadataFilePath:String = (variation != '') ? Paths.file('$MUSIC_DATA_PATH$musicPath/$musicPath-metadata-$variation.json') : Paths.file('$MUSIC_DATA_PATH$musicPath/$musicPath-metadata.json');

    var rawJson:String = Assets.getText(musicMetadataFilePath).trim();

    while (!rawJson.endsWith("}"))
    {
      rawJson = rawJson.substr(0, rawJson.length - 1);
    }

    return rawJson;
  }

  public static function parseSongChartData(songId:String, variation:String = ""):SongChartData
  {
    var rawJson:String = loadSongChartDataFile(songId, variation);
    var jsonData:Dynamic = null;
    try
    {
      jsonData = Json.parse(rawJson);
    }
    catch (e) {}

    var songChartData:SongChartData = SongMigrator.migrateSongChartData(jsonData, songId);
    songChartData = SongValidator.validateSongChartData(songChartData, songId);

    if (songChartData == null)
    {
      trace('Failed to validate song chart data: ${songId}');
      return null;
    }

    return songChartData;
  }

  static function loadSongChartDataFile(songPath:String, variation:String = ''):String
  {
    var songChartDataFilePath:String = (variation != '') ? Paths.json('$SONG_DATA_PATH$songPath/$songPath-chart-$variation') : Paths.json('$SONG_DATA_PATH$songPath/$songPath-chart');

    var rawJson:String = Assets.getText(songChartDataFilePath).trim();

    while (!rawJson.endsWith("}"))
    {
      rawJson = rawJson.substr(0, rawJson.length - 1);
    }

    return rawJson;
  }
}

typedef RawSongMetadata =
{
  /**
   * A semantic versioning string for the song data format.
   *
   */
  var version:Version;

  var songName:String;
  var artist:String;
  var timeFormat:SongTimeFormat;
  var divisions:Int;
  var timeChanges:Array<SongTimeChange>;
  var looped:Bool;
  var playData:SongPlayData;
  var generatedBy:String;

  /**
   * Defaults to `default` or `''`. Populated later.
   */
  var variation:String;
};

@:forward
abstract SongMetadata(RawSongMetadata)
{
  public function new(songName:String, artist:String, variation:String = 'default')
  {
    this =
      {
        version: SongMigrator.CHART_VERSION,
        songName: songName,
        artist: artist,
        timeFormat: 'ms',
        divisions: 96,
        timeChanges: [new SongTimeChange(-1, 0, 100, 4, 4, [4, 4, 4, 4])],
        looped: false,
        playData:
          {
            songVariations: [],
            difficulties: ['normal'],

            playableChars:
              {
                bf: new SongPlayableChar('gf', 'dad'),
              },

            stage: 'mainStage',
            noteSkin: 'Normal'
          },
        generatedBy: SongValidator.DEFAULT_GENERATEDBY,

        // Variation ID.
        variation: variation
      };
  }

  public function clone(?newVariation:String = null):SongMetadata
  {
    var result = new SongMetadata(this.songName, this.artist, newVariation == null ? this.variation : newVariation);
    result.version = this.version;
    result.timeFormat = this.timeFormat;
    result.divisions = this.divisions;
    result.timeChanges = this.timeChanges;
    result.looped = this.looped;
    result.playData = this.playData;
    result.generatedBy = this.generatedBy;

    return result;
  }
}

typedef SongPlayData =
{
  var songVariations:Array<String>;
  var difficulties:Array<String>;

  /**
   * Keys are the player characters and the values give info on what opponent/GF/inst to use.
   */
  var playableChars:DynamicAccess<SongPlayableChar>;

  var stage:String;
  var noteSkin:String;
}

typedef RawSongPlayableChar =
{
  var g:String;
  var o:String;
  var i:String;
}

typedef RawSongNoteData =
{
  /**
   * The timestamp of the note. The timestamp is in the format of the song's time format.
   */
  var t:Float;

  /**
   * Data for the note. Represents the index on the strumline.
   * 0 = left, 1 = down, 2 = up, 3 = right
   * `floor(direction / strumlineSize)` specifies which strumline the note is on.
   * 0 = player, 1 = opponent, etc.
   */
  var d:Int;

  /**
   * Length of the note, if applicable.
   * Defaults to 0 for single notes.
   */
  var l:Float;

  /**
   * The kind of the note.
   * This can allow the note to include information used for custom behavior.
   * Defaults to blank or `"normal"`.
   */
  var k:String;
}

abstract SongNoteData(RawSongNoteData)
{
  public function new(time:Float, data:Int, length:Float = 0, kind:String = '')
  {
    this =
      {
        t: time,
        d: data,
        l: length,
        k: kind
      };
  }

  /**
   * The timestamp of the note, in milliseconds.
   */
  public var time(get, set):Float;

  public function get_time():Float
  {
    return this.t;
  }

  public function set_time(value:Float):Float
  {
    return this.t = value;
  }

  /**
   * The timestamp of the note, in steps.
   */
  public var stepTime(get, never):Float;

  public function get_stepTime():Float
  {
    return Conductor.getTimeInSteps(abstract.time);
  }

  /**
   * The raw data for the note.
   */
  public var data(get, set):Int;

  public function get_data():Int
  {
    return this.d;
  }

  public function set_data(value:Int):Int
  {
    return this.d = value;
  }

  /**
   * The direction of the note, if applicable.
   * Strips the strumline index from the data.
   *
   * 0 = left, 1 = down, 2 = up, 3 = right
   */
  public inline function getDirection(strumlineSize:Int = 4):Int
  {
    return abstract.data % strumlineSize;
  }

  public function getDirectionName(strumlineSize:Int = 4):String
  {
    switch (abstract.data % strumlineSize)
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
    return Math.floor(abstract.data / strumlineSize);
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
   * If this is a hold note, this is the length of the hold note in milliseconds.
   * @default 0 (not a hold note)
   */
  public var length(get, set):Float;

  function get_length():Float
  {
    return this.l;
  }

  function set_length(value:Float):Float
  {
    return this.l = value;
  }

  /**
   * If this is a hold note, this is the length of the hold note in steps.
   * @default 0 (not a hold note)
   */
  public var stepLength(get, set):Float;

  function get_stepLength():Float
  {
    return Conductor.getTimeInSteps(abstract.time + abstract.length) - abstract.stepTime;
  }

  function set_stepLength(value:Float):Float
  {
    return abstract.length = Conductor.getStepTimeInMs(value) - abstract.time;
  }

  public var isHoldNote(get, never):Bool;

  public function get_isHoldNote():Bool
  {
    return this.l > 0;
  }

  public var kind(get, set):String;

  function get_kind():String
  {
    if (this.k == null || this.k == '') return 'normal';

    return this.k;
  }

  public function set_kind(value:String):String
  {
    if (value == 'normal' || value == '') value = null;
    return this.k = value;
  }

  @:op(A == B)
  public function op_equals(other:SongNoteData):Bool
  {
    if (abstract.kind == '')
    {
      if (other.kind != '' && other.kind != 'normal') return false;
    }
    else
    {
      if (other.kind == '' || other.kind != abstract.kind) return false;
    }

    return abstract.time == other.time && abstract.data == other.data && abstract.length == other.length;
  }

  @:op(A != B)
  public function op_notEquals(other:SongNoteData):Bool
  {
    if (abstract.kind == '')
    {
      if (other.kind != '' && other.kind != 'normal') return true;
    }
    else
    {
      if (other.kind == '' || other.kind != abstract.kind) return true;
    }

    return abstract.time != other.time || abstract.data != other.data || abstract.length != other.length;
  }

  @:op(A > B)
  public function op_greaterThan(other:SongNoteData):Bool
  {
    return abstract.time > other.time;
  }

  @:op(A < B)
  public function op_lessThan(other:SongNoteData):Bool
  {
    return this.t < other.time;
  }

  @:op(A >= B)
  public function op_greaterThanOrEquals(other:SongNoteData):Bool
  {
    return this.t >= other.time;
  }

  @:op(A <= B)
  public function op_lessThanOrEquals(other:SongNoteData):Bool
  {
    return this.t <= other.time;
  }
}

typedef RawSongEventData =
{
  /**
   * The timestamp of the event. The timestamp is in the format of the song's time format.
   */
  var t:Float;

  /**
   * The kind of the event.
   * Examples include "FocusCamera" and "PlayAnimation"
   * Custom events can be added by scripts with the `ScriptedSongEvent` class.
   */
  var e:String;

  /**
   * The data for the event.
   * This can allow the event to include information used for custom behavior.
   * Data type depends on the event kind. It can be anything that's JSON serializable.
   */
  var v:DynamicAccess<Dynamic>;

  /**
   * Whether this event has been activated.
   * This is only used internally by the game. It should not be serialized.
   */
  @:optional var a:Bool;
}

abstract SongEventData(RawSongEventData)
{
  public function new(time:Float, event:String, value:Dynamic = null)
  {
    this =
      {
        t: time,
        e: event,
        v: value,
        a: false
      };
  }

  public var time(get, set):Float;

  public function get_time():Float
  {
    return this.t;
  }

  public function set_time(value:Float):Float
  {
    return this.t = value;
  }

  public var stepTime(get, never):Float;

  public function get_stepTime():Float
  {
    return Conductor.getTimeInSteps(abstract.time);
  }

  public var event(get, set):String;

  public function get_event():String
  {
    return this.e;
  }

  public function set_event(value:String):String
  {
    return this.e = value;
  }

  public var value(get, set):Dynamic;

  public function get_value():Dynamic
  {
    return this.v;
  }

  public function set_value(value:Dynamic):Dynamic
  {
    return this.v = value;
  }

  public var activated(get, set):Bool;

  public function get_activated():Bool
  {
    return this.a;
  }

  public function set_activated(value:Bool):Bool
  {
    return this.a = value;
  }

  public inline function getDynamic(key:String):Null<Dynamic>
  {
    return this.v.get(key);
  }

  public inline function getBool(key:String):Null<Bool>
  {
    return cast this.v.get(key);
  }

  public inline function getInt(key:String):Null<Int>
  {
    return cast this.v.get(key);
  }

  public inline function getFloat(key:String):Null<Float>
  {
    return cast this.v.get(key);
  }

  public inline function getString(key:String):String
  {
    return cast this.v.get(key);
  }

  public inline function getArray(key:String):Array<Dynamic>
  {
    return cast this.v.get(key);
  }

  public inline function getBoolArray(key:String):Array<Bool>
  {
    return cast this.v.get(key);
  }

  @:op(A == B)
  public function op_equals(other:SongEventData):Bool
  {
    return this.t == other.time && this.e == other.event && this.v == other.value;
  }

  @:op(A != B)
  public function op_notEquals(other:SongEventData):Bool
  {
    return this.t != other.time || this.e != other.event || this.v != other.value;
  }

  @:op(A > B)
  public function op_greaterThan(other:SongEventData):Bool
  {
    return this.t > other.time;
  }

  @:op(A < B)
  public function op_lessThan(other:SongEventData):Bool
  {
    return this.t < other.time;
  }

  @:op(A >= B)
  public function op_greaterThanOrEquals(other:SongEventData):Bool
  {
    return this.t >= other.time;
  }

  @:op(A <= B)
  public function op_lessThanOrEquals(other:SongEventData):Bool
  {
    return this.t <= other.time;
  }
}

abstract SongPlayableChar(RawSongPlayableChar)
{
  public function new(girlfriend:String, opponent:String, inst:String = "")
  {
    this =
      {
        g: girlfriend,
        o: opponent,
        i: inst
      };
  }

  public var girlfriend(get, set):String;

  public function get_girlfriend():String
  {
    return this.g;
  }

  public function set_girlfriend(value:String):String
  {
    return this.g = value;
  }

  public var opponent(get, set):String;

  public function get_opponent():String
  {
    return this.o;
  }

  public function set_opponent(value:String):String
  {
    return this.o = value;
  }

  public var inst(get, set):String;

  public function get_inst():String
  {
    return this.i;
  }

  public function set_inst(value:String):String
  {
    return this.i = value;
  }
}

typedef RawSongChartData =
{
  var version:Version;

  var scrollSpeed:DynamicAccess<Float>;
  var events:Array<SongEventData>;
  var notes:DynamicAccess<Array<SongNoteData>>;
  var generatedBy:String;
};

@:forward
abstract SongChartData(RawSongChartData)
{
  public function new(scrollSpeed:Float, events:Array<SongEventData>, notes:Array<SongNoteData>)
  {
    this =
      {
        version: SongMigrator.CHART_VERSION,

        events: events,
        notes:
          {
            normal: notes
          },
        scrollSpeed:
          {
            normal: scrollSpeed
          },
        generatedBy: SongValidator.DEFAULT_GENERATEDBY
      }
  }

  public function getScrollSpeed(diff:String = 'default'):Float
  {
    var result:Float = this.scrollSpeed.get(diff);

    if (result == 0.0 && diff != 'default') return getScrollSpeed('default');

    return (result == 0.0) ? 1.0 : result;
  }
}

typedef RawSongTimeChange =
{
  /**
   * Timestamp in specified `timeFormat`.
   */
  var t:Float;

  /**
   * Time in beats (int). The game will calculate further beat values based on this one,
   * so it can do it in a simple linear fashion.
   */
  var b:Null<Float>;

  /**
   * Quarter notes per minute (float). Cannot be empty in the first element of the list,
   * but otherwise it's optional, and defaults to the value of the previous element.
   */
  var bpm:Float;

  /**
   * Time signature numerator (int). Optional, defaults to 4.
   */
  var n:Int;

  /**
   * Time signature denominator (int). Optional, defaults to 4. Should only ever be a power of two.
   */
  var d:Int;

  /**
   * Beat tuplets (Array<int> or int). This defines how many steps each beat is divided into.
   * It can either be an array of length `n` (see above) or a single integer number.
   * Optional, defaults to `[4]`.
   */
  var bt:OneOfTwo<Int, Array<Int>>;
}

/**
 * Add aliases to the minimalized property names of the typedef,
 * to improve readability.
 */
abstract SongTimeChange(RawSongTimeChange) from RawSongTimeChange
{
  public function new(timeStamp:Float, beatTime:Null<Float>, bpm:Float, timeSignatureNum:Int = 4, timeSignatureDen:Int = 4, beatTuplets:Array<Int>)
  {
    this =
      {
        t: timeStamp,
        b: beatTime,
        bpm: bpm,
        n: timeSignatureNum,
        d: timeSignatureDen,
        bt: beatTuplets,
      }
  }

  public var timeStamp(get, set):Float;

  public function get_timeStamp():Float
  {
    return this.t;
  }

  public function set_timeStamp(value:Float):Float
  {
    return this.t = value;
  }

  public var beatTime(get, set):Null<Float>;

  public function get_beatTime():Null<Float>
  {
    return this.b;
  }

  public function set_beatTime(value:Null<Float>):Null<Float>
  {
    return this.b = value;
  }

  public var bpm(get, set):Float;

  public function get_bpm():Float
  {
    return this.bpm;
  }

  public function set_bpm(value:Float):Float
  {
    return this.bpm = value;
  }

  public var timeSignatureNum(get, set):Int;

  public function get_timeSignatureNum():Int
  {
    return this.n;
  }

  public function set_timeSignatureNum(value:Int):Int
  {
    return this.n = value;
  }

  public var timeSignatureDen(get, set):Int;

  public function get_timeSignatureDen():Int
  {
    return this.d;
  }

  public function set_timeSignatureDen(value:Int):Int
  {
    return this.d = value;
  }

  public var beatTuplets(get, set):Array<Int>;

  public function get_beatTuplets():Array<Int>
  {
    if (Std.isOfType(this.bt, Int))
    {
      return [this.bt];
    }
    else
    {
      return this.bt;
    }
  }

  public function set_beatTuplets(value:Array<Int>):Array<Int>
  {
    return this.bt = value;
  }
}

enum abstract SongTimeFormat(String) from String to String
{
  var TICKS = "ticks";
  var FLOAT = "float";
  var MILLISECONDS = "ms";
}
