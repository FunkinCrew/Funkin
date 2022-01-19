package substates;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import game.Highscore;
import ui.Alphabet;
import flixel.FlxG;

class ImportHighscoresSubstate extends MusicBeatSubstate
{
    var yes:Alphabet;
    var no:Alphabet;

    public function new()
    {
        FlxG.mouse.visible = true;
        
        super();

        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        bg.scrollFactor.set();
        add(bg);

        FlxTween.tween(bg, {alpha: 0.5}, 1, {ease: FlxEase.circOut, startDelay: 0});

        var areYouSure = new Alphabet(0,0,"Import Old Highscores?", true);
        areYouSure.screenCenter();
        areYouSure.y -= areYouSure.height * 2;

        yes = new Alphabet(areYouSure.x, areYouSure.y + areYouSure.height,"Yes",true);

        no = new Alphabet(areYouSure.x + areYouSure.width, areYouSure.y + areYouSure.height,"No",true);
        no.x -= no.width;

        add(areYouSure);
        add(yes);
        add(no);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.mouse.overlaps(yes))
            yes.alpha = 1;
        else
            yes.alpha = 0.5;

        if(FlxG.mouse.overlaps(no))
            no.alpha = 1;
        else
            no.alpha = 0.5;

        if(FlxG.mouse.justPressed)
        {
            if(FlxG.mouse.overlaps(yes))
            {
                Highscore.importOldData();
                close();
            }
            else if(FlxG.mouse.overlaps(no))
                close();
        }

        if(controls.BACK)
            close();
    }
}