package funkin.audio;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;

/**
 * A group of FlxSounds which can be controlled as a whole.
 * 
 * Add sounds to the group using `add()`, and then control them
 * as a whole using the properties and methods of this class.
 * 
 * It is assumed that all the sounds will play at the same time,
 * and have the same duration.
 */
class FlxAudioGroup extends FlxTypedGroup<FlxSound>
{
  /**
   * The position in time of the sounds in the group.
   * Measured in milliseconds.
   */
  public var time(get, set):Float;

  function get_time():Float
  {
    if (getFirstAlive() != null) return getFirstAlive().time;
    else
      return 0;
  }

  function set_time(time:Float):Float
  {
    forEachAlive(function(sound:FlxSound)
    {
      // account for different offsets per sound?
      sound.time = time;
    });

    return time;
  }

  /**
   * The volume of the sounds in the group.
   */
  public var volume(get, set):Float;

  function get_volume():Float
  {
    if (getFirstAlive() != null) return getFirstAlive().volume;
    else
      return 1.0;
  }

  function set_volume(volume:Float):Float
  {
    forEachAlive(function(sound:FlxSound)
    {
      sound.volume = volume;
    });

    return volume;
  }

  /**
   * The pitch of the sounds in the group, as a multiplier of 1.0x.
   * `2.0` would play the audio twice as fast with a higher pitch,
   * and `0.5` would play the audio at half speed with a lower pitch.
   */
  public var pitch(get, set):Float;

  function get_pitch():Float
  {
    #if FLX_PITCH
    if (getFirstAlive() != null) return getFirstAlive().pitch;
    else
    #end
    return 1;
  }

  function set_pitch(val:Float):Float
  {
    #if FLX_PITCH
    trace('Setting audio pitch to ' + val);
    forEachAlive(function(sound:FlxSound)
    {
      sound.pitch = val;
    });
    #end
    return val;
  }

  /**
   * Whether members of the group should be destroyed when they finish playing.
   */
  public var autoDestroyMembers(default, set):Bool = false;

  function set_autoDestroyMembers(value:Bool):Bool
  {
    autoDestroyMembers = value;
    forEachAlive(function(sound:FlxSound)
    {
      sound.autoDestroy = value;
    });
    return value;
  }

  /**
   * Add a sound to the group.
   */
  public override function add(sound:FlxSound):FlxSound
  {
    var result:FlxSound = super.add(sound);

    if (result == null) return null;

    // Apply parameters to the new sound.
    result.autoDestroy = this.autoDestroyMembers;
    result.pitch = this.pitch;
    result.volume = this.volume;

    // We have to play, then pause the sound to set the time,
    // else the sound will restart immediately when played.
    result.play(true, 0.0);
    result.pause();
    result.time = this.time;

    return result;
  }

  /**
   * Pause all the sounds in the group.
   */
  public function pause()
  {
    forEachAlive(function(sound:FlxSound)
    {
      sound.pause();
    });
  }

  /**
   * Play all the sounds in the group.
   */
  public function play(forceRestart:Bool = false, startTime:Float = 0.0, ?endTime:Float)
  {
    forEachAlive(function(sound:FlxSound)
    {
      sound.play(forceRestart, startTime, endTime);
    });
  }

  /**
   * Resume all the sounds in the group.
   */
  public function resume()
  {
    forEachAlive(function(sound:FlxSound)
    {
      sound.resume();
    });
  }

  /**
   * Stop all the sounds in the group.
   */
  public function stop()
  {
    forEachAlive(function(sound:FlxSound)
    {
      sound.stop();
    });
  }

  public override function clear():Void
  {
    this.stop();

    super.clear();
  }

  /**
   * Calculates the deviation of the sounds in the group from the target time.
   * 
   * @param targetTime The time to compare the sounds to.
   *             If null, the current time of the first sound in the group is used.
   * @return The largest deviation of the sounds in the group from the target time.
   */
  public function calcDeviation(?targetTime:Float):Float
  {
    var deviation:Float = 0;

    forEachAlive(function(sound:FlxSound)
    {
      if (targetTime == null) targetTime = sound.time;
      else
      {
        var diff:Float = sound.time - targetTime;
        if (Math.abs(diff) > Math.abs(deviation)) deviation = diff;
      }
    });

    return deviation;
  }
}
