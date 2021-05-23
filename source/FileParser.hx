import flixel.util.FlxColor;
using StringTools;
// Static class used to parse files into a more game friendly format...
typedef DialogTextInfo = {
    var speaker:String;
    var speakermood:String;
    var boxmood:String;
    var speech:String;
}
typedef AdvancedDialogDefines = {
    var backgroundColorR:Int;
    var backgroundColorG:Int;
    var backgroundColorB:Int;
    var backgroundColorA:Int;
    var musicName:String;
    var musicVolume:Int;
    var characterScale:Float;
    var dialogueBox:String;
    var fadeInTime:Float;
    var fadeInLoop:Int;
    var fadeOutTime:Float;
    var fadeOutLoop:Int;
    var bgFIT:Float;
    var bfFIL:Int;
    var textboxSprite:String;
    var acceptSound:String;
}
typedef AdvancedDialogInfo = {
    var dialogue:String;
    var speaker:String;
    var emotion:String;
    var fontname:String;
    var fontscale:Int;
    var musicVolume:Int;
    var shakeAmount:Float;
    var shakeDuration:Int;
    var shakeDelay:Int;
    var flashDuration:Int;
    var flashDelay:Int;
    var writingSpeed:Float;
    var flipSides:Bool;
    var dialogueBox:String;
    var dialogueSound:String;
    var textColor:FlxColor;
    var textShadowColor:FlxColor;
    var portraitColor:FlxColor;
    var skipAfter:Int;
}
typedef AdvancedDialogFile = {
    var defines:AdvancedDialogDefines;
    var info:Array<AdvancedDialogInfo>;
}


class FileParser {
    // The file should already be read when I get it!
    static public function parseDialog(content:String):Array<DialogTextInfo> {
        var arrayText = content.split('\n');
        var textInfo:Array<DialogTextInfo> = [];
        for (text in arrayText) {
            var things = text.split(":");
            var info = {speaker: "", speakermood: "", boxmood:"", speech: ""};
            // HEY! THERE SHOULD BE AT LEAST ThREE: THE FIRST EMTPY STRING, THE SPEAKER AND THE SPEECH
            switch (things.length) {
                case 3: 
                    info.speaker = things[1];
                    info.speakermood = "normal";
                    info.boxmood = "normal";
                    info.speech = things[2];
                case 4:
                    info.speaker = things[1];
                    // only a fucking loser would do shit like this
                    // just imitating what sarv engine does:
                    // it allows ommision
                    if (things[2] != "") {
                        info.speakermood = things[2];
                    } else {
                        info.speakermood = "normal";
                    }
                    info.speech = things[3];
                case 5:
                    info.speaker = things[1];
                    if (things[2] != "") {
                        info.speakermood = things[2];
                    } else {
                        info.speakermood = "normal";
                    }
                    if (things[3] != "") {
                        info.boxmood = things[3];
                    } else {
                        info.boxmood = "normal";
                    }
                    info.speech = things[4];
            } 
            textInfo.push(info);
        }
        return textInfo;
    }
    // I assume it is going to be advanced! And that it is in the format of mic'd up, with no define line!
    
