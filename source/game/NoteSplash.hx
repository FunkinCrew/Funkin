package game;

import shaders.NoteColors;
import shaders.ColorSwap;
import utilities.NoteVariables;
import flixel.FlxG;
import states.PlayState;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite
{
    var target:FlxSprite;

    public var colorSwap:ColorSwap;

    public function new(x:Float = 0, y:Float = 0, noteData:Int, target:FlxSprite, ?isPlayer:Bool = false) {
        super(x, y);

        this.target = target;

        var localKeyCount = isPlayer ? PlayState.SONG.playerKeyCount : PlayState.SONG.keyCount;

        alpha = 0.8;
        frames = PlayState.instance.splash_Texture;

        animation.addByPrefix("default", "note splash " + NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData] + "0", FlxG.random.int(22, 26), false);
        animation.play("default", true);

        setGraphicSize(Std.int(target.width * 2.5));

        updateHitbox();
        centerOrigin();
        centerOffsets();

        colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		var noteColor = NoteColors.getNoteColor(NoteVariables.Other_Note_Anim_Stuff[localKeyCount - 1][noteData]);

		colorSwap.hue = noteColor[0] / 360;
		colorSwap.saturation = noteColor[1] / 100;
		colorSwap.brightness = noteColor[2] / 100;
    }

    override function update(elapsed:Float)
    {
        if(animation.curAnim.finished)
        {
            kill();
            alpha = 0;
        }
        
        x = target.x - (target.width / 1.5);
        y = target.y - (target.height / 1.5);

        color = target.color;
        
        flipX = target.flipX;
        flipY = target.flipY;

        angle = target.angle;

        super.update(elapsed);
    }
}