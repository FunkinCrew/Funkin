package funkin;

import funkin.play.song.SongData.SongTimeChange;
import flixel.util.FlxSignal;
import funkin.play.song.Song.SongDifficulty;

typedef BPMChangeEvent =
{
  var stepTime:Int;
  var songTime:Float;
  var bpm:Float;
}

/**
 * A global source of truth for timing information.
 */
class Conductor
{
  public static final PIXELS_PER_MS:Float = 0.45;
  public static final HIT_WINDOW_MS:Float = 160;
  public static final SECONDS_PER_MINUTE:Float = 60;
  public static final MILLIS_PER_SECOND:Float = 1000;
  public static final STEPS_PER_BEAT:Int = 4;

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
   * The current position in the song in milliseconds.
   * Updated every frame based on the audio position.
   */
  public static var songPosition:Float;

  /**
   * Beats per minute of the current song at the current time.
   */
  public static var bpm(get, null):Float;

  static function get_bpm():Float
  {
    if (bpmOverride != null) return bpmOverride;

    if (currentTimeChange == null) return 100;

    return currentTimeChange.bpm;
  }

  static var bpmOverride:Null<Float> = null;

  /**
   * Current position in the song, in whole measures.
   */
  public static var currentMeasure(default, null):Int;

  /**
   * Current position in the song, in whole beats.
  **/
  public static var currentBeat(default, null):Int;

  /**
   * Current position in the song, in whole steps.
   */
  public static var currentStep(default, null):Int;

  /**
   * Current position in the song, in steps and fractions of a step.
   */
  public static var currentStepTime(default, null):Float;

  /**
   * Duration of a measure in milliseconds. Calculated based on bpm.
   */
  public static var measureLengthMs(get, null):Float;

  static function get_measureLengthMs():Float
  {
    return beatLengthMs * timeSignatureNumerator;
  }

  /**
   * Duration of a beat (quarter note) in milliseconds. Calculated based on bpm.
   */
  public static var beatLengthMs(get, null):Float;

  static function get_beatLengthMs():Float
  {
    // Tied directly to BPM.
    return ((SECONDS_PER_MINUTE / bpm) * MILLIS_PER_SECOND);
  }

  /**
   * Duration of a step (sixteenth) in milliseconds. Calculated based on bpm.
   */
  public static var stepLengthMs(get, null):Float;

  static function get_stepLengthMs():Float
  {
    return beatLengthMs / STEPS_PER_BEAT;
  }

  /**
   * The numerator of the current time signature (number of notes in a measure)
   */
  public static var timeSignatureNumerator(get, null):Int;

  static function get_timeSignatureNumerator():Int
  {
    if (currentTimeChange == null) return 4;

    return currentTimeChange.timeSignatureNum;
  }

  /**
   * The numerator of the current time signature (length of notes in a measure)
   */
  public static var timeSignatureDenominator(get, null):Int;

  static function get_timeSignatureDenominator():Int
  {
    if (currentTimeChange == null) return 4;

    return currentTimeChange.timeSignatureDen;
  }

  public static var offset:Float = 0;

  // TODO: What's the difference between visualOffset and audioOffset?
  public static var visualOffset:Float = 0;
  public static var audioOffset:Float = 0;

  //
  // Signals
  //

  /**
   * Signal that is dispatched every measure.
   * At 120 BPM 4/4, this is dispatched every 2 seconds.
   * At 120 BPM 3/4, this is dispatched every 1.5 seconds.
   */
  public static var measureHit(default, null):FlxSignal = new FlxSignal();

  /**
   * Signal that is dispatched every beat.
   * At 120 BPM 4/4, this is dispatched every 0.5 seconds.
   * At 120 BPM 3/4, this is dispatched every 0.5 seconds.
   */
  public static var beatHit(default, null):FlxSignal = new FlxSignal();

  /**
   * Signal that is dispatched when a step is hit.
   * At 120 BPM 4/4, this is dispatched every 0.125 seconds.
   * At 120 BPM 3/4, this is dispatched every 0.125 seconds.
   */
  public static var stepHit(default, null):FlxSignal = new FlxSignal();

  //
  // Internal Variables
  //

  /**
   * The list of time changes in the song.
   * There should be at least one time change (at the beginning of the song) to define the BPM.
   */
  static var timeChanges:Array<SongTimeChange> = [];

  /**
   * The current time change.
   */
  static var currentTimeChange:SongTimeChange;

  public static var lastSongPos:Float;

  /**
   * The number of beats (whole notes) in a measure.
   */
  public static var beatsPerMeasure(get, null):Int;

  static function get_beatsPerMeasure():Int
  {
    return timeSignatureNumerator;
  }

  /**
   * The number of steps (quarter-notes) in a measure.
   */
  public static var stepsPerMeasure(get, null):Int;

  static function get_stepsPerMeasure():Int
  {
    // This is always 4, b
    return timeSignatureNumerator * 4;
  }

  /**
   * Forcibly defines the current BPM of the song.
   * Useful for things like the chart editor that need to manipulate BPM in real time.
   *
   * Set to null to reset to the BPM defined by the timeChanges.
   *
   * WARNING: Avoid this for things like setting the BPM of the title screen music,
   * you should have a metadata file for it instead.
   */
  public static function forceBPM(?bpm:Float = null):Void
  {
    if (bpm != null)
    {
      trace('[CONDUCTOR] Forcing BPM to ' + bpm);
    }
    else
    {
      trace('[CONDUCTOR] Resetting BPM to default');
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
  public static function update(songPosition:Float = null):Void
  {
    if (songPosition == null) songPosition = (FlxG.sound.music != null) ? FlxG.sound.music.time + Conductor.offset : 0.0;

    var oldMeasure:Int = currentMeasure;
    var oldBeat:Int = currentBeat;
    var oldStep:Int = currentStep;

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
      currentStepTime = (currentTimeChange.beatTime * 4) + (songPosition - currentTimeChange.timeStamp) / stepLengthMs;
      currentStep = Math.floor(currentStepTime);
      currentBeat = Math.floor(currentStep / 4);
    }
    else
    {
      // Assume a constant BPM equal to the forced value.
      currentStepTime = (songPosition / stepLengthMs);
      currentStep = Math.floor(currentStepTime);
      currentBeat = Math.floor(currentStep / 4);
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

    if (currentMeasure != oldMeasure)
    {
      measureHit.dispatch();
    }
  }

  public static function mapTimeChanges(songTimeChanges:Array<SongTimeChange>):Void
  {
    timeChanges = [];

    for (currentTimeChange in songTimeChanges)
    {
      timeChanges.push(currentTimeChange);
    }

    trace('Done mapping time changes: ' + timeChanges);

    // Done.
  }

  /**
   * Given a time in milliseconds, return a time in steps.
   */
  public static function getTimeInSteps(ms:Float):Int
  {
    if (timeChanges.length == 0)
    {
      // Assume a constant BPM equal to the forced value.
      return Math.floor(ms / stepLengthMs);
    }
    else
    {
      var resultStep:Int = 0;

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

      resultStep += Math.floor((ms - lastTimeChange.timeStamp) / stepLengthMs);

      return resultStep;
    }
  }
}
