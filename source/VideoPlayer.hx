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
using StringTools;

class VideoPlayer extends FlxSprite {
    public var finishCallback:Void->Void=null;

    #if sys
    public var player:WebmPlayer;
    #end

    public var sound:FlxSound;
    public var soundMultiplier:Float = 1;
    public var prevSoundMultiplier:Float = 1;
    var videoFrames:Int = 0;
    var doShit:Bool = false;

    public var pathfile:String;

    public function new(path:String, ?x, ?y) 
    {
        super(x, y);

        #if sys
        WebmPlayer.SKIP_STEP_LIMIT = 90;

        pathfile = path;

        var path = Asset2File.getPath(Paths.file(path), ".webm");

        videoFrames = Std.parseInt(Assets.getText(Paths.file(pathfile.replace(".webm", ".txt"))));

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
        sound = FlxG.sound.play(Paths.file(pathfile.replace('.webm', '.ogg'))); 
        sound.time = sound.length * soundMultiplier;
        doShit = true;
        #end

        #if html5
        trace('video is unsupported');
        #end
    }

    public function play() {
        #if sys
            player.play();
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
    override public function update(elapsed:Float) {
        super.update(elapsed);
        /*#if sys
        soundMultiplier = player.renderedCount / videoFrames;
        if (soundMultiplier > 1)
			{
				soundMultiplier = 1;
			}
			if (soundMultiplier < 0)
			{
				soundMultiplier = 0;
			}
        if (soundMultiplier == 0)
			{
				if (prevSoundMultiplier != 0)
				{
					sound.pause();
					sound.time = 0;
				}
			} else {
				if (prevSoundMultiplier == 0)
				{
					sound.resume();
					sound.time = sound.length * soundMultiplier;
				}
			}
            prevSoundMultiplier = soundMultiplier;
            if (doShit)
                {
                    var compareShit:Float = 50;
                    if (sound.time >= (sound.length * soundMultiplier) + compareShit || sound.time <= (sound.length * soundMultiplier) - compareShit)
                        sound.time = sound.length * soundMultiplier;
                }
        #end*/
    }

    override public function destroy() {
        #if sys
        player.stop();
        super.destroy();
        #end
    }
}