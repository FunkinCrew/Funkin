package funkin;

import flixel.FlxObject;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.PlayState;
import funkin.play.character.BaseCharacter;
import funkin.ui.PreferencesMenu;

using StringTools;

/**
 * A substate which renders over the PlayState when the player dies.
 * Displays the player death animation, plays the music, and handles restarting the song.
 * 
 * The newest implementation uses a substate, which prevents having to reload the song and stage each reset.
 */
class GameOverSubstate extends MusicBeatSubstate
{
	/**
	 * The boyfriend character.
	 */
	var boyfriend:BaseCharacter;

	/**
	 * The invisible object in the scene which the camera focuses on.
	 */
	var cameraFollowPoint:FlxObject;

	/**
	 * The music playing in the background of the state.
	 */
	var gameOverMusic:FlxSound = new FlxSound();

	/**
	 * Whether the player has confirmed and prepared to restart the level.
	 * This means the animation and transition have already started.
	 */
	var isEnding:Bool = false;

	/**
	 * Music variant to use.
	 * TODO: De-hardcode this somehow.
	 */
	var musicVariant:String = "";

	public function new()
	{
		super();

		FlxG.sound.list.add(gameOverMusic);
		gameOverMusic.stop();

		Conductor.songPosition = 0;

		playBlueBalledSFX();

		switch (PlayState.instance.currentStageId)
		{
			case 'school' | 'schoolEvil':
				musicVariant = "-pixel";
			default:
				if (PlayState.instance.currentStage.getBoyfriend().characterId == 'pico')
				{
					musicVariant = "Pico";
				}
				else
				{
					musicVariant = "";
				}
		}

		// We have to remove boyfriend from the stage. Then we can add him back at the end.
		boyfriend = PlayState.instance.currentStage.getBoyfriend(true);
		boyfriend.isDead = true;
		boyfriend.playAnimation('firstDeath');
		add(boyfriend);

		cameraFollowPoint = new FlxObject(PlayState.instance.cameraFollowPoint.x, PlayState.instance.cameraFollowPoint.y, 1, 1);
		add(cameraFollowPoint);

		// FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		FlxG.camera.follow(cameraFollowPoint, LOCKON, 0.01);
	}

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
				if (touch.overlaps(boyfriend))
					confirmDeath();
			}
		}

		if (controls.ACCEPT)
		{
			confirmDeath();
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

		// Start panning the camera to BF after 12 frames.
		// TODO: Should this be de-hardcoded?
		if (boyfriend.getCurrentAnimation().startsWith('firstDeath') && boyfriend.animation.curAnim.curFrame == 12)
		{
			cameraFollowPoint.x = boyfriend.getGraphicMidpoint().x;
			cameraFollowPoint.y = boyfriend.getGraphicMidpoint().y;
		}

		if (gameOverMusic.playing)
		{
			Conductor.songPosition = gameOverMusic.time;
		}
		else
		{
			switch (PlayState.storyWeek)
			{
				case 7:
					if (boyfriend.getCurrentAnimation().startsWith('firstDeath') && boyfriend.isAnimationFinished() && !playingJeffQuote)
					{
						playingJeffQuote = true;
						playJeffQuote();

						startDeathMusic(0.2);
					}
				default:
					if (boyfriend.getCurrentAnimation().startsWith('firstDeath') && boyfriend.isAnimationFinished())
					{
						startDeathMusic();
					}
			}
		}

		dispatchEvent(new UpdateScriptEvent(elapsed));
	}

	override function dispatchEvent(event:ScriptEvent)
	{
		super.dispatchEvent(event);

		ScriptEventDispatcher.callEvent(boyfriend, event);
	}

	/**
	 * Starts the death music at the appropriate volume.
	 * @param startingVolume 
	 */
	function startDeathMusic(?startingVolume:Float = 1):Void
	{
		if (!isEnding)
		{
			gameOverMusic.loadEmbedded(Paths.music('gameOver' + musicVariant));
			gameOverMusic.volume = startingVolume;
			gameOverMusic.play();
		}
		else
		{
			gameOverMusic.loadEmbedded(Paths.music('gameOverEnd' + musicVariant));
			gameOverMusic.volume = startingVolume;
			gameOverMusic.play();
		}
	}

	/**
	 * Play the sound effect that occurs when
	 * boyfriend's testicles get utterly annihilated.
	 */
	function playBlueBalledSFX()
	{
		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + musicVariant));
	}

	var playingJeffQuote:Bool = false;

	/**
	 * Week 7-specific hardcoded behavior, to play a custom death quote.
	 * TODO: Make this a module somehow.
	 */
	function playJeffQuote()
	{
		var randomCensor:Array<Int> = [];

		if (PreferencesMenu.getPref('censor-naughty'))
			randomCensor = [1, 3, 8, 13, 17, 21];

		FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, randomCensor)), 1, false, null, true, function()
		{
			// Once the quote ends, fade in the game over music.
			if (!isEnding && gameOverMusic != null)
			{
				gameOverMusic.fadeIn(4, 0.2, 1);
			}
		});
	}

	/**
	 * Do behavior which occurs when you confirm and move to restart the level.
	 */
	function confirmDeath():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			startDeathMusic(); // isEnding changes this function's behavior.

			boyfriend.playAnimation('deathConfirm', true);

			// After the animation finishes...
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				// ...fade out the graphics. Then after that happens...
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					// ...close the GameOverSubstate.
					FlxG.camera.fade(FlxColor.BLACK, 1, true, null, true);
					PlayState.needsReset = true;

					// Readd Boyfriend to the stage.
					boyfriend.isDead = false;
					remove(boyfriend);
					PlayState.instance.currentStage.addCharacter(boyfriend, BF);

					// Close the substate.
					close();
				});
			});
		}
	}
}
