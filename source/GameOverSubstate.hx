package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.FlxSprite;

class GameOverSubstate extends MusicBeatSubstate
{
	var camFollow:FlxObject;

	var stageSuffix:String = "";

	var txt:FlxText;

	var daStage:String = PlayState.curStage;

	public function new(x:Float, y:Float)
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		txt = new FlxText(0,0,0,"Game Over! Try again?",75);
		txt.color = FlxColor.YELLOW;
		add(txt);
		txt.screenCenter(XY);

		switch(daStage)
		{
			case 'school' | 'schoolEvil':
				stageSuffix = '-pixel';
		}

		Conductor.songPosition = 0;

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();

			if (PlayState.isStoryMode)
				FlxG.switchState(new StoryMenuState());
			else
				FlxG.switchState(new FreeplayState());
		}
	}

	override function beatHit()
	{
		super.beatHit();

		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			txt.text = 'NICE!';
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					LoadingState.loadAndSwitchState(new PlayState());
				});
			});
		}
	}
}
