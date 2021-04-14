package;

import flixel.FlxSprite;
import openfl.display.FPS;

class BPMLogoBumpState extends MusicBeatState
{
    var logo:FlxSprite;
    var fpsCounter:FPS;

    override public function create():Void
    {
        logo = new FlxSprite(-150, -100);
        logo.frames = Paths.getSparrowAtlas('logoBumpin');
        logo.antialiasing = true;
        logo.animation.addByPrefix('bump', 'logo bumpin', 24);
        logo.animation.play('bump');
        logo.scale.x = 1.25;
        logo.scale.y = 1.25;
        logo.updateHitbox();
        logo.screenCenter();

        add(logo);

        Conductor.changeBPM(100);
    }

    override function beatHit()
    {
        super.beatHit();

        logo.animation.play('bump');
    }
}