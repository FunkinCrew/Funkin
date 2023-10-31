package funkin;

import funkin.util.Constants;
import flixel.util.FlxSignal;
import flixel.math.FlxMath;
import funkin.play.song.Song.SongDifficulty;
import funkin.data.song.SongData.SongTimeChange;
import funkin.data.song.SongDataUtils;

/**
 * A core class which handles musical timing throughout the game,
 * both in gameplay and in menus.
 */
class Conductor
{
  // onBeatHit is called every quarter note
  // onStepHit is called every sixteenth note
  // 4/4 = 4 beats per measure = 16 steps per measure
  //   120 BPM = 120 quarter notes per minute = 2 onBeatHit per second
  //   120 BPM = 480 sixteenth notes per minute = 8 onStepHit per second
  //   60 BPM = 60 quarter notes per minute = 1 onBeatHit per second
  //   60 BPM = 240 sixteenth notes per minute = 4 onStepHit per second
  // 3/4 = 3 beats per measure = 12 steps per measure
  //   (IDENTICAL TO 4/4 but shorter measure length)
  //   120 BPM = 120 quarter notes per minute = 2 onBeatHit per second
  //   120 BPM = 480 sixteenth notes per minute = 8 onStepHit per second
  //   60 BPM = 60 quarter notes per minute = 1 onBeatHit per second
  //   60 BPM = 240 sixteenth notes per minute = 4 onStepHit per second
  // 7/8 = 3.5 beats per measure = 14 steps per measure

  /**
   * The list of time changes in the song.
   * There should be at least one time change (at the beginning of the song) to define the BPM.
   */
  static var timeChanges:Array<SongTimeChange> = [];

  /**
   * The current time change.
   */
  static var currentTimeChange:SongTimeChange;

  /**
   * The current position in the song in milliseconds.
   * Updated every frame based on the audio position.
   */
  public static var songPosition:Float = 0;

  /**
   * Beats per minute of the current song at the current time.
   */
  public static var bpm(get, never):Float;

  static function get_bpm():Float
  {
    if (bpmOverride != null) return bpmOverride;

    if (currentTimeChange == null) return Constants.DEFAULT_BPM;

    return currentTimeChange.bpm;
  }

  /**
   * The current value set by `forceBPM`.
   * If false, BPM is determined by time changes.
   */
  static var bpmOverride:Null<Float> = null;

  /**
   * Duration of a measure in milliseconds. Calculated based on bpm.
   */
  public static var measureLengthMs(get, never):Float;

  static function get_measureLengthMs():Float
  {
    return beatLengthMs * timeSignatureNumerator;
  }

  /**
   * Duration of a beat (quarter note) in milliseconds. Calculated based on bpm.
   */
  public static var beatLengthMs(get, never):Float;

  static function get_beatLengthMs():Float
  {
    // Tied directly to BPM.
    return ((Constants.SECS_PER_MIN / bpm) * Constants.MS_PER_SEC);
  }

  /**
   * Duration of a step (sixtennth note) in milliseconds. Calculated based on bpm.
   */
  public static var stepLengthMs(get, never):Float;

  static function get_stepLengthMs():Float
  {
    return beatLengthMs / timeSignatureNumerator;
  }

  public static var timeSignatureNumerator(get, never):Int;

  static function get_timeSignatureNumerator():Int
  {
    if (currentTimeChange == null) return Constants.DEFAULT_TIME_SIGNATURE_NUM;

    return currentTimeChange.timeSignatureNum;
  }

  public static var timeSignatureDenominator(get, never):Int;

  static function get_timeSignatureDenominator():Int
  {
    if (currentTimeChange == null) return Constants.DEFAULT_TIME_SIGNATURE_DEN;

    return currentTimeChange.timeSignatureDen;
  }

  /**
   * Current position in the song, in measures.
   */
  public static var currentMeasure(default, null):Int;

  /**
   * Current position in the song, in beats.
   */
  public static var currentBeat(default, null):Int;

  /**
   * Current position in the song, in steps.
   */
  public static var currentStep(default, null):Int;

  /**
   * Current position in the song, in measures and fractions of a measure.
   */
  public static var currentMeasureTime(default, null):Float;

  /**
   * Current position in the song, in beats and fractions of a measure.
   */
  public static var currentBeatTime(default, null):Float;

  /**
   * Current position in the song, in steps and fractions of a step.
   */
  public static var currentStepTime(default, null):Float;

