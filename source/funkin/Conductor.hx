package funkin;

import funkin.util.Constants;
import flixel.util.FlxSignal;
import flixel.math.FlxMath;
import funkin.data.song.SongData.SongTimeChange;
import funkin.data.song.SongDataUtils;
import funkin.save.Save;
import funkin.util.TimerUtil.SongSequence;
import haxe.Timer;
import flixel.sound.FlxSound;

/**
 * A core class which handles musical timing throughout the game,
 * both in gameplay and in menus.
 */
@:nullSafety
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
   * The current instance of the Conductor.
   * If one doesn't currently exist, a new one will be created.
   *
   * You can also do stuff like store a reference to the Conductor and pass it around or temporarily replace it,
   * or have a second Conductor running at the same time, or other weird stuff like that if you need to.
   */
  public static var instance(get, never):Conductor;

  static var _instance:Null<Conductor> = null;

  /**
   * Signal fired when the current static Conductor instance advances to a new measure.
   */
  public static var measureHit(default, null):FlxSignal = new FlxSignal();

  /**
   * Signal fired when THIS Conductor instance advances to a new measure.
   * TODO: This naming sucks but we can't make a static and instance field with the same name!
   */
  public var onMeasureHit(default, null):FlxSignal = new FlxSignal();

  /**
   * Signal fired when the current Conductor instance advances to a new beat.
   */
  public static var beatHit(default, null):FlxSignal = new FlxSignal();

  /**
   * Signal fired when THIS Conductor instance advances to a new beat.
   * TODO: This naming sucks but we can't make a static and instance field with the same name!
   */
  public var onBeatHit(default, null):FlxSignal = new FlxSignal();

  /**
   * Signal fired when the current Conductor instance advances to a new step.
   */
  public static var stepHit(default, null):FlxSignal = new FlxSignal();

  /**
   * Signal fired when THIS Conductor instance advances to a new step.
   * TODO: This naming sucks but we can't make a static and instance field with the same name!
   */
  public var onStepHit(default, null):FlxSignal = new FlxSignal();

  /**
   * The list of time changes in the song.
   * There should be at least one time change (at the beginning of the song) to define the BPM.
   */
  var timeChanges:Array<SongTimeChange> = [];

  /**
   * The most recent time change for the current song position.
   */
  public var currentTimeChange(default, null):Null<SongTimeChange>;

  /**
   * The current position in the song in milliseconds.
   * Update this every frame based on the audio position using `Conductor.instance.update()`.
   */
  public var songPosition(default, null):Float = 0;

  /**
   * The offset between frame time and music time.
   * Used in `getTimeWithDelta()` to get a more accurate music time when on higher framerates.
   */
  var songPositionDelta(default, null):Float = 0;

  var prevTimestamp:Float = 0;
  var prevTime:Float = 0;

  /**
   * Beats per minute of the current song at the current time.
   */
  public var bpm(get, never):Float;

  function get_bpm():Float
  {
    if (bpmOverride != null) return bpmOverride;

    if (currentTimeChange == null) return Constants.DEFAULT_BPM;

    return currentTimeChange.bpm;
  }

  /**
   * Beats per minute of the current song at the start time.
   */
  public var startingBPM(get, never):Float;

  function get_startingBPM():Float
  {
    if (bpmOverride != null) return bpmOverride;

    var timeChange = timeChanges[0];
    if (timeChange == null) return Constants.DEFAULT_BPM;

    return timeChange.bpm;
  }

  /**
   * The current value set by `forceBPM`.
   * If false, BPM is determined by time changes.
   */
  var bpmOverride:Null<Float> = null;

  /**
   * Duration of a measure in milliseconds. Calculated based on bpm.
   */
  public var measureLengthMs(get, never):Float;

  function get_measureLengthMs():Float
  {
    return beatLengthMs * timeSignatureNumerator;
  }

  /**
   * Duration of a beat (quarter note) in milliseconds. Calculated based on bpm.
   */
  public var beatLengthMs(get, never):Float;

  function get_beatLengthMs():Float
  {
    // Tied directly to BPM.
    return ((Constants.SECS_PER_MIN / bpm) * Constants.MS_PER_SEC);
  }

  /**
   * Duration of a step (sixtennth note) in milliseconds. Calculated based on bpm.
   */
  public var stepLengthMs(get, never):Float;

  function get_stepLengthMs():Float
  {
    return beatLengthMs / timeSignatureNumerator;
  }

  /**
   * The numerator for the current time signature (the `3` in `3/4`).
   */
  public var timeSignatureNumerator(get, never):Int;

  function get_timeSignatureNumerator():Int
  {
    if (currentTimeChange == null) return Constants.DEFAULT_TIME_SIGNATURE_NUM;

    return currentTimeChange.timeSignatureNum;
  }

  /**
   * The denominator for the current time signature (the `4` in `3/4`).
   */
  public var timeSignatureDenominator(get, never):Int;

  function get_timeSignatureDenominator():Int
  {
    if (currentTimeChange == null) return Constants.DEFAULT_TIME_SIGNATURE_DEN;

    return currentTimeChange.timeSignatureDen;
  }

  /**
   * Current position in the song, in measures.
   */
  public var currentMeasure(default, null):Int = 0;

  /**
   * Current position in the song, in beats.
   */
  public var currentBeat(default, null):Int = 0;

  /**
   * Current position in the song, in steps.
   */
  public var currentStep(default, null):Int = 0;

  /**
   * Current position in the song, in measures and fractions of a measure.
   */
  public var currentMeasureTime(default, null):Float = 0;

  /**
   * Current position in the song, in beats and fractions of a measure.
   */
  public var currentBeatTime(default, null):Float = 0;

  /**
   * Current position in the song, in steps and fractions of a step.
   */
  public var currentStepTime(default, null):Float = 0;

  /**
   * An offset tied to the current chart file to compensate for a delay in the instrumental.
   */
  public var instrumentalOffset:Float = 0;

  /**
   * The instrumental offset, in terms of steps.
   */
  public var instrumentalOffsetSteps(get, never):Float;

  function get_instrumentalOffsetSteps():Float
  {
    var startingStepLengthMs:Float = ((Constants.SECS_PER_MIN / startingBPM) * Constants.MS_PER_SEC) / timeSignatureNumerator;

    return instrumentalOffset / startingStepLengthMs;
  }

  /**
   * An offset tied to the file format of the audio file being played.
   */
  public var formatOffset:Float = 0;

  /**
   * An offset set by the user to compensate for input lag.
   * No matter if you're using a local conductor or not, this always loads
   * to/from the save file
   */
  public var globalOffset(get, never):Int;

  /**
   * An offset set by the user to compensate for audio/visual lag
   * No matter if you're using a local conductor or not, this always loads
   * to/from the save file
   */
  public var audioVisualOffset(get, never):Int;

  function get_globalOffset():Int
  {
    return Preferences.globalOffset;
  }

  function get_audioVisualOffset():Int
  {
    return Save?.instance?.options?.audioVisualOffset ?? 0;
  }

  public var combinedOffset(get, never):Float;

  function get_combinedOffset():Float
  {
    return instrumentalOffset + formatOffset + globalOffset;
  }

  /**
   * The number of beats in a measure. May be fractional depending on the time signature.
   */
  public var beatsPerMeasure(get, never):Float;

  function get_beatsPerMeasure():Float
  {
    // NOTE: Not always an integer, for example 7/8 is 3.5 beats per measure
    return stepsPerMeasure / Constants.STEPS_PER_BEAT;
  }

  /**
   * The number of steps in a measure.
   * TODO: I don't think this can be fractional?
   */
  public var stepsPerMeasure(get, never):Int;

  function get_stepsPerMeasure():Int
  {
    // TODO: Is this always an integer?
    return Std.int(timeSignatureNumerator / timeSignatureDenominator * Constants.STEPS_PER_BEAT * Constants.STEPS_PER_BEAT);
  }

  /**
   * Reset the Conductor, replacing the current instance with a fresh one.
   */
  public static function reset():Void
  {
    set_instance(new Conductor());
  }

  static function dispatchMeasureHit():Void
  {
    Conductor.measureHit.dispatch();
  }

  static function dispatchBeatHit():Void
  {
    Conductor.beatHit.dispatch();
  }

  static function dispatchStepHit():Void
  {
    Conductor.stepHit.dispatch();
  }

  static function setupSingleton(input:Conductor):Void
  {
    input.onMeasureHit.add(dispatchMeasureHit);

    input.onBeatHit.add(dispatchBeatHit);

    input.onStepHit.add(dispatchStepHit);
  }

  static function clearSingleton(input:Conductor):Void
  {
    input.onMeasureHit.remove(dispatchMeasureHit);

    input.onBeatHit.remove(dispatchBeatHit);

    input.onStepHit.remove(dispatchStepHit);
  }

  static function get_instance():Conductor
  {
    if (Conductor._instance == null) set_instance(new Conductor());
    if (Conductor._instance == null) throw "Could not initialize singleton Conductor!";
    return Conductor._instance;
  }

  static function set_instance(instance:Conductor):Conductor
  {
    // Use _instance in here to avoid recursion
    if (Conductor._instance != null) clearSingleton(Conductor._instance);

    Conductor._instance = instance;

    if (Conductor._instance != null) setupSingleton(Conductor._instance);

    return Conductor._instance;
  }

  /**
   * The constructor.
   */
  public function new() {}

  /**
   * Forcibly defines the current BPM of the song.
   * Useful for things like the chart editor that need to manipulate BPM in real time.
   *
   * Set to null to reset to the BPM defined by the timeChanges.
   *
   * WARNING: Avoid this for things like setting the BPM of the title screen music,
   * you should have a metadata file for it instead.
   * We should probably deprecate this in the future.
   */
  public function forceBPM(?bpm:Float):Void
  {
    if (bpm != null)
    {
      trace('[CONDUCTOR] Forcing BPM to ${bpm}');
    }
    else
    {
      trace('[CONDUCTOR] Resetting BPM to default');
    }

    this.bpmOverride = bpm;
  }

  /**
   * Update the conductor with the current song position.
   * BPM, current step, etc. will be re-calculated based on the song position.
   *
   * @param	songPosition The current position in the song in milliseconds.
   *        Leave blank to use the FlxG.sound.music position.
   * @param applyOffsets If it should apply the instrumentalOffset + formatOffset + audioVisualOffset
   * @param forceDispatch If it should force the dispatch of onStepHit, onBeatHit, and onMeasureHit
   *        even if the current step, beat, or measure hasn't changed.
   */
  public function update(?songPos:Float, applyOffsets:Bool = true, forceDispatch:Bool = false):Void
  {
    var currentTime:Float = (FlxG.sound.music != null) ? FlxG.sound.music.time : 0.0;
    var currentLength:Float = (FlxG.sound.music != null) ? FlxG.sound.music.length : 0.0;

    if (songPos == null)
    {
      songPos = currentTime;
    }

    // Take into account instrumental and file format song offsets.
    songPos += applyOffsets ? (combinedOffset) : 0;

    var oldMeasure:Float = this.currentMeasure;
    var oldBeat:Float = this.currentBeat;
    var oldStep:Float = this.currentStep;

    // If the song is playing, limit the song position to the length of the song or beginning of the song.
    if (FlxG.sound.music != null && FlxG.sound.music.playing)
    {
      this.songPosition = FlxMath.bound(Math.min(this.combinedOffset, 0), songPos, currentLength);
      this.songPositionDelta += FlxG.elapsed * 1000 * FlxG.sound.music.pitch;
    }
    else
    {
      this.songPosition = songPos;
    }

    // Set the song position we are at (for purposes of calculating note positions, etc).

    currentTimeChange = timeChanges[0];
    if (this.songPosition > 0.0)
    {
      for (i in 0...timeChanges.length)
      {
        if (this.songPosition >= timeChanges[i].timeStamp) currentTimeChange = timeChanges[i];

        if (this.songPosition < timeChanges[i].timeStamp) break;
      }
    }

    if (currentTimeChange == null && bpmOverride == null && FlxG.sound.music != null)
    {
      trace('WARNING: Conductor is broken, timeChanges is empty.');
    }
    else if (currentTimeChange != null && this.songPosition > 0.0)
    {
      // roundDecimal prevents representing 8 as 7.9999999
      this.currentStepTime = FlxMath.roundDecimal((currentTimeChange.beatTime * Constants.STEPS_PER_BEAT)
        + (this.songPosition - currentTimeChange.timeStamp) / stepLengthMs, 6);
      this.currentBeatTime = currentStepTime / Constants.STEPS_PER_BEAT;
      this.currentMeasureTime = currentStepTime / stepsPerMeasure;
      this.currentStep = Math.floor(currentStepTime);
      this.currentBeat = Math.floor(currentBeatTime);
      this.currentMeasure = Math.floor(currentMeasureTime);
    }
    else
    {
      // Assume a constant BPM equal to the forced value.
      this.currentStepTime = FlxMath.roundDecimal((songPosition / stepLengthMs), 4);
      this.currentBeatTime = currentStepTime / Constants.STEPS_PER_BEAT;
      this.currentMeasureTime = currentStepTime / stepsPerMeasure;
      this.currentStep = Math.floor(currentStepTime);
      this.currentBeat = Math.floor(currentBeatTime);
      this.currentMeasure = Math.floor(currentMeasureTime);
    }

    // FlxSignals are really cool.
    if (currentStep != oldStep)
    {
      this.onStepHit.dispatch();
    }

    if (currentBeat != oldBeat)
    {
      this.onBeatHit.dispatch();
    }

    if (currentMeasure != oldMeasure)
    {
      this.onMeasureHit.dispatch();
    }

    // only update the timestamp if songPosition actually changed
    // which it doesn't do every frame!
    if (prevTime != this.songPosition)
    {
      this.songPositionDelta = 0;

      // Update the timestamp for use in-between frames
      prevTime = this.songPosition;
      prevTimestamp = Std.int(Timer.stamp() * 1000);
    }

    if (this == Conductor.instance) @:privateAccess SongSequence.update.dispatch();
  }

  /**
   * Returns a more accurate music time for higher framerates.
   * @return Float
   */
  public function getTimeWithDelta():Float
  {
    return this.songPosition + this.songPositionDelta;
  }

  /**
   * Can be called in-between frames, usually for input related things
   * that can potentially get processed on exact milliseconds/timestmaps.
   * If you need song position, use `Conductor.instance.songPosition` instead
   * for use in update() related functions.
   * @param soundToCheck Which FlxSound object to check, defaults to FlxG.sound.music if no input
   * @return Float
   */
  public function getTimeWithDiff(?soundToCheck:FlxSound):Float
  {
    if (soundToCheck == null) soundToCheck = FlxG.sound.music;
    // trace(this.songPosition);

    @:privateAccess
    this.songPosition = soundToCheck._channel.position;
    // return this.songPosition + (Std.int(Timer.stamp() * 1000) - prevTimestamp);
    // trace("\t--> " + this.songPosition);
    return this.songPosition;
  }

  /**
   * Apply the `SongTimeChange` data from the song metadata to this Conductor.
   * @param songTimeChanges The SongTimeChanges.
   */
  public function mapTimeChanges(songTimeChanges:Array<SongTimeChange>):Void
  {
    timeChanges = [];

    // Sort in place just in case it's out of order.
    SongDataUtils.sortTimeChanges(songTimeChanges);

    for (songTimeChange in songTimeChanges)
    {
      // TODO: Maybe handle this different?
      // Do we care about BPM at negative timestamps?
      // Without any custom handling, `currentStepTime` becomes non-zero at `songPosition = 0`.
      if (songTimeChange.timeStamp < 0.0) songTimeChange.timeStamp = 0.0;

      if (songTimeChange.timeStamp <= 0.0)
      {
        songTimeChange.beatTime = 0.0;
      }
      else
      {
        // Calculate the beat time of this timestamp.
        songTimeChange.beatTime = 0.0;

        if (songTimeChange.timeStamp > 0.0 && timeChanges.length > 0)
        {
          var prevTimeChange:SongTimeChange = timeChanges[timeChanges.length - 1];
          songTimeChange.beatTime = FlxMath.roundDecimal(prevTimeChange.beatTime
            + ((songTimeChange.timeStamp - prevTimeChange.timeStamp) * prevTimeChange.bpm / Constants.SECS_PER_MIN / Constants.MS_PER_SEC),
            4);
        }
      }

      timeChanges.push(songTimeChange);
    }

    if (timeChanges.length > 0)
    {
      trace('Done mapping time changes: ${timeChanges}');
    }

    // Update currentStepTime
    this.update(this.songPosition, false);
  }

  /**
   * Given a time in milliseconds, return a time in steps.
   * @param ms The time in milliseconds.
   * @return The time in steps.
   */
  public function getTimeInSteps(ms:Float):Float
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
          resultStep = lastTimeChange.beatTime * Constants.STEPS_PER_BEAT;
        }
        else
        {
          // This time change is after the requested time.
          break;
        }
      }

      var lastStepLengthMs:Float = ((Constants.SECS_PER_MIN / lastTimeChange.bpm) * Constants.MS_PER_SEC) / timeSignatureNumerator;
      var resultFractionalStep:Float = (ms - lastTimeChange.timeStamp) / lastStepLengthMs;
      resultStep += resultFractionalStep;

      return resultStep;
    }
  }

  /**
   * Given a time in steps and fractional steps, return a time in milliseconds.
   * @param stepTime The time in steps.
   * @return The time in milliseconds.
   */
  public function getStepTimeInMs(stepTime:Float):Float
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
        if (stepTime >= timeChange.beatTime * Constants.STEPS_PER_BEAT)
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
      resultMs += (stepTime - lastTimeChange.beatTime * Constants.STEPS_PER_BEAT) * lastStepLengthMs;

      return resultMs;
    }
  }

  /**
   * Given a time in beats and fractional beats, return a time in milliseconds.
   * @param beatTime The time in beats.
   * @return The time in milliseconds.
   */
  public function getBeatTimeInMs(beatTime:Float):Float
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

  /**
   * Adds Conductor fields to the Flixel debugger variable display.
   * @param conductorToUse The conductor to use. Defaults to `Conductor.instance`.
   */
  public static function watchQuick(?target:Conductor):Void
  {
    if (target == null) target = Conductor.instance;

    FlxG.watch.addQuick('songPosition', target.songPosition);
    FlxG.watch.addQuick('bpm', target.bpm);
    FlxG.watch.addQuick('currentMeasureTime', target.currentMeasureTime);
    FlxG.watch.addQuick('currentBeatTime', target.currentBeatTime);
    FlxG.watch.addQuick('currentStepTime', target.currentStepTime);
  }
}
