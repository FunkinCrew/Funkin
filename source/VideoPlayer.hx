package;

import flixel.system.FlxSound;
import flixel.FlxCamera;
import haxe.macro.Expr.Catch;
import openfl.Assets;
import openfl.media.Sound;
import flixel.FlxSprite;
import webm.*;
import utils.Asset2File;
import webm.WebmPlayer;
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

    public var player:WebmPlayer;

    public var sound:FlxSound;

    public var pathfile:String;

    public function new(x, y, path:String) 
    {
        super(x, y);

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
    }

    public function play() {
        player.play();
        
        sound = FlxG.sound.play(Paths.file(pathfile + '.ogg'));

        //FlxG.sound.playMusic(Reflect.field(player, "sound"));// not working
    }

    public function ownCamera() {
        var cam = new FlxCamera();
	    FlxG.cameras.add(cam);
		cam.bgColor.alpha = 0;
		cameras = [cam];
    }

    override public function destroy() {
        player.stop();
    }
}