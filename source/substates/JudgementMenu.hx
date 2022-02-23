package substates;

import game.Conductor;
import utilities.Ratings;
import lime.app.Application;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

class JudgementMenu extends MusicBeatSubstate
{
    var judgements:Array<Int> = utilities.Options.getData("judgementTimings");

    var preset:String = "Leather Engine";

    var presets:Array<String> = [];

    var preset_Selected:Int = 0;

    var judgementText:FlxText = new FlxText(0,0,0,"Preset: Leather Engine\nMARVELOUS: 25ms\nSICK: 50ms\nGOOD: 70ms\nBAD: 100ms\n",48).setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

    var selected:Int = 0;

    public function new()
    {
        Ratings.loadPresets();
        presets = Ratings.presets;
        
        super();
        
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        bg.scrollFactor.set();
        add(bg);

        FlxTween.tween(bg, {alpha: 0.5}, 1, {ease: FlxEase.circOut, startDelay: 0});

        update_Text();
        add(judgementText);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;

        var downP = controls.DOWN_P;
		var upP = controls.UP_P;

        var accept = controls.ACCEPT;
        var back = controls.BACK;

        if(back)
        {
            utilities.Options.setData(judgements, "judgementTimings");
            FlxG.state.closeSubState();
        }

        if(downP || upP)
        {
            if(downP)
                selected += 1;
            if(upP)
                selected -= 1;

            if(selected < 0)
                selected = 3;
            if(selected > (utilities.Options.getData("marvelousRatings") ? 4 : 3))
                selected = 0;
        }

        if(leftP || rightP)
        {
            if(selected == 0)
            {
                if(leftP)
                    preset_Selected -= 1;
                if(rightP)
                    preset_Selected += 1;

                if(preset_Selected < 0)
                    preset_Selected = presets.length - 1;
                if(preset_Selected > presets.length - 1)
                    preset_Selected = 0;

                preset = presets[preset_Selected];

                judgements = Ratings.returnPreset(preset);
            }
            else
            {
                var ms_Select = selected - 1;

                if(leftP)
                    judgements[ms_Select] -= 1;
                if(rightP)
                    judgements[ms_Select] += 1;

                if(ms_Select > 0)
                {
                    if(judgements[ms_Select] <= judgements[ms_Select - 1])
                        judgements[ms_Select] = judgements[ms_Select - 1] + 1;
                }
                else
                {
                    if(judgements[ms_Select] < 1)
                        judgements[ms_Select] = 1;
                }

                if(ms_Select < 2)
                {
                    if(judgements[ms_Select] >= judgements[ms_Select + 1])
                        judgements[ms_Select] = judgements[ms_Select + 1] - 1;
                }
                else
                {
                    if(judgements[ms_Select] > Std.int(Conductor.safeZoneOffset))
                        judgements[ms_Select] = Std.int(Conductor.safeZoneOffset);
                }
            }
        }

        update_Text();
    }

    function update_Text()
    {
        judgementText.text = (
            "Preset: " + preset + (selected == 0 ? " <\n" : "\n") +
            (utilities.Options.getData("marvelousRatings") ? "MARVELOUS: " + Std.string(judgements[0]) + "ms" + (selected == 1 ? " <\n" : "\n") : "") +
            "SICK: " + Std.string(judgements[1]) + "ms" + (selected == (utilities.Options.getData("marvelousRatings") ? 2 : 1) ? " <\n" : "\n") +
            "GOOD: " + Std.string(judgements[2]) + "ms" + (selected == (utilities.Options.getData("marvelousRatings") ? 3 : 2) ? " <\n" : "\n") +
            "BAD: " + Std.string(judgements[3]) + "ms" + (selected == (utilities.Options.getData("marvelousRatings") ? 4 : 3) ? " <\n" : "\n") +
            "\n"
        );

        judgementText.screenCenter();
    }
}