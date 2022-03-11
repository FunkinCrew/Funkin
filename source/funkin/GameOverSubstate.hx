package funkin;

import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.display.Display;
import funkin.ui.PreferencesMenu;
import funkin.play.PlayState;

class GameOverSubstate extends MusicBeatSubstate
{
	var bf:Boyfriend;
	var camFollow:FlxObject;

	var stageSuffix:String = "";
	var randomGameover:Int = 1;

	var gameOverMusic:FlxSound;

	public function new()
	{
		gameOverMusic = new FlxSound();
		FlxG.sound.list.add(gameOverMusic);

		var daStage = PlayState.instance.currentStageId;
		var daBf:String = '';
		switch (daStage)
		{
			case 'school' | 'schoolEvil':
				stageSuffix = '-pixel';
				daBf = 'bf-pixel-dead';
			default:
				daBf = 'bf';
		}

		var daSong = PlayState.currentSong.song.toLowerCase();

		switch (daSong)
		{
			case 'stress':
				daBf = 'bf-holding-gf-dead';
		}

		super();

		Conductor.songPosition = 0;

		var bfXPos = PlayState.instance.currentStage.getBoyfriend().getScreenPosition().x;
		var bfYPos = PlayState.instance.currentStage.getBoyfriend().getScreenPosition().y;
		bf = new Boyfriend(bfXPos, bfYPos, daBf);
		add(bf);

		camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
		add(camFollow);

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
		// Conductor.changeBPM(100);

		switch (PlayState.currentSong.player1)
		{
			case 'pico':
				stageSuffix = 'Pico';
		}

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));

		// commented out for now
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		bf.playAnim('firstDeath');

		var randomCensor:Array<Int> = [];

		if (PreferencesMenu.getPref('censor-naughty'))
			randomCensor = [1, 3, 8, 13, 17, 21];

		randomGameover = FlxG.random.int(1, 25, randomCensor);
	}

	var playingDeathSound:Bool = false;

	override function update(elapsed:Float)
	{
		// makes the lerp non-dependant on the framerate
		// FlxG.camera.followLerp = CoolUtil.camLerpShit(0.01);

		super.update(elapsed);

		if (FlxG.onMobile)
		{
			var touch = FlxG.touches.getFirst();
			if (touch != null)
			{
				if (touch.overlaps(bf))
					endBullshit();
			}
		}

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			// FlxG.sound.music.stop();
			gameOverMusic.stop();

			if (PlayState.isStoryMode)
				FlxG.switchState(new StoryMenuState());
			else
				FlxG.switchState(new FreeplayState());
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01);
		}

		switch (PlayState.storyWeek)
		{
			case 7:
				if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished && !playingDeathSound)
				{
					playingDeathSound = true;

					bf.startedDeath = true;
					coolStartDeath(0.2);

					FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + randomGameover), 1, false, null, true, function()
					{
						if (!isEnding)
						{
							gameOverMusic.fadeIn(4, 0.2, 1);
						}
						// FlxG.sound.music.fadeIn(4, 0.2, 1);
					});
				}
			default:
				if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
				{
					bf.startedDeath = true;
					coolStartDeath();
				}
		}

		if (gameOverMusic.playing)
		{
			Conductor.songPosition = gameOverMusic.time;
		}
	}

	private function coolStartDeath(?vol:Float = 1):Void
	{
		if (!isEnding)
		{
			gameOverMusic.loadEmbedded(Paths.music('gameOver' + stageSuffix));
			gameOverMusic.volume = vol;
			gameOverMusic.play();
		}
		// FlxG.sound.playMusic();
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			gameOverMusic.stop();
			// FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					FlxG.camera.fade(FlxColor.BLACK, 1, true, null, true);
					PlayState.needsReset = true;
					close();
					// LoadingState.loadAndSwitchState(new PlayState());
				});
			});
		}
	}
}
