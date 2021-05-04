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

typedef KeyPress =
{
    public var time:Float;
    public var key:String;
}

typedef KeyRelease =
{
    public var time:Float;
    public var key:String;
}

typedef ReplayJSON =
{
    public var replayGameVer:String;
    public var timestamp:Date;
    public var songName:String;
    public var songDiff:Int;
    public var keyPresses:Array<KeyPress>;
    public var keyReleases:Array<KeyRelease>;
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
            keyPresses: [],
            keyReleases: [],
            replayGameVer: version,
            timestamp: Date.now()
        };
    }

    public static function LoadReplay(path:String):Replay
    {
        var rep:Replay = new Replay(path);

        rep.LoadFromJSON();

        trace('basic replay data:\nSong Name: ' + rep.replay.songName + '\nSong Diff: ' + rep.replay.songDiff + '\nKeys Length: ' + rep.replay.keyPresses.length);

        return rep;
    }

    public function SaveReplay()
    {
        var json = {
            "songName": PlayState.SONG.song.toLowerCase(),
            "songDiff": PlayState.storyDifficulty,
            "keyPresses": replay.keyPresses,
            "keyReleases": replay.keyReleases,
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
