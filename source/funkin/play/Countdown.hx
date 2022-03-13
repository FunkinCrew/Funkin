package funkin.play;

import funkin.util.Constants;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.input.actions.FlxAction.FlxActionAnalog;
import cpp.abi.Abi;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.module.ModuleHandler;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.CountdownScriptEvent;
import flixel.util.FlxTimer;

using StringTools;

class Countdown
{
	/**
	 * The current step of the countdown.
	 */
	public static var countdownStep(default, null):CountdownStep = BEFORE;

	/**
	 * The currently running countdown. This will be null if there is no countdown running.
	 */
	static var countdownTimer:FlxTimer = null;

	/**
	 * Performs the countdown.
	 * Pauses the song, plays the countdown graphics/sound, and then starts the song.
	 * This will automatically stop and restart the countdown if it is already running.
	 */
	public static function performCountdown(isPixelStyle:Bool):Void
	{
		// Stop any existing countdown.
		stopCountdown();

		PlayState.isInCountdown = true;
		Conductor.songPosition = Conductor.crochet * -5;
		countdownStep = BEFORE;

		var cancelled:Bool = propagateCountdownEvent(countdownStep);
		if (cancelled)
			return;

		// The timer function gets called based on the beat of the song.
		countdownTimer = new FlxTimer();

		countdownTimer.start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			countdownStep = decrement(countdownStep);

			// Play the dance animations manually.
			@:privateAccess
			PlayState.instance.danceOnBeat();

			// Countdown graphic.
			showCountdownGraphic(countdownStep, isPixelStyle);

			// Countdown sound.
			playCountdownSound(countdownStep, isPixelStyle);

			// Event handling bullshit.
			var cancelled:Bool = propagateCountdownEvent(countdownStep);

			if (cancelled)
				pauseCountdown();

			if (countdownStep == AFTER)
			{
				stopCountdown();
			}
		}, 6); // Before, 3, 2, 1, GO!, After
	}

	/**
	 * @return TRUE if the event was cancelled.
	 */
	static function propagateCountdownEvent(index:CountdownStep):Bool
	{
		var event:ScriptEvent;

		switch (index)
		{
			case BEFORE:
				event = new CountdownScriptEvent(ScriptEvent.COUNTDOWN_START, index);
			case THREE | TWO | ONE | GO: // I didn't know you could use `|` in a switch/case block!
				event = new CountdownScriptEvent(ScriptEvent.COUNTDOWN_STEP, index);
			case AFTER:
				event = new CountdownScriptEvent(ScriptEvent.COUNTDOWN_END, index, false);
			default:
				return true;
		}

		// Stage
		ScriptEventDispatcher.callEvent(PlayState.instance.currentStage, event);

		// Modules
		ModuleHandler.callEvent(event);

		return event.eventCanceled;
	}

	/**
	 * Pauses the countdown at the current step. You can start it up again later by calling resumeCountdown().
	 * 
	 * If you want to call this from a module, it's better to use the event system and cancel the onCountdownStep event.
	 */
	public static function pauseCountdown()
	{
		if (countdownTimer != null && !countdownTimer.finished)
		{
			countdownTimer.active = false;
		}
	}

	/**
	 * Resumes the countdown at the current step. Only makes sense if you called pauseCountdown() first.
	 * 
	 * If you want to call this from a module, it's better to use the event system and cancel the onCountdownStep event.
	 */
	public static function resumeCountdown()
	{
		if (countdownTimer != null && !countdownTimer.finished)
		{
			countdownTimer.active = true;
		}
	}

	/**
	 * Stops the countdown at the current step. You will have to restart it again later.
	 * 
	 * If you want to call this from a module, it's better to use the event system and cancel the onCountdownStart event.
	 */
	public static function stopCountdown()
	{
		if (countdownTimer != null)
		{
			countdownTimer.cancel();
			countdownTimer.destroy();
			countdownTimer = null;
		}
	}

	/**
	 * Stops the current countdown, then starts the song for you.
	 */
	public static function skipCountdown()
	{
		stopCountdown();
		// This will trigger PlayState.startSong()
		Conductor.songPosition = 0;
		// PlayState.isInCountdown = false;
	}

	/**
	 * Resets the countdown. Only works if it's already running.
	 */
	public static function resetCountdown()
	{
		if (countdownTimer != null)
		{
			countdownTimer.reset();
		}
	}

	/**
	 * Retrieves the graphic to use for this step of the countdown.
	 * TODO: Make this less dumb. Unhardcode it? Use modules? Use notestyles?
	 * 
	 * This is public so modules can do lol funny shit.
	 */
	public static function showCountdownGraphic(index:CountdownStep, isPixelStyle:Bool):Void
	{
		var spritePath:String = null;

		if (isPixelStyle)
		{
			switch (index)
			{
				case TWO:
					spritePath = 'weeb/pixelUI/ready-pixel';
				case ONE:
					spritePath = 'weeb/pixelUI/set-pixel';
				case GO:
					spritePath = 'weeb/pixelUI/date-pixel';
				default:
					// null
			}
		}
		else
		{
			switch (index)
			{
				case TWO:
					spritePath = 'ready';
				case ONE:
					spritePath = 'set';
				case GO:
					spritePath = 'go';
				default:
					// null
			}
		}

		if (spritePath == null)
			return;

		var countdownSprite:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image(spritePath));
		countdownSprite.scrollFactor.set(0, 0);

		if (isPixelStyle)
			countdownSprite.setGraphicSize(Std.int(countdownSprite.width * Constants.PIXEL_ART_SCALE));

		countdownSprite.updateHitbox();
		countdownSprite.screenCenter();

		// Fade sprite in, then out, then destroy it.
		FlxTween.tween(countdownSprite, {y: countdownSprite.y += 100, alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				countdownSprite.destroy();
			}
		});

		PlayState.instance.add(countdownSprite);
	}

	/**
	 * Retrieves the sound file to use for this step of the countdown.
	 * TODO: Make this less dumb. Unhardcode it? Use modules? Use notestyles?
	 * 
	 * This is public so modules can do lol funny shit.
	 */
	public static function playCountdownSound(index:CountdownStep, isPixelStyle:Bool):Void
	{
		var soundPath:String = null;

		if (isPixelStyle)
		{
			switch (index)
			{
				case THREE:
					soundPath = 'intro3-pixel';
				case TWO:
					soundPath = 'intro2-pixel';
				case ONE:
					soundPath = 'intro1-pixel';
				case GO:
					soundPath = 'introGo-pixel';
				default:
					// null
			}
		}
		else
		{
			switch (index)
			{
				case THREE:
					soundPath = 'intro3';
				case TWO:
					soundPath = 'intro2';
				case ONE:
					soundPath = 'intro1';
				case GO:
					soundPath = 'introGo';
				default:
					// null
			}
		}

		if (soundPath == null)
			return;

		FlxG.sound.play(Paths.sound(soundPath), Constants.COUNTDOWN_VOLUME);
	}

	public static function decrement(step:CountdownStep):CountdownStep
	{
		switch (step)
		{
			case BEFORE:
				return THREE;
			case THREE:
				return TWO;
			case TWO:
				return ONE;
			case ONE:
				return GO;
			case GO:
				return AFTER;

			default:
				return AFTER;
		}
	}
}

/**
 * The countdown step.
 * This can't be an enum abstract because scripts may need it.
 */
enum CountdownStep
{
	BEFORE;
	THREE;
	TWO;
	ONE;
	GO;
	AFTER;
}
