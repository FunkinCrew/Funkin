// Static class used to parse files into a more game friendly format...
typedef DialogTextInfo = {
    var speaker:String;
    var speakermood:String;
    var boxmood:String;
    var speech:String;
}
class FileParser {
    // The file should already be read when I get it!
    static public function parseDialog(content:String):Array<DialogTextInfo> {
        var arrayText = content.split('\n');
        var textInfo:Array<DialogTextInfo> = [];
        for (text in arrayText) {
            var things = text.split(":");
            var info = {speaker: "", speakermood: "", boxmood:"", speech: ""};
            // HEY! THERE SHOULD BE AT LEAST TWO: THE SPEAKER AND THE SPEECH
            switch (things.length) {
                case 2: 
                    info.speaker = things[0];
                    speakermood = "normal";
                    boxmood = "normal";
                    speech = things[1];
                case 3:
                    info.speaker = things[0];
                    // only a fucking loser would do shit like this
                    // just imitating what sarv engine does:
                    // it allows ommision
                    if (things[1] != "") {
                        info.speakermood = things[1];
                    } else {
                        info.speakermood = "normal";
                    }
                    info.speech = things[2];
                case 4:
                    info.speaker = things[0];
                    if (things[1] != "") {
                        info.speakermood = things[1];
                    } else {
                        info.speakermood = "normal";
                    }
                    if (things[2] != "") {
                        info.boxmood = things[2];
                    } else {
                        info.boxmood = "";
                    }
                    info.speech = things[3];
            } 
            textInfo.push(info);
        }
        return textInfo;
    }
}