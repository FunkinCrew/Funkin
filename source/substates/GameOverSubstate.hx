package substates;

import haxe.Exception;
import game.Character;
import states.FreeplayState;
import states.StoryMenuState;
import game.Conductor;
import states.PlayState;
import game.Boyfriend;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import states.LoadingState;

class GameOverSubstate extends MusicBeatSubstate
{
	var bf:Character;
	var camFollow:FlxObject;

	var stageSuffix:String = "";

	public function new(x:Float, y:Float)
	{
		super();

		FlxG.save.data.deaths += 1;
		FlxG.save.flush();

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		if(!FlxG.save.data.quickRestart)
		{
			if(PlayState.SONG.player1 == "bf-pixel")
				stageSuffix = '-pixel';

			Conductor.songPosition = 0;

			bf = new Boyfriend(x, y, PlayState.boyfriend.deathCharacter, true);
			add(bf);
	
			camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
			add(camFollow);
	
			if(FlxG.sound.music.active)
				FlxG.sound.music.stop();
	
			var soundThing = FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
			soundThing.play();
	
			Conductor.changeBPM(100);
	
			bf.playAnim('firstDeath');
		}
		else
		{
			PlayState.SONG.speed = PlayState.previousScrollSpeedLmao;
			FlxG.resetState();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(!FlxG.save.data.quickRestart)
		{
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

			if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
			{
				FlxG.camera.follow(camFollow, LOCKON, 0.01);
			}

			if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
			{
				FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));
			}

			if (FlxG.sound.music.playing)
			{
				Conductor.songPosition = FlxG.sound.music.time;
			}
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
			FlxG.sound.music.stop();

			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));

			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					PlayState.SONG.speed = PlayState.previousScrollSpeedLmao;
					FlxG.resetState();
				});
			});
		}
	}
}
