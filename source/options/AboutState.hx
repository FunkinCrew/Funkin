package options;

import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import openfl.utils.Assets;

using StringTools;

class AboutState extends MusicBeatState
{
	var bg0:FlxSprite;
	var bg1:FlxSprite;
	var bg2:FlxSprite;
	var bg3:FlxSprite;

	override function create()
	{
		var bgasset = Assets.getBitmapData(Paths.image('bgcredit'));

		bg0 = new FlxSprite(0, 0).loadGraphic(bgasset);
		bg1 = new FlxSprite(0, 0).loadGraphic(bgasset);
		bg2 = new FlxSprite(0, 0).loadGraphic(bgasset);
		bg3 = new FlxSprite(0, 0).loadGraphic(bgasset);

		add(bg0);
		add(bg1);
		add(bg2);
		add(bg3);

		var bgfront:FlxSprite = new FlxSprite().loadGraphic(Paths.image('creditfront'));
		add(bgfront);

		move();
 
		super.create();
	}

	function move(?tween) {
		bg0.x = 0;
		bg0.y = 0;

		bg1.x = -1280;
		bg1.y = 0;

		bg2.x = 0;
		bg2.y = -720;

		bg3.x = -1280;
		bg3.y = -720;

		var duration:Float = 50;

		// bg 1
		FlxTween.num(0, 1280, duration, {onComplete: move}, num -> {
			bg0.x = num;
		});
		FlxTween.num(0, 720, duration, {}, num -> {
			bg0.y = num;
		});

		// bg 2
		FlxTween.num(-1280, 0, duration, {}, num -> {
			bg1.x = num;
		});
		FlxTween.num(0, 720, duration, {}, num -> {
			bg1.y = num;
		});

		// bg 3
		FlxTween.num(0, 1280, duration, {}, num -> {
			bg2.x = num;
		});
		FlxTween.num(-720, 0, duration, {}, num -> {
			bg2.y = num;
		});

		// bg 4  
		FlxTween.num(-1280, 0, duration, {}, num -> {
			bg3.x = num;
		});
		FlxTween.num(-720, 0, duration, {}, num -> {
			bg3.y = num;
		});
	}


	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		#if android
		if (FlxG.android.justReleased.BACK)
		{
			FlxG.switchState(new OptionsMenu());
		}
		#end

	}

}