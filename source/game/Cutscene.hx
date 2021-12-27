package game;

import lime.utils.Assets;
import haxe.Json;

using StringTools;

typedef Cutscene = {
    var type:String;
    var cutsceneAfter:Null<String>;

    /* VIDEO */
    var videoPath:String;
    var videoExt:String;

    /* DIALOGUE */
    var bgFade:Null<Bool>;
    var bgColor:Null<String>;

    var dialogueSections:Array<DialogueSection>;
    var dialogueMusic:String;
    var dialogueBox:String;
    var dialogueBoxSize:Null<Float>;
    var dialogueBoxFlips:Null<Bool>;
}

typedef DialogueSection = {
    var side:String;

    var showOtherPortrait:Bool;

    var leftPortrait:DialogueObject;
    var rightPortrait:DialogueObject;

    var dialogue:DialogueText;

    var box_Anim:Null<String>;
    var box_Open:Null<String>;
    var box_FPS:Null<Int>;
    var open_Box:Null<Bool>;
    var box_Antialiased:Null<Bool>;

    var has_Hand:Bool;
    var hand_Sprite:DialogueObject;
}

typedef DialogueObject = {
    var sprite:String;

    var x:Float;
    var y:Float;

    var scale:Null<Float>;
    var antialiased:Null<Bool>;

    // bru
    var animated:Bool;
    var anim_Name:String;
    var fps:Null<Int>;
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

    var size:Int;
    var box_Offset:Array<Int>;

    var alphabet:Null<Bool>;
    var bold:Null<Bool>;

    var text_Delay:Null<Float>;
}

class CutsceneUtil
{
	public static function loadFromJson(jsonPath:String):Cutscene
    {
        var rawJson:String = "";

        rawJson = Assets.getText(Paths.json("cutscenes/" + jsonPath)).trim();

        return parseJSONshit(rawJson);
    }

    public static function parseJSONshit(rawJson:String):Cutscene
    {
        var swagShit:Cutscene = cast Json.parse(rawJson);

        return swagShit;
    }
}