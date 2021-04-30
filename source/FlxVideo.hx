package;

// pi
import openfl.media.Video;
import openfl.net.NetConnection;
import flixel.FlxG;
import flixel.FlxBasic;
import openfl.net.NetStream;
// this is truly and wholely decompiled from js
class FlxVideo extends FlxBasic {
    public var video:Video;
    public var netStream:NetStream;
    public var finishCallback:Void->Void;
    public function new(a:String) {
        super();
        video = new Video();
        video.x = 0;
        video.y = 0;
        FlxG.addChildBelowMouse(video);
        var b = new NetConnection();
        b.connect(null);
        netStream = new NetStream(b);
        netStream.client = {onMetaData: client_onMetaData};
        b.addEventListener("netStatus", netConnection_onNetStatus);
        netStream.play(a);
    }
    function client_onMetaData(a) {
        video.attachNetStream(netStream);
        video.width = FlxG.width;
        video.height = FlxG.height;
    }
    function netConnection_onNetStatus(a) {
        if (a.info.code == "NetStream.Play.Complete") {
            finishVideo();
        }
    }
    function finishVideo() {
        netStream.dispose();
        if (FlxG.game.contains(video)) {
            FlxG.game.removeChild(video);
        }
        if (finishCallback != null) {
            finishCallback();
        }
    }
}