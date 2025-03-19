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

class Countdown
{
  /**
   * The current step of the countdown.
   */
  public static var countdownStep(default, null):CountdownStep = BEFORE;

  /**
   * Which alternate graphic/sound on countdown to use.
   * This is set via the current notestyle.
   * For example, in Week 6 it is `pixel`.
   */
  public static var soundSuffix:String = '';

  /**
   * Which alternate graphic on countdown to use.
   * You can set this via script.
   * For example, in Week 6 it is `-pixel`.
   */
  public static var graphicSuffix:String = '';

  static var noteStyle:NoteStyle;

  static var fallbackNoteStyle:Null<NoteStyle>;

  /**
   * The currently running countdown. This will be null if there is no countdown running.
   */
  static var countdownTimer:FlxTimer = null;

  /**
   * Performs the countdown.
   * Pauses the song, plays the countdown graphics/sound, and then starts the song.
   * This will automatically stop and restart the countdown if it is already running.
   * @returns `false` if the countdown was cancelled by a script.
   */
  public static function performCountdown():Bool
  {
    countdownStep = BEFORE;
    var cancelled:Bool = propagateCountdownEvent(countdownStep);
    if (cancelled)
    {
      return false;
    }

    // Stop any existing countdown.
    stopCountdown();

    PlayState.instance.isInCountdown = true;
    Conductor.instance.update(PlayState.instance.startTimestamp + Conductor.instance.beatLengthMs * -5);
    // Handle onBeatHit events manually
    // @:privateAccess
    // PlayState.instance.dispatchEvent(new SongTimeScriptEvent(SONG_BEAT_HIT, 0, 0));

    // The timer function gets called based on the beat of the song.
    countdownTimer = new FlxTimer();

    countdownTimer.start(Conductor.instance.beatLengthMs / 1000, function(tmr:FlxTimer) {
      if (PlayState.instance == null)
      {
        tmr.cancel();
        return;
      }

      countdownStep = decrement(countdownStep);

      // onBeatHit events are now properly dispatched by the Conductor even at negative timestamps,
      // so calling this is no longer necessary.
      // PlayState.instance.dispatchEvent(new SongTimeScriptEvent(SONG_BEAT_HIT, 0, 0));

      // Countdown graphic.
      showCountdownGraphic(countdownStep);

      // Countdown sound.
      playCountdownSound(countdownStep);

      // Event handling bullshit.
      var cancelled:Bool = propagateCountdownEvent(countdownStep);

      if (cancelled)
      {
        pauseCountdown();
      }

      if (countdownStep == AFTER)
      {
        stopCountdown();
      }
    }, 5); // Before, 3, 2, 1, GO!, After

    return true;
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
        event = new CountdownScriptEvent(COUNTDOWN_START, index);
      case THREE | TWO | ONE | GO: // I didn't know you could use `|` in a switch/case block!
        event = new CountdownScriptEvent(COUNTDOWN_STEP, index);
      case AFTER:
        event = new CountdownScriptEvent(COUNTDOWN_END, index, false);
      default:
        return true;
    }

    // Modules, stages, characters.
    @:privateAccess
    PlayState.instance.dispatchEvent(event);

    return event.eventCanceled;
  }

  /**
   * Pauses the countdown at the current step. You can start it up again later by calling resumeCountdown().
   *
   * If you want to call this from a module, it's better to use the event system and cancel the onCountdownStep event.
   */
  public static function pauseCountdown():Void
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
  public static function resumeCountdown():Void
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
  public static function stopCountdown():Void
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
  public static function skipCountdown():Void
  {
    stopCountdown();
    // This will trigger PlayState.startSong()
    Conductor.instance.update(0);
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
   * Reset the countdown configuration to the default.
   */
  public static function reset()
  {
    noteStyle = null;
  }

  /**
   * Retrieve the note style data (if we haven't already)
   * @param noteStyleId The id of the note style to fetch. Defaults to the one used by the current PlayState.
   * @param force Fetch the note style from the registry even if we've already fetched it.
   */
  static function fetchNoteStyle(?noteStyleId:String, force:Bool = false):Void
  {
    if (noteStyle != null && !force) return;

    if (noteStyleId == null) noteStyleId = PlayState.instance?.currentChart?.noteStyle;

    noteStyle = NoteStyleRegistry.instance.fetchEntry(noteStyleId);
    if (noteStyle == null) noteStyle = NoteStyleRegistry.instance.fetchDefault();
  }

  /**
   * Retrieves the graphic to use for this step of the countdown.
   */
  public static function showCountdownGraphic(index:CountdownStep):Void
  {
    fetchNoteStyle();

    var countdownSprite = noteStyle.buildCountdownSprite(index);
    if (countdownSprite == null) return;

    var fadeEase = FlxEase.cubeInOut;
    if (noteStyle.isCountdownSpritePixel(index)) fadeEase = EaseUtil.stepped(8);

    // Fade sprite in, then out, then destroy it.
    FlxTween.tween(countdownSprite, {alpha: 0}, Conductor.instance.beatLengthMs / 1000,
      {
        ease: fadeEase,
        onComplete: function(twn:FlxTween) {
          countdownSprite.destroy();
        }
      });

    countdownSprite.cameras = [PlayState.instance.camHUD];
    PlayState.instance.add(countdownSprite);
    countdownSprite.screenCenter();

    var offsets = noteStyle.getCountdownSpriteOffsets(index);
    countdownSprite.x += offsets[0];
    countdownSprite.y += offsets[1];
  }

  /**
   * Retrieves the sound file to use for this step of the countdown.
   */
  public static function playCountdownSound(step:CountdownStep):FunkinSound
  {
    fetchNoteStyle();
    var path = noteStyle.getCountdownSoundPath(step);
    if (path == null) return null;

    return FunkinSound.playOnce(path, Constants.COUNTDOWN_VOLUME, null, null, true);
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