  public static var beatHit(default, null):FlxSignal = new FlxSignal();
  public static var stepHit(default, null):FlxSignal = new FlxSignal();

  public static var lastSongPos:Float;
  public static var visualOffset:Float = 0;
  public static var audioOffset:Float = 0;
  public static var offset:Float = 0;

  public static var beatsPerMeasure(get, never):Float;

  static function get_beatsPerMeasure():Float
  {
    // NOTE: Not always an integer, for example 7/8 is 3.5 beats per measure
    return stepsPerMeasure / Constants.STEPS_PER_BEAT;
  }

  public static var stepsPerMeasure(get, never):Int;

  static function get_stepsPerMeasure():Int
  {
    // TODO: Is this always an integer?
    return Std.int(timeSignatureNumerator / timeSignatureDenominator * Constants.STEPS_PER_BEAT * Constants.STEPS_PER_BEAT);
  }

  function new() {}

  /**
   * Forcibly defines the current BPM of the song.
   * Useful for things like the chart editor that need to manipulate BPM in real time.
   *
   * Set to null to reset to the BPM defined by the timeChanges.
   *
   * WARNING: Avoid this for things like setting the BPM of the title screen music,
   * you should have a metadata file for it instead.
   */
  public static function forceBPM(?bpm:Float = null)
  {
    if (bpm != null)
    {
      trace('[CONDUCTOR] Forcing BPM to ${bpm}');
    }
    else
    {
      // trace('[CONDUCTOR] Resetting BPM to default');
    }

    Conductor.bpmOverride = bpm;
  }

  /**
   * Update the conductor with the current song position.
   * BPM, current step, etc. will be re-calculated based on the song position.
   *
   * @param	songPosition The current position in the song in milliseconds.
   *        Leave blank to use the FlxG.sound.music position.
   */
  public static function update(songPosition:Float = null)
  {
    if (songPosition == null) songPosition = (FlxG.sound.music != null) ? FlxG.sound.music.time + Conductor.offset : 0.0;

    var oldBeat = currentBeat;
    var oldStep = currentStep;

    Conductor.songPosition = songPosition;

    currentTimeChange = timeChanges[0];
    for (i in 0...timeChanges.length)
    {
      if (songPosition >= timeChanges[i].timeStamp) currentTimeChange = timeChanges[i];

      if (songPosition < timeChanges[i].timeStamp) break;
    }

    if (currentTimeChange == null && bpmOverride == null && FlxG.sound.music != null)
    {
      trace('WARNING: Conductor is broken, timeChanges is empty.');
    }
    else if (currentTimeChange != null)
    {
      // roundDecimal prevents representing 8 as 7.9999999
      currentStepTime = FlxMath.roundDecimal((currentTimeChange.beatTime * 4) + (songPosition - currentTimeChange.timeStamp) / stepLengthMs, 6);
      currentBeatTime = currentStepTime / Constants.STEPS_PER_BEAT;
      currentMeasureTime = currentStepTime / stepsPerMeasure;
      currentStep = Math.floor(currentStepTime);
      currentBeat = Math.floor(currentBeatTime);
      currentMeasure = Math.floor(currentMeasureTime);
    }
    else
    {
      // Assume a constant BPM equal to the forced value.
      currentStepTime = FlxMath.roundDecimal((songPosition / stepLengthMs), 4);
      currentBeatTime = currentStepTime / Constants.STEPS_PER_BEAT;
      currentMeasureTime = currentStepTime / stepsPerMeasure;
      currentStep = Math.floor(currentStepTime);
      currentBeat = Math.floor(currentBeatTime);
      currentMeasure = Math.floor(currentMeasureTime);
    }

    // FlxSignals are really cool.
    if (currentStep != oldStep)
    {
      stepHit.dispatch();
    }

    if (currentBeat != oldBeat)
    {
      beatHit.dispatch();
    }
  }

