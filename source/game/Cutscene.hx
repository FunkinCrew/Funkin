package game;

import haxe.Json;
#if polymod
import polymod.backends.PolymodAssets;
#end

using StringTools;

typedef Cutscene = {
    var type:String;

    var videoPath:String;
    var videoExt:String;
}

class CutsceneUtil
{
	public static function loadFromJson(jsonPath:String):Cutscene
    {
        var rawJson:String = "";

        #if sys
        rawJson = PolymodAssets.getText(Paths.json("cutscenes/" + jsonPath)).trim();
        #else
        rawJson = Assets.getText(Paths.json("cutscenes/" + jsonPath)).trim();
        #end

        return parseJSONshit(rawJson);
    }

    public static function parseJSONshit(rawJson:String):Cutscene
    {
        var swagShit:Cutscene = cast Json.parse(rawJson);

        return swagShit;
    }
}