package substates;

import game.Conductor;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

class SongOffsetMenu extends MusicBeatSubstate
{
    var offset:Float = 0.0;
    var offsetText:FlxText = new FlxText(0,0,0,"Offset: 0\nPress ENTER to round number\n",64).setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

    public function new()
    {
        super();

        offset = utilities.Options.getData("songOffset");
        
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        bg.scrollFactor.set();
        add(bg);

        FlxTween.tween(bg, {alpha: 0.5}, 1, {ease: FlxEase.circOut, startDelay: 0});

        offsetText.text = "Offset: " + offset + "\nPress ENTER to round number\n";
        offsetText.screenCenter();
        add(offsetText);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;

        var left = controls.LEFT;
		var right = controls.RIGHT;

        var accept = controls.ACCEPT;
        var back = controls.BACK;

        if(back)
        {
            utilities.Options.setData(offset, "songOffset");
            Conductor.offset = offset;
            FlxG.state.closeSubState();
        }

        if(left && !FlxG.keys.pressed.SHIFT)
            offset -= 0.1;
        if(right && !FlxG.keys.pressed.SHIFT)
            offset += 0.1;

        if(leftP && FlxG.keys.pressed.SHIFT)
            offset -= 0.1;
        if(rightP && FlxG.keys.pressed.SHIFT)
            offset += 0.1;

        offset = offset * Math.pow(10, 2);
        offset = Math.round(offset) / Math.pow(10, 2);

        if(accept)
            offset = Math.round(offset);

        offsetText.text = "Offset: " + offset + "\nPress ENTER to round number\n";
        offsetText.screenCenter();
    }
}