package funkin.play;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.CountdownScriptEvent;
import flixel.util.FlxTimer;
import funkin.util.EaseUtil;
import funkin.audio.FunkinSound;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;

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

class Countdown implements flixel.util.FlxDestroyUtil.IFlxDestroyable
{
  /**
   * Currently used Countdown in PlayState.
   */
  public static var instance:Countdown;

  /**
   * Helper function:
   * Decrements given countdown step.
   */
  static function decrementStep(step:CountdownStep):CountdownStep
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

  /**
   * Destroys previous and creates new Countdown.
   * Used in PlayState twice!! :steamhappy:
   */
  public static function performCountdown(?noteStyleId:String = "funkin"):Bool
  {
    // remove previous countdown
    Countdown.instance?.destroy();

    Countdown.instance = new Countdown(NoteStyleRegistry.instance.fetchEntry(noteStyleId) ?? NoteStyleRegistry.instance.fetchDefault());

    return Countdown.instance.prepareCoundown();
  }

  /**
   * Static back-compability funtions for static access from PlayState.
   */
  /**
   * Resumes currently used countdown timer.
   */
  public static inline function resumeCountdown()
  {
    Countdown.instance?.resume();
  }

  /**
   * Pauses currently used countdown timer.
   */
  public static inline function pauseCountdown()
  {
    Countdown.instance?.pause();
  }

  /**
   * Stops currently used countdown timer and destroys countdown.
   */
  public static inline function stopCountdown()
  {
    Countdown.instance?.stop();
  }

  /**
   * Resets currently used countdown timer.
   */
  public static inline function resetCountdown()
  {
    Countdown.instance?.resetTimer();
  }

  /**
   * Destroys currently used countdown.
   */
  public static inline function reset()
  {
    Countdown.instance?.destroy();
  }

  /**
   * Current notestyle, used to obtaining
   */
  var noteStyle:NoteStyle;

  /**
   * The current step of the countdown.
   */
  public var countdownStep(default, null):CountdownStep = BEFORE;

  /**
   * The currently running countdown. This will be null if there is no countdown running.
   */
  public var countdownTimer:FlxTimer = null;

  /**
   * Constructor function.
   */
  public function new(noteStyle:NoteStyle)
  {
    this.noteStyle = noteStyle;
  }

  /**
   * Dispatches CountDownScriptEvent through all tied clasees and objects.
   * (Characters, stage and e.t.c.)
   */
  public function propagateCountdownEvent(index:CountdownStep):Bool
  {
    var event:ScriptEvent;

    switch (index)
    {
      case BEFORE:
        event = new CountdownScriptEvent(COUNTDOWN_START, index);
      case THREE | TWO | ONE | GO:
        event = new CountdownScriptEvent(COUNTDOWN_STEP, index);
      case AFTER:
        event = new CountdownScriptEvent(COUNTDOWN_END, index, false);
      default:
        return true;
    }

    @:privateAccess
    PlayState.instance.dispatchEvent(event);

    return event.eventCanceled;
  }

  /**
   * Resumes current countdown.
   */
  public function resume()
  {
    if (countdownTimer != null && !countdownTimer.finished) countdownTimer.active = true;
  };

  /**
   * Pauses current countdown.
   */
  public function pause()
  {
    if (countdownTimer != null && !countdownTimer.finished) countdownTimer.active = false;
  };

  /**
   * Skip current countdown.
   */
  public function skip()
  {
    stop();
    Conductor.instance.update(0);
  };

  /**
   * Destroys current countdown.
   */
  public function stop()
  {
    // uhh
    destroy();
  };

  public function resetTimer()
  {
    countdownTimer?.reset();
  }

  public function prepareCoundown()
  {
    countdownStep = BEFORE;
    var cancelled:Bool = propagateCountdownEvent(countdownStep);
    if (cancelled) return false;

    // stop();

    PlayState.instance.isInCountdown = true;
    Conductor.instance.update(PlayState.instance.startTimestamp + Conductor.instance.beatLengthMs * -5);

    countdownTimer = new FlxTimer().start(Conductor.instance.beatLengthMs / 1000, function(tmr:FlxTimer) {
      if (PlayState.instance == null)
      {
        tmr.cancel();
        return;
      }

      countdownStep = decrementStep(countdownStep);

      showGraphic(countdownStep);

      playSound(countdownStep);

      var cancelled:Bool = propagateCountdownEvent(countdownStep);

      if (cancelled) pause();

      if (countdownStep == AFTER) stop();
    }, 5);

    return true;
  }

  /**
   * Retrieves the sound file to use for this step of the countdown.
   */
  public function playSound(step:CountdownStep):FunkinSound
  {
    final path = noteStyle.getCountdownSoundPath(step);
    if (path == null) return null;

    return FunkinSound.playOnce(path, Constants.COUNTDOWN_VOLUME, null, null, true);
  }

  private var _graphicOffsets:Array<Float>;

  /**
   * Retrieves the graphic to use for this step of the countdown.
   */
  public function showGraphic(index:CountdownStep):Void
  {
    final countdownSprite = noteStyle.buildCountdownSprite(index);
    if (countdownSprite == null) return;

    var fadeEase = FlxEase.cubeInOut;
    if (noteStyle.isCountdownSpritePixel(index)) fadeEase = EaseUtil.stepped(8);

    FlxTween.tween(countdownSprite, {alpha: 0}, Conductor.instance.beatLengthMs / 1000,
      {
        ease: fadeEase,
        onComplete: (twn:FlxTween) -> countdownSprite.destroy()
      });

    countdownSprite.camera = PlayState.instance.camHUD;
    PlayState.instance.add(countdownSprite);
    countdownSprite.screenCenter();

    _graphicOffsets = noteStyle.getCountdownSpriteOffsets(index);
    countdownSprite.x += _graphicOffsets[0];
    countdownSprite.y += _graphicOffsets[1];
  }

  /**
   * Destroys some values from this countdown.
   */
  public function destroy()
  {
    noteStyle = null;
    countdownStep = null;

    countdownTimer?.cancel();
    countdownTimer?.destroy();
    countdownTimer = null;
  }
}
