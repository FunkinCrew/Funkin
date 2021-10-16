package game;

import haxe.Json;
#if polymod
import polymod.backends.PolymodAssets;
#end

using StringTools;

typedef Cutscene = {
    var type:String;
    var bgFade:Bool;

    /* VIDEO */
    var videoPath:String;
    var videoExt:String;

    /* DIALOGUE */
    var dialogueSections:Array<DialogueSection>;
    var dialogueMusic:String;
    var dialogueSound:String;
}

typedef DialogueSection = {
    var side:String;

    var showOtherPortrait:Bool;

    var leftPortrait:DialogueObject;
    var rightPortrait:DialogueObject;

    var dialogue:DialogueText;

    var box:DialogueObject;

    var has_Hand:Bool;
    var hand_Sprite:DialogueObject;
}

typedef DialogueObject = {
    var sprite:String;

    var x:Float;
    var y:Float;

    var scale:Float;
    var antialiased:Bool;

    // bru
    var animated:Bool;
    var anim_Name:String;
    var fps:Int;
}

typedef DialogueText = {
    var text:String;
    var font:String;
    var sound:String;

    // hex codes lol
    var color:String;
    var shadowColor:String;

    var hasShadow:Bool;
    var shadowOffset:Float;
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