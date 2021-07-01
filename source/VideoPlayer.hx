package;

import flixel.system.FlxSound;
import flixel.FlxCamera;
import haxe.macro.Expr.Catch;
import openfl.Assets;
import openfl.media.Sound;
import flixel.FlxSprite;
import webm.*;
import utils.Asset2File;
#if sys
import webm.WebmPlayer;
#end
import PlayState;
import flixel.addons.ui.FlxUIState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxPath;

/**-200 -200
    usage:
    var video = new VideoPlayer(0, 0, 'videos/ughintro.webm');
    video.play();
    add(video);

    - Bitstream not supported by this decoder
    maybe use vp8 (idk)
**/

class VideoPlayer extends FlxSprite {
    public var finishCallback:Void->Void=null;

    #if sys
    public var player:WebmPlayer;
    #end

    public var sound:FlxSound;

    public var pathfile:String;

    public function new(x, y, path:String) 
    {
        super(x, y);

        #if sys
        WebmPlayer.SKIP_STEP_LIMIT = 10;

        pathfile = path;

        var path = Asset2File.getPath(Paths.file(path), ".webm");

        var io:WebmIo = new WebmIoFile(path);
        player = new WebmPlayer();
        player.fuck(io);

        player.addEventListener('play', function(e) {
            trace('play!');
        });

        player.addEventListener('end', function(e) {
            if (finishCallback != null)
                finishCallback();
        });

        player.addEventListener('stop', function(e) {
            if (finishCallback != null)
                finishCallback();
        });

        loadGraphic(player.bitmapData); 
        #end

        #if html5
        trace('video is unsupported');
        #end
    }

    public function play() {
        #if sys
        player.play();
        
        sound = FlxG.sound.play(Paths.file(pathfile + '.ogg'));
        #end

        #if html5
        #end
    }

    public function ownCamera() {
        var cam = new FlxCamera();
	    FlxG.cameras.add(cam);
		cam.bgColor.alpha = 0;
		cameras = [cam];
    }

    override public function destroy() {
        #if sys
        player.stop();
        super.destroy();
        #end
    }
}