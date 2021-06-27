package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import fmf.characters.*;
import fmf.songs.*;

class GameOverSubstate extends MusicBeatSubstate
{
	var bf:Character;
	var camFollow:FlxObject;

	var stageSuffix:String = "";

	public function new(x:Float, y:Float)
	{
		var daStage = PlayState.curStage;
		var daBf:String = '';
		

		super();

		Conductor.songPosition = 0;

		bf = new Character(x, y);
		add(bf);
		if (PlayState.songPlayer.songLabel == 'school')
		{
				//okay now create pixel shit bf
				bf.frames = Paths.getSparrowAtlas('characters/bfPixelsDEAD');
				bf.animation.addByPrefix('singUP', "BF Dies pixel", 24, false);
				bf.animation.addByPrefix('firstDeath', "BF Dies pixel", 24, false);
				bf.animation.addByPrefix('deathLoop', "Retry Loop", 24, true);
				bf.animation.addByPrefix('deathConfirm', "RETRY CONFIRM", 24, false);
				bf.animation.play('firstDeath');

				bf.addOffset('firstDeath');
				bf.addOffset('deathLoop', -37);
				bf.addOffset('deathConfirm', -37);
				bf.playAnim('firstDeath');
				// pixel bullshit
				bf.setGraphicSize(Std.int(bf.width * 6));
				bf.updateHitbox();
				bf.antialiasing = false;
				bf.flipX = true;
				stageSuffix = '-pixel';
		}
		else
		{
				//okay now create normal bf
				var tex = Paths.getSparrowAtlas('characters/BoyFriend_Dead_Assets');
				bf.frames = tex;
				bf.animation.addByPrefix('firstDeath', "BF dies", 24, false);
				bf.animation.addByPrefix('deathLoop', "BF Dead Loop", 24, true);
				bf.animation.addByPrefix('deathConfirm', "BF Dead confirm", 24, false);
				bf.flipX = true;

		}



		camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
		add(camFollow);

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
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

			if (PlayState.isStoryMode)
				FlxG.switchState(new StoryMenuState());
			else
				FlxG.switchState(new FreeplayState());
			PlayState.loadRep = false;
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
					LoadingState.loadAndSwitchState(new PlayState());
				});
			});
		}
	}
}
