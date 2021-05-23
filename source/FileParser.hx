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
    var characterScale:Int;
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
    var textColor:String;
    var textShadowColor:String;
    var portraitColor:String;
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
    /*
    public static function parseAdvancedDialog(content:String):AdvancedDialogFile {
        var dialogueList = content.split('\n');
        var dialogueFile:AdvancedDialogFile = {defines: {}, info: []};
        var splitData = dialogueList[0].split("[");
        dialogueFile.defines.backgroundColorA = Std.parseInt(splitData[1]);
        dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();
        splitData = dialogueList[0].split("[");
        dialogueFile.defines.backgroundColorR = Std.parseInt(splitData[1]);
        dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();
        
        splitData = dialogueList[0].split("[");
        dialogueFile.defines.backgroundColorG = Std.parseInt(splitData[1]);
        dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList[0].split("[");
        dialogueFile.defines.backgroundColorB = Std.parseInt(splitData[1]).trim();
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList[0].split("|");
        dialogueFile.defines.musicName = splitData[1];
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList[0].split("*");
        dialogueFile.defines.musicVolume = Std.parseInt(splitData[1]);
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList[0].split("=");
        dialogueFile.defines.characterScale = Std.parseFloat(splitData[1]);
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList[0].split("#");
        dialogueFile.defines.dialogueBox = splitData[1];
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList[0].split("<");
        dialogueFile.defines.fadeInTime = Std.parseFloat(splitData[1]);
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList[0].split(">");
        dialogueFile.defines.fadeInLoop = Std.parseInt(splitData[1]);
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList[0].split("(");
        dialogueFile.defines.fadeOutTime = Std.parseFloat(splitData[1]);
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList[0].split(")");
        dialogueFile.defines.fadeOutLoop = Std.parseInt(splitData[1]);
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList[0].split("{");
        dialogueFile.defines.bgFIT = Std.parseFloat(splitData[1]);
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList.split("}");
        dialogueFile.defines.bfFIL = Std.parseInt(splitData[1]);
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList.split("`");
        dialogueFile.defines.textboxSprite = splitData[1];
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        splitData = dialogueList.split("~");
        dialogueFile.defines.acceptSound = splitData[1];
		dialogueList[0] = dialogueList[0].substr(splitData[1].length + 2).trim();

        dialogueList.remove(dialogueList[0]);

        for (dialog in )
    }*/
}