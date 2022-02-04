package game;

import flixel.FlxG;
import lime.utils.Assets;
import haxe.Json;
import states.PlayState;

using StringTools;

typedef SwagReplay =
{
	var songMultiplier:Float;

    var song:String;
    var difficulty:String;

    var inputs:Array<Array<Dynamic>>;

    var offset:Float;
    var judgementTimings:Array<Float>;

    var ghostTapping:Bool;

    var antiMash:Null<Bool>;
}

class Replay
{
	public var songMultiplier:Float;

    public var song:String;
    public var difficulty:String;

    public var inputs:Array<Array<Dynamic>>;

    public var offset:Float;
    public var judgementTimings:Array<Float>;

    public var ghostTapping:Bool;

    public var antiMash:Bool;

    public var swag:SwagReplay;

    public function new(?usePlayStateVars:Bool = true)
    {
        if(usePlayStateVars)
        {
            songMultiplier = PlayState.songMultiplier;

            song = PlayState.SONG.song.toLowerCase();
            difficulty = PlayState.storyDifficultyStr.toLowerCase();
        }

        ghostTapping = utilities.Options.getData("ghostTapping");
        offset = Conductor.offset;
        judgementTimings = utilities.Options.getData("judgementTimings");
        antiMash = utilities.Options.getData("antiMash");

        inputs = [];
    }

    public function convertToSwag():SwagReplay
    {
        swag = {
            songMultiplier: this.songMultiplier,
            song: this.song,
            difficulty: this.difficulty,
            inputs: this.inputs,
            offset: this.offset,
            judgementTimings: this.judgementTimings,
            ghostTapping: this.ghostTapping,
            antiMash: this.antiMash
        };

        return swag;
    }

    public function recordInput(key:Int, type:String = "pressed")
    {
        inputs.push([key, Conductor.songPosition, (type == "pressed" ? 0 : 1)]);
    }

    public function recordKeyHit(direction:Int, strumTime:Float, noteDifference:Float)
    {
        inputs.push([direction, strumTime, 2, noteDifference]);
    }

    public static function loadFromJson(replayFile:String):Replay
    {
        trace("Started loading replay " + replayFile);

        var replay = new Replay(false);

		var rawJson:String = "";

        #if sys
        if(Assets.exists(Paths.json(replayFile, "replays")))
        #end
            rawJson = Assets.getText(Paths.json(replayFile, "replays")).trim();
        #if sys
        else
            rawJson = sys.io.File.getContent(Sys.getCwd() + "assets/replays/" + replayFile + ".json").trim();
        #end

        if(rawJson == "")
            return null;

        trace("Loaded Raw JSON!");

        replay.swag = parseJSONshit(rawJson);

        replay.songMultiplier = replay.swag.songMultiplier;

        replay.song = replay.swag.song;
        replay.difficulty = replay.swag.difficulty;

        replay.offset = replay.swag.offset;
        replay.judgementTimings = replay.swag.judgementTimings;

        replay.inputs = replay.swag.inputs;

        if(replay.swag.antiMash != null)
            replay.antiMash = replay.swag.antiMash;

        trace("Converted from swag data!");

        return replay;
    }

    public static function parseJSONshit(rawJson:String):SwagReplay
    {
        return cast Json.parse(rawJson);
    }

    public static function getReplayList():Array<String>
    {
        var replays:Array<String> = [];

        #if sys
        var sysReplays = sys.FileSystem.readDirectory(Sys.getCwd() + "assets/replays/");
        
        if(sysReplays.length > 0)
        {
            for(replayName in sysReplays)
            {
                if(replayName.startsWith("replay-"))
                    replays.push(replayName.split(".json")[0]);
            }
        }

        var modList = modding.ModList.getActiveMods(modding.PolymodHandler.metadataArrays);
        
        if(modList.length > 0)
        {
            for(mod in modList)
            {
                if(sys.FileSystem.exists(Sys.getCwd() + "mods/" + mod + "/replays/"))
                {
                    var modSysReplays = sys.FileSystem.readDirectory(Sys.getCwd() + "mods/" + mod + "/replays/");

                    if(modSysReplays.length > 0)
                    {
                        for(replayName in modSysReplays)
                        {
                            if(replayName.startsWith("replay-"))
                                replays.push(replayName.split(".json")[0]);
                        }
                    }
                }
            }
        }
        #end

        return replays;
    }
}