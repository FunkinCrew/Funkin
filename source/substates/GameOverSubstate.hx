package substates;

import lime.utils.Assets;
import game.Replay;
import states.ReplaySelectorState;
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

	public function new(x:Float, y:Float)
	{
		super();

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		if(utilities.Options.getData("quickRestart"))
		{
			#if linc_luajit
			if (PlayState.luaModchart != null)
			{
				PlayState.luaModchart.die();
				PlayState.luaModchart = null;
			}
			#end
			
			PlayState.SONG.speed = PlayState.previousScrollSpeedLmao;
			FlxG.resetState();
		}

		Conductor.songPosition = 0;

		bf = new Boyfriend(x, y, PlayState.boyfriend.deathCharacter, true);
		add(bf);

		camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
		add(camFollow);

		if(FlxG.sound.music.active)
			FlxG.sound.music.stop();

		var soundPath = Paths.sound("deaths/bf-dead/death");

		if(Assets.exists(Paths.sound("deaths/" + bf.curCharacter + "/death")))
			soundPath = Paths.sound("deaths/" + bf.curCharacter + "/death");

		var soundThing = FlxG.sound.play(soundPath);
		soundThing.play();

		Conductor.changeBPM(100);

		bf.playAnim('firstDeath');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxG.camera.followLerp = 0.01 * (60 / Main.display.currentFPS);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();

			#if linc_luajit
			if (PlayState.luaModchart != null)
			{
				PlayState.luaModchart.die();
				PlayState.luaModchart = null;
			}
			#end

			if(PlayState.playingReplay && Replay.getReplayList().length > 0)
			{
				Conductor.offset = utilities.Options.getData("songOffset");

				@:privateAccess
				{
					utilities.Options.setData(PlayState.instance.ogJudgementTimings, "judgementTimings");
					utilities.Options.setData(PlayState.instance.ogGhostTapping, "ghostTapping");
				}

				FlxG.switchState(new ReplaySelectorState());
			}
			else
			{
				if (PlayState.isStoryMode)
					FlxG.switchState(new StoryMenuState());
				else
					FlxG.switchState(new FreeplayState());
			}

			PlayState.playingReplay = false;
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01 * (60 / Main.display.currentFPS));
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		{
			var soundPath = Paths.music("deaths/bf-dead/loop");

			if(Assets.exists(Paths.music("deaths/" + bf.curCharacter + "/loop")))
				soundPath = Paths.music("deaths/" + bf.curCharacter + "/loop");

			FlxG.sound.playMusic(soundPath);
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();

			var soundPath = Paths.music("deaths/bf-dead/retry");

			if(Assets.exists(Paths.music("deaths/" + bf.curCharacter + "/retry")))
				soundPath = Paths.music("deaths/" + bf.curCharacter + "/retry");

			FlxG.sound.play(soundPath);

			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					#if linc_luajit
					if (PlayState.luaModchart != null)
					{
						PlayState.luaModchart.die();
						PlayState.luaModchart = null;
					}
					#end

					PlayState.SONG.speed = PlayState.previousScrollSpeedLmao;

					if(PlayState.playingReplay && Replay.getReplayList().length > 0)
						FlxG.switchState(new ReplaySelectorState());
					else if(PlayState.playingReplay)
					{
						if (PlayState.isStoryMode)
							FlxG.switchState(new StoryMenuState());
						else
							FlxG.switchState(new FreeplayState());
					}
					else
						FlxG.resetState();
		
					PlayState.playingReplay = false;
				});
			});
		}
	}
}
