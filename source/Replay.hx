#if sys
import sys.io.File;
#end
import Controls.Control;
import flixel.FlxG;
import openfl.events.IOErrorEvent;
import openfl.events.Event;
import openfl.net.FileReference;
import lime.utils.Assets;
import haxe.Json;
import flixel.input.keyboard.FlxKey;
import openfl.utils.Dictionary;

typedef ReplayJSON =
{
	public var replayGameVer:String;
	public var timestamp:Date;
	public var songName:String;
	public var songDiff:Int;
	public var songNotes:Array<Dynamic>;
	public var noteSpeed:Float;
	public var isDownscroll:Bool;
	public var sf:Int;
}

class Replay
{
	public static var version:String = "1.2"; // replay file version

	public var path:String = "";
	public var replay:ReplayJSON;
	public function new(path:String)
	{
		this.path = path;
		replay = {
			songName: "No Song Found", 
			songDiff: 1,
			noteSpeed: 1.5,
			isDownscroll: false,
			songNotes: [],
			replayGameVer: version,
			timestamp: Date.now(),
			sf: Conductor.safeFrames
		};
	}

	public static function LoadReplay(path:String):Replay
    {
		var rep:Replay = new Replay(path);

		rep.LoadFromJSON();

		trace('basic replay data:\nSong Name: ' + rep.replay.songName + '\nSong Diff: ' + rep.replay.songDiff);

		return rep;
	}

	public function SaveReplay(notearray:Array<Dynamic>)
	{
		var json = {
			"songName": PlayState.SONG.song,
			"songDiff": PlayState.storyDifficulty,
			"noteSpeed": (FlxG.save.data.scrollSpeed > 1 ? FlxG.save.data.scrollSpeed : PlayState.SONG.speed),
			"isDownscroll": FlxG.save.data.downscroll,
			"songNotes": notearray,
			"timestamp": Date.now(),
			"replayGameVer": version,
			"sf": Conductor.safeFrames
		};

		var data:String = Json.stringify(json);
		
		var time = Date.now().getTime();

		#if sys
		File.saveContent("assets/replays/replay-" + PlayState.SONG.song + "-time" + time + ".kadeReplay", data);

		path = "replay-" + PlayState.SONG.song + "-time" + time + ".kadeReplay"; // for score screen shit

		LoadFromJSON();
		#end
	}

	public function LoadFromJSON()
	{
		#if sys
		trace('loading ' + Sys.getCwd() + 'assets/replays/' + path + ' replay...');
		try
		{
			var repl:ReplayJSON = cast Json.parse(File.getContent(Sys.getCwd() + "assets/replays/" + path));
			replay = repl;
		}
		catch(e)
		{
			trace('failed!\n' + e.message);
		}
		#end
	}

}
