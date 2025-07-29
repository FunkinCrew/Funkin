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
  public static var instance:Countdown;

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

  public static function performCountdown(?noteStyleId:String = "funkin"):Bool
  {
    // remove previous countdown
    Countdown.instance?.destroy();

    Countdown.instance = new Countdown(NoteStyleRegistry.instance.fetchEntry(noteStyleId) ?? NoteStyleRegistry.instance.fetchDefault());

    return Countdown.instance.prepareCoundown();
  }

  public static inline function resumeCountdown()
  {
    Countdown.instance?.resume();
  }

  public static inline function pauseCountdown()
  {
    Countdown.instance?.pause();
  }

  public static inline function stopCountdown()
  {
    Countdown.instance?.stop();
  }

  public static inline function resetCountdown()
  {
    Countdown.instance?.resetTimer();
  }

  public static inline function reset()
  {
    Countdown.instance?.destroy();
  }

  var noteStyle:NoteStyle;

  public var soundSuffix:String = '';
  public var graphicSuffix:String = '';

  /**
   * The current step of the countdown.
   */
  public var countdownStep(default, null):CountdownStep = BEFORE;

  /**
   * The currently running countdown. This will be null if there is no countdown running.
   */
  public var countdownTimer:FlxTimer = null;

  public function new(noteStyle:NoteStyle)
  {
    this.noteStyle = noteStyle;
  }

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

  public function resume()
  {
    if (countdownTimer != null && !countdownTimer.finished) countdownTimer.active = true;
  };

  public function pause()
  {
    if (countdownTimer != null && !countdownTimer.finished) countdownTimer.active = false;
  };

  public function skip()
  {
    stop();
    Conductor.instance.update(0);
  };

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

  public function playSound(step:CountdownStep):FunkinSound
  {
    var path = noteStyle.getCountdownSoundPath(step);
    if (path == null) return null;

    return FunkinSound.playOnce(path, Constants.COUNTDOWN_VOLUME, null, null, true);
  }

  private var _graphicOffsets:Array<Float>;

  public function showGraphic(index:CountdownStep):Void
  {
    var countdownSprite = noteStyle.buildCountdownSprite(index);
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

  public function destroy()
  {
    noteStyle = null;
    countdownStep = null;

    countdownTimer?.cancel();
    countdownTimer?.destroy();
    countdownTimer = null;
  }
}
