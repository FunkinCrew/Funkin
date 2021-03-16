package;

import flixel.FlxG;
import haxe.display.Display.Package;
import flixel.FlxSprite;

class TankmenBG extends FlxSprite
{

    public var strumTime:Float = 0;
    public var goingRight:Bool = false;

    public function new(x:Float, y:Float)
    {
        super(x, y);

        frames = Paths.getSparrowAtlas('tankmanKilled1');
        antialiasing = true;
        animation.addByPrefix('run', 'tankman running', 24, true);
        animation.addByPrefix('shot', 'John', 24, false);

        animation.play('run');
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var endDirection:Float = FlxG.width * 0.3;

        if (goingRight)
            endDirection = FlxG.width * 0.6;

        x = (endDirection - (Conductor.songPosition - strumTime) * 0.45);

        if (animation.curAnim.name == 'run' && animation.curAnim.finished)
        {
            kill();
        }
    }
}