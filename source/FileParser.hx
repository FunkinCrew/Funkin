// Static class used to parse files into a more game friendly format...
typedef DialogTextInfo = {
    var speaker:String;
    ?var speakermood:String;
    ?var boxmood:String;
    var speech:String;
}
class FileParser {
    // The file should already be read when I get it!
    static public function parseDialog(content:String):Array<DialogTextInfo> {
        var arrayText = content.split('\n');
        var textInfo:Array<DialogTextInfo> = [];
        for (text in arrayText) {
            var things = text.split(":");
            var info = {speaker: things[0], speakermood: things[1], boxmood:things[2], speech: things[3]};
            textInfo.push(info);
        }
        return textInfo;
    }
}