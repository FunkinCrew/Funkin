package;

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

/**-200 -200
    usage:
    var video = new VideoPlayer(0, 0, 'videos/ughintro.webm');
    video.play();
    add(video);

    - Bitstream not supported by this decoder
    maybe use vp8 (idk)
**/

class VideoPlayer extends FlxSprite {
    public static var finishCallback:Void->Void=null;

    public var player:WebmPlayer;

    public function new(x, y, path:String) 
    {
        super(x, y);

        if (finishCallback == null)
            finishCallback = ()->{};

        var path = Asset2File.getPath(Paths.file(path), ".webm");

        var io:WebmIo = new WebmIoFile(path);
        player = new WebmPlayer();
        player.fuck(io);

        player.addEventListener('play', function(e) {
            trace('play!');
        });

        player.addEventListener('end', function(e) {
            finishCallback();
        });

        player.addEventListener('stop', function(e) {
            finishCallback();
        });

        loadGraphic(player.bitmapData); 
    }

    public function play() {
        //var sound = Assets.getSound(path + '.ogg');
        player.play();
        /*if (sound != null)
            FlxG.sound.playMusic(sound);*/

        //FlxG.sound.playMusic(Reflect.field(player, "sound"));// not working
    }
}