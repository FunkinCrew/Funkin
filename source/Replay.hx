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
    public var songNotes:Array<Float>;
	public var noteSpeed:Float;
	public var isDownscroll:Bool;
}

class Replay
{
    public static var version:String = "1.0"; // replay file version

    public var path:String = "";
    public var replay:ReplayJSON;
    public function new(path:String)
    {
        this.path = path;
        replay = {
            songName: "Tutorial", 
            songDiff: 1,
			noteSpeed: 1.5,
			isDownscroll: false,
			songNotes: [],
            replayGameVer: version,
            timestamp: Date.now()
        };
    }

    public static function LoadReplay(path:String):Replay
    {
        var rep:Replay = new Replay(path);

        rep.LoadFromJSON();

        trace('basic replay data:\nSong Name: ' + rep.replay.songName + '\nSong Diff: ' + rep.replay.songDiff + '\nNotes Length: ' + rep.replay.songNotes.length);

        return rep;
    }

    public function SaveReplay(notearray:Array<Float>)
    {
        var json = {
            "songName": PlayState.SONG.song.toLowerCase(),
            "songDiff": PlayState.storyDifficulty,
			"noteSpeed": (FlxG.save.data.scrollSpeed > 1 ? FlxG.save.data.scrollSpeed : PlayState.SONG.speed),
			"isDownscroll": FlxG.save.data.downscroll,
			"songNotes": notearray,
            "timestamp": Date.now(),
            "replayGameVer": version
        };

        var data:String = Json.stringify(json);

        #if sys
        File.saveContent("assets/replays/replay-" + PlayState.SONG.song + "-time" + Date.now().getTime() + ".kadeReplay", data);
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
