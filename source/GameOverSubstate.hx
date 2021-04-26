package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.FlxCamera;

using StringTools;

class GameOverSubstate extends MusicBeatSubstate
{
	var bf:Boyfriend;
	var camFollow:FlxObject;

	var stageSuffix:String = "";
	var CharSoundSuffix:String = "";
	var CharMusicSuffix:String = "";
	var perfect:FlxSprite;
	
	/*private var camHUD2:FlxCamera;
	
	camHUD2 = new FlxCamera();
	camHUD2.bgColor.alpha = 0;
	FlxG.cameras.add(camHUD2);*/
		
	public function new(x:Float, y:Float)
	{
		var daPlayer = PlayState.curPlayer;
		var daBf:String = '';
		var Suffix = PlayState.CharacterSuffix;
		switch (daPlayer)
		{
			case 'bf-pico':
				daBf = 'bf-pico';
				CharSoundSuffix = '-pico';
			case 'bf-dylan':
				daBf = 'bf-dylan-dead';
			default:
				daBf = 'bf';
		}
		switch (Suffix)
		{
			case '-pixel':
				daBf = daPlayer + Suffix + '-dead';
				stageSuffix = '-pixel';
			case '-bsides' | '-car-bsides' | '-christmas-bsides':
				stageSuffix = '-bsides';
				daBf += '-bsides';
			case '-pixel-bsides':
				daBf = daPlayer + Suffix + '-dead';
				stageSuffix = '-pixel-bsides';
		}

		super();

		Conductor.songPosition = 0;

		bf = new Boyfriend(x, y, daBf);
		add(bf);

		camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
		add(camFollow);

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + CharSoundSuffix));
		Conductor.changeBPM(100);

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		bf.playAnim('firstDeath');
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
			
			remove(camFollow);
			remove(bf);

			if (PlayState.isStoryMode)
				FlxG.switchState(new StoryMenuState());
			else
				FlxG.switchState(new FreeplayState());
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01);
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		{
			if (!PlayState.perfectMode)
			{
				FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix + CharMusicSuffix));
			}
			else
			{
				if (stageSuffix.startsWith('-pixel'))
				{
					FlxG.sound.playMusic(Paths.music('PerfectFail-pixel'));
				}
				else
				{
					FlxG.sound.playMusic(Paths.music('PerfectFail'));
				}
			}
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
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
			bf.playAnim('deathConfirm', true);
			if (!PlayState.perfectMode)
			{
				FlxG.sound.music.stop();
				FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix + CharMusicSuffix));
			}
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					remove(camFollow);
					remove(bf);
			
					LoadingState.loadAndSwitchState(new PlayState());
				});
			});
		}
	}
}
