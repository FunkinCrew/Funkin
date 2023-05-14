package game.objects;

import flixel.FlxG;
import flixel.FlxSprite;

import game.state.PlayState;

/*
    Pulled a Forever Engine and moved the ratings, combo numbers n stuff into
    a separate class

    - Zyflx
*/

class JudgeSpr
{
    public static function spawnJudgeSpr(rating:String, isPixel:Bool = false)
    {
        var ratingSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(rating));

        ratingSpr.x = FlxG.width * 0.55 - 40;
		if (ratingSpr.x < FlxG.camera.scroll.x)
			ratingSpr.x = FlxG.camera.scroll.x;
		else if (ratingSpr.x > FlxG.camera.scroll.x + FlxG.camera.width - ratingSpr.width)
			ratingSpr.x = FlxG.camera.scroll.x + FlxG.camera.width - ratingSpr.width;

		ratingSpr.y = FlxG.camera.scroll.y + FlxG.camera.height * 0.4 - 60;
		ratingSpr.acceleration.y = 550;
		ratingSpr.velocity.y -= FlxG.random.int(140, 175);
		ratingSpr.velocity.x -= FlxG.random.int(0, 10);

        if (isPixel)
        {
            ratingSpr.setGraphicSize(Std.int(ratingSpr.width * PlayState.daPixelZoom * 0.7));
        }
        else
        {
            ratingSpr.setGraphicSize(Std.int(ratingSpr.width * 0.7));
            ratingSpr.antialiasing = true;
        }
        ratingSpr.updateHitbox();

        return ratingSpr;
    }

    public static function spawnComboNum(path:String, isPixel:Bool = false)
    {
        var comboNum:FlxSprite = new FlxSprite().loadGraphic(Paths.image(path));

        if (isPixel)
        {
            comboNum.setGraphicSize(Std.int(comboNum.width * PlayState.daPixelZoom));
        }
        else
        {
            comboNum.setGraphicSize(Std.int(comboNum.width * 0.5));
        }
        comboNum.updateHitbox();

		comboNum.acceleration.y = FlxG.random.int(200, 300);
		comboNum.velocity.y -= FlxG.random.int(140, 160);
		comboNum.velocity.x = FlxG.random.float(-5, 5);

        return comboNum;
    }

    public static function spawnComboSpr(path:String, isPixel:Bool = false)
    {
        var comboSpr:FlxSprite = new FlxSprite();
        comboSpr.loadGraphic(Paths.image(path));

        comboSpr.y = FlxG.camera.scroll.y + FlxG.camera.height * 0.4 + 80;
		comboSpr.x = FlxG.width * 0.55;
		if (comboSpr.x < FlxG.camera.scroll.x + 194)
			comboSpr.x = FlxG.camera.scroll.x + 194;
		else if (comboSpr.x > FlxG.camera.scroll.x + FlxG.camera.width - comboSpr.width)
			comboSpr.x = FlxG.camera.scroll.x + FlxG.camera.width - comboSpr.width;

		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.velocity.x += FlxG.random.int(1, 10);

        if (isPixel)
        {
            comboSpr.setGraphicSize(Std.int(comboSpr.width * PlayState.daPixelZoom * 0.7));
        }
        else
        {
            comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
            comboSpr.antialiasing = true;
        }
        comboSpr.updateHitbox();

        return comboSpr;
    }
}