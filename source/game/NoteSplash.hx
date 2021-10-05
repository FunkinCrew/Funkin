package game;

import utilities.NoteVariables;
import flixel.FlxG;
import states.PlayState;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite
{
    var target:FlxSprite;

    public function new(x:Float = 0, y:Float = 0, noteData:Int, target:FlxSprite) {
        super(x, y);

        this.target = target;

        alpha = 0.8;
        frames = PlayState.splash_Texture;

        var coolAnimRando:Int = FlxG.random.int(1,2);

        animation.addByPrefix("default", "note splash " + NoteVariables.Other_Note_Anim_Stuff[PlayState.SONG.keyCount - 1][noteData] + " " + coolAnimRando, 24 + FlxG.random.int(-2, 2), false);
        animation.play("default", true);

        setGraphicSize(Std.int(target.width * 2));
        updateHitbox();
    }

    override function update(elapsed:Float) {
        if(animation.curAnim.finished)
        {
            kill();
            alpha = 0;
        }

        x = target.x - (target.width / 2);
        y = target.y - (target.height / 2);

        super.update(elapsed);
    }
}