  public static function mapTimeChanges(songTimeChanges:Array<SongTimeChange>)
  {
    timeChanges = [];

    // Sort in place just in case it's out of order.
    SongDataUtils.sortTimeChanges(songTimeChanges);

    for (currentTimeChange in songTimeChanges)
    {
      // TODO: Maybe handle this different?
      // Do we care about BPM at negative timestamps?
      // Without any custom handling, `currentStepTime` becomes non-zero at `songPosition = 0`.
      if (currentTimeChange.timeStamp < 0.0) currentTimeChange.timeStamp = 0.0;

      if (currentTimeChange.beatTime == null)
      {
        if (currentTimeChange.timeStamp <= 0.0)
        {
          currentTimeChange.beatTime = 0.0;
        }
        else
        {
          // Calculate the beat time of this timestamp.
          currentTimeChange.beatTime = 0.0;

          if (currentTimeChange.timeStamp > 0.0 && timeChanges.length > 0)
          {
            var prevTimeChange:SongTimeChange = timeChanges[timeChanges.length - 1];
            currentTimeChange.beatTime = FlxMath.roundDecimal(prevTimeChange.beatTime
              + ((currentTimeChange.timeStamp - prevTimeChange.timeStamp) * prevTimeChange.bpm / Constants.SECS_PER_MIN / Constants.MS_PER_SEC),
              4);
          }
        }
      }

      timeChanges.push(currentTimeChange);
    }

    if (timeChanges.length > 0)
    {
      trace('Done mapping time changes: ${timeChanges}');
    }

    // Update currentStepTime
    Conductor.update(Conductor.songPosition);
  }

  /**
   * Given a time in milliseconds, return a time in steps.
   */
  public static function getTimeInSteps(ms:Float):Float
  {
    if (timeChanges.length == 0)
    {
      // Assume a constant BPM equal to the forced value.
      return Math.floor(ms / stepLengthMs);
    }
    else
    {
      var resultStep:Float = 0;

      var lastTimeChange:SongTimeChange = timeChanges[0];
      for (timeChange in timeChanges)
      {
        if (ms >= timeChange.timeStamp)
        {
          lastTimeChange = timeChange;
          resultStep = lastTimeChange.beatTime * 4;
        }
        else
        {
          // This time change is after the requested time.
          break;
        }
      }

      var lastStepLengthMs:Float = ((Constants.SECS_PER_MIN / lastTimeChange.bpm) * Constants.MS_PER_SEC) / timeSignatureNumerator;
      var resultFractionalStep:Float = (ms - lastTimeChange.timeStamp) / lastStepLengthMs;
      resultStep += resultFractionalStep; // Math.floor();

      return resultStep;
    }
  }

  /**
   * Given a time in steps and fractional steps, return a time in milliseconds.
   */
  public static function getStepTimeInMs(stepTime:Float):Float
  {
    if (timeChanges.length == 0)
    {
      // Assume a constant BPM equal to the forced value.
      return stepTime * stepLengthMs;
    }
    else
    {
      var resultMs:Float = 0;

      var lastTimeChange:SongTimeChange = timeChanges[0];
      for (timeChange in timeChanges)
      {
        if (stepTime >= timeChange.beatTime * 4)
        {
          lastTimeChange = timeChange;
          resultMs = lastTimeChange.timeStamp;
        }
        else
        {
          // This time change is after the requested time.
          break;
        }
      }

      var lastStepLengthMs:Float = ((Constants.SECS_PER_MIN / lastTimeChange.bpm) * Constants.MS_PER_SEC) / timeSignatureNumerator;
      resultMs += (stepTime - lastTimeChange.beatTime * 4) * lastStepLengthMs;

      return resultMs;
    }
  }

  /**
   * Given a time in beats and fractional beats, return a time in milliseconds.
   */
  public static function getBeatTimeInMs(beatTime:Float):Float
  {
    if (timeChanges.length == 0)
    {
      // Assume a constant BPM equal to the forced value.
      return beatTime * stepLengthMs * Constants.STEPS_PER_BEAT;
    }
    else
    {
      var resultMs:Float = 0;

      var lastTimeChange:SongTimeChange = timeChanges[0];
      for (timeChange in timeChanges)
      {
        if (beatTime >= timeChange.beatTime)
        {
          lastTimeChange = timeChange;
          resultMs = lastTimeChange.timeStamp;
        }
        else
        {
          // This time change is after the requested time.
          break;
        }
      }

      var lastStepLengthMs:Float = ((Constants.SECS_PER_MIN / lastTimeChange.bpm) * Constants.MS_PER_SEC) / timeSignatureNumerator;
      resultMs += (beatTime - lastTimeChange.beatTime) * lastStepLengthMs * Constants.STEPS_PER_BEAT;

      return resultMs;
    }
  }

  public static function reset():Void
  {
    beatHit.removeAll();
    stepHit.removeAll();

    mapTimeChanges([]);
    forceBPM(null);
    update(0);
  }
}