    public static function parseAdvancedDialog(content:String):AdvancedDialogFile {
        var dialogueList = content.split('\n');
        var dialogueFile:AdvancedDialogFile = {defines: {textboxSprite: '', backgroundColorA: 0, backgroundColorB: 0, backgroundColorG: 0, backgroundColorR: 0, acceptSound: '', bfFIL: 0, bgFIT: 0, dialogueBox: '', musicVolume: 0, musicName: '', fadeOutLoop: 0, fadeOutTime: 0, fadeInLoop: 0, fadeInTime: 0, characterScale: 1}, info: []};
		var useDialog = dialogueList.shift();
		var splitData = useDialog.split("[");
		trace(useDialog);
        dialogueFile.defines.backgroundColorA = Std.parseInt(splitData[1]);
        useDialog = useDialog.substr(splitData[1].length + 2).trim();
        splitData = useDialog.split("[");
        dialogueFile.defines.backgroundColorR = Std.parseInt(splitData[1]);
        useDialog = useDialog.substr(splitData[1].length + 2).trim();
        
        splitData = useDialog.split("[");
        dialogueFile.defines.backgroundColorG = Std.parseInt(splitData[1]);
        useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split("[");
        dialogueFile.defines.backgroundColorB = Std.parseInt(splitData[1]);
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split("|");
        dialogueFile.defines.musicName = splitData[1];
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split("*");
        dialogueFile.defines.musicVolume = Std.parseInt(splitData[1]);
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split("=");
        dialogueFile.defines.characterScale = Std.parseFloat(splitData[1]);
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split("#");
        dialogueFile.defines.dialogueBox = splitData[1];
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split("<");
        dialogueFile.defines.fadeInTime = Std.parseFloat(splitData[1]);
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split(">");
        dialogueFile.defines.fadeInLoop = Std.parseInt(splitData[1]);
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split("(");
        dialogueFile.defines.fadeOutTime = Std.parseFloat(splitData[1]);
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split(")");
        dialogueFile.defines.fadeOutLoop = Std.parseInt(splitData[1]);
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split("{");
        dialogueFile.defines.bgFIT = Std.parseFloat(splitData[1]);
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split("}");
        dialogueFile.defines.bfFIL = Std.parseInt(splitData[1]);
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split("`");
        dialogueFile.defines.textboxSprite = splitData[1];
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        splitData = useDialog.split("~");
        dialogueFile.defines.acceptSound = splitData[1];
		useDialog = useDialog.substr(splitData[1].length + 2).trim();

        

        for (dialog in dialogueList) {
            var advancedInfo:AdvancedDialogInfo = {dialogue: "", writingSpeed: 0.0, textShadowColor: FlxColor.WHITE, textColor: FlxColor.WHITE, speaker: "", skipAfter: 0, shakeDuration: 0, shakeDelay: 0, shakeAmount: 0.0, portraitColor: FlxColor.WHITE, musicVolume: 100, fontscale: 32, fontname: "lol", dialogueSound: "", dialogueBox: "", emotion: "", flashDelay: 0, flashDuration: 0, flipSides: false};

            splitData = dialog.split(":");
            advancedInfo.speaker = splitData[1];
            dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split("!");
            advancedInfo.emotion = splitData[1];
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split("[");
            advancedInfo.fontname = splitData[1];
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split("]");
            advancedInfo.fontscale = Std.parseInt(splitData[1]);
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split("*");
            advancedInfo.musicVolume = Std.parseInt(splitData[1]);
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split("=");
            advancedInfo.shakeAmount = Std.parseFloat(splitData[1]);
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split("+");
            advancedInfo.shakeDuration = Std.parseInt(splitData[1]);
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split("-");
            advancedInfo.shakeDelay = Std.parseInt(splitData[1]);
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split("<");
            advancedInfo.flashDuration = Std.parseInt(splitData[1]);
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split(">");
            advancedInfo.flashDelay = Std.parseInt(splitData[1]);
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split(";");
            advancedInfo.writingSpeed = Std.parseFloat(splitData[1]);
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split("|");
            advancedInfo.flipSides = splitData[1] == 'true' ? true : false;
			dialog = dialog.substr(splitData[1].length + 2).trim();
            
            splitData = dialog.split("#");
            advancedInfo.dialogueBox = splitData[1];
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split("^");
            advancedInfo.dialogueSound = splitData[1];
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split("!");
            advancedInfo.textColor = FlxColor.fromString(splitData[1]);
			dialog = dialog.substr(splitData[1].length + 2).trim();

            splitData = dialog.split("?");
            advancedInfo.textShadowColor = FlxColor.fromString(splitData[1]);
			dialog = dialog.substr(splitData[1].length + 2).trim();
            splitData = dialog.split(".");
            advancedInfo.portraitColor = FlxColor.fromString(splitData[1]);
			dialog = dialog.substr(splitData[1].length + 2).trim();
            splitData = dialog.split("~");
            advancedInfo.skipAfter = Std.parseInt(splitData[1]);
			dialog = dialog.substr(splitData[1].length + 2).trim();
            trace(dialog);
            //sussy workaround
            //dialog = dialog.replace("~~","").trim();
            advancedInfo.dialogue = dialog;
            dialogueFile.info.push(advancedInfo);
        }
        return dialogueFile;
    }
}