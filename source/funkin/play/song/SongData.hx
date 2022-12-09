package funkin.play.song;

import flixel.util.typeLimit.OneOfTwo;
import funkin.play.song.ScriptedSong;
import funkin.util.assets.DataAssets;
import haxe.DynamicAccess;
import haxe.Json;
import openfl.utils.Assets;
import thx.semver.Version;

using StringTools;

/**
 * Contains utilities for loading and parsing stage data.
 */
class SongDataParser
{
	/**
	 * A list containing all the songs available to the game.
	 */
	static final songCache:Map<String, Song> = new Map<String, Song>();

	static final DEFAULT_SONG_ID = 'UNKNOWN';
	static final SONG_DATA_PATH = 'songs/';
	static final SONG_DATA_SUFFIX = '-metadata.json';

	/**
	 * Parses and preloads the game's song metadata and scripts when the game starts.
	 * 
	 * If you want to force song metadata to be reloaded, you can just call this function again.
	 */
	public static function loadSongCache():Void
	{
		clearSongCache();
		trace("[SONGDATA] Loading song cache...");

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
		var songIdList:Array<String> = DataAssets.listDataFilesInPath(SONG_DATA_PATH, SONG_DATA_SUFFIX).map(function(songDataPath:String):String
		{
			return songDataPath.split('/')[0];
		});
		var unscriptedSongIds:Array<String> = songIdList.filter(function(songId:String):Bool
		{
			return !songCache.exists(songId);
		});
		trace('  Instantiating ${unscriptedSongIds.length} non-scripted songs...');
		for (songId in unscriptedSongIds)
		{
			try
			{
				var song = new Song(songId);
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
	 */
	public static function fetchSong(songId:String):Null<Song>
	{
		if (songCache.exists(songId))
		{
			var song:Song = songCache.get(songId);
			trace('[SONGDATA] Successfully fetch song: ${songId}');
			return song;
		}
		else
		{
			trace('[SONGDATA] Failed to fetch song, not found in cache: ${songId}');
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
		return [for (x in songCache.keys()) x];
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
		catch (e)
		{
		}

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
			var variationRawJson:String = loadSongMetadataFile(songId, variation);
			var variationSongMetadata:SongMetadata = SongMigrator.migrateSongMetadata(variationRawJson, '${songId}_${variation}');
			variationSongMetadata = SongValidator.validateSongMetadata(variationSongMetadata, '${songId}_${variation}');
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

	public static function parseSongChartData(songId:String, variation:String = ""):SongChartData
	{
		var rawJson:String = loadSongChartDataFile(songId, variation);
		var jsonData:Dynamic = null;
		try
		{
			jsonData = Json.parse(rawJson);
		}
		catch (e)
		{
		}

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
	var loop:Bool;
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
		this = {
			version: SongMigrator.CHART_VERSION,
			songName: songName,
			artist: artist,
			timeFormat: 'ms',
			divisions: 96,
			timeChanges: [new SongTimeChange(-1, 0, 100, 4, 4, [4, 4, 4, 4])],
			loop: false,
			playData: {
				songVariations: [],
				difficulties: ['normal'],

				playableChars: {
					bf: new SongPlayableChar('gf', 'dad'),
				},

				stage: 'mainStage',
				noteSkin: 'Normal'
			},
			generatedBy: SongValidator.DEFAULT_GENERATEDBY,
			variation: variation
		};
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
	public function new(time:Float, data:Int, length:Float = 0, kind:String = "")
	{
		this = {
			t: time,
			d: data,
			l: length,
			k: kind
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
		// TODO: Account for changes in BPM.
		return this.t / Conductor.stepCrochet;
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
		return this.d % strumlineSize;
	}

	public function getDirectionName(strumlineSize:Int = 4):String
	{
		switch (this.d % strumlineSize)
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
		return Math.floor(this.d / strumlineSize);
	}

	public inline function getMustHitNote(strumlineSize:Int = 4):Bool
	{
		return getStrumlineIndex(strumlineSize) == 0;
	}

	public var length(get, set):Float;

	public function get_length():Float
	{
		return this.l;
	}

	public function set_length(value:Float):Float
	{
		return this.l = value;
	}

	public var kind(get, set):String;

	public function get_kind():String
	{
		if (this.k == null || this.k == '')
			return 'normal';

		return this.k;
	}

	public function set_kind(value:String):String
	{
		if (value == 'normal' || value == '')
			value = null;
		return this.k = value;
	}

	@:op(A == B)
	public function op_equals(other:SongNoteData):Bool
	{
		if (this.k == '')
			if (other.kind != '' && other.kind != 'normal')
				return false;

		return this.t == other.time && this.d == other.data && this.l == other.length;
	}

	@:op(A != B)
	public function op_notEquals(other:SongNoteData):Bool
	{
		return this.t != other.time || this.d != other.data || this.l != other.length || this.k != other.kind;
	}

	@:op(A > B)
	public function op_greaterThan(other:SongNoteData):Bool
	{
		return this.t > other.time;
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
	var v:Dynamic;
}

abstract SongEventData(RawSongEventData)
{
	public function new(time:Float, event:String, value:Dynamic = null)
	{
		this = {
			t: time,
			e: event,
			v: value
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

	public inline function getBool():Bool
	{
		return cast this.v;
	}

	public inline function getInt():Int
	{
		return cast this.v;
	}

	public inline function getFloat():Float
	{
		return cast this.v;
	}

	public inline function getString():String
	{
		return cast this.v;
	}

	public inline function getArray():Array<Dynamic>
	{
		return cast this.v;
	}

	public inline function getBoolArray():Array<Bool>
	{
		return cast this.v;
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
		this = {
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
		this = {
			version: SongMigrator.CHART_VERSION,

			events: events,
			notes: {
				normal: notes
			},
			scrollSpeed: {
				normal: scrollSpeed
			},
			generatedBy: SongValidator.DEFAULT_GENERATEDBY
		}
	}

	public function getScrollSpeed(diff:String = 'default'):Float
	{
		var result:Float = this.scrollSpeed.get(diff);

		if (result == 0.0 && diff != 'default')
			return getScrollSpeed('default');

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
	var b:Int;

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
abstract SongTimeChange(RawSongTimeChange)
{
	public function new(timeStamp:Float, beatTime:Int, bpm:Float, timeSignatureNum:Int = 4, timeSignatureDen:Int = 4, beatTuplets:Array<Int>)
	{
		this = {
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

	public var beatTime(get, set):Int;

	public function get_beatTime():Int
	{
		return this.b;
	}

	public function set_beatTime(value:Int):Int
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
