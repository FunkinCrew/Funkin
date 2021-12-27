package ui;

import states.PlayState;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import game.Replay;
import flixel.group.FlxGroup;

class NoteGraph extends FlxGroup
{
    public function new(replay:Replay, ?startX:Float = 0.0, ?startY:Float = 0.0) {
        super();

        var bg = new FlxSprite(startX, startY).makeGraphic(500, 332, FlxColor.BLACK);
        bg.alpha = 0.3;
        add(bg);

        add(new FlxText(startX, startY - 16, 0, "-166ms", 16).setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK));
        add(new FlxText(startX, startY + 332, 0, "166ms", 16).setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK));

        add(new FlxSprite(startX, startY).makeGraphic(500, 4, FlxColor.GRAY));
        add(new FlxSprite(startX, startY + 83).makeGraphic(500, 4, FlxColor.GRAY));
        add(new FlxSprite(startX, startY + 166).makeGraphic(500, 4, FlxColor.GRAY));
        add(new FlxSprite(startX, startY + 249).makeGraphic(500, 4, FlxColor.GRAY));

        for(i in 0...replay.inputs.length)
        {
            var input = replay.inputs[i];

            if(input[2] == 2)
            {
                var dif = input[3];
                var strumTime = input[1];

                var hitDot = new FlxSprite(startX + (500 * (strumTime / FlxG.sound.music.length)), (startY + 166) + (dif / PlayState.songMultiplier));
                hitDot.makeGraphic(6,6,FlxColor.fromRGB(Math.floor(255 * (Math.abs(dif) / 166)), 255, 0));

                add(hitDot);
            }
        }
    }
}