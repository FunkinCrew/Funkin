package funkin.audio;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import funkin.audio.FunkinSound;

/**
 * A group of FunkinSounds that are all synced together.
 * Unlike FlxSoundGroup, you can also control their time and pitch.
 */
class SoundGroup extends FlxTypedGroup<FunkinSound>
{
  public var time(get, set):Float;

  public var volume(get, set):Float;

  public var pitch(get, set):Float;

  public function new()
  {
    super();
  }

  @:deprecated("Create sound files and call add() instead")
  public static function build(song:String, ?files:Array<String> = null):SoundGroup
  {
    var result = new SoundGroup();

    if (files == null)
    {
      // Add an empty voice.
      result.add(new FunkinSound());
      return result;
    }

    for (sndFile in files)
    {
      var snd:FunkinSound = FunkinSound.load(Paths.voices(song, '$sndFile'));
      result.add(snd); // adds it to main group for other shit
    }

    return result;
  }

  /**
   * Finds the largest deviation from the desired time inside this SoundGroup.
   *
   * @param targetTime	The time to check against.
   * 						If none is provided, it checks the time of all members against the first member of this SoundGroup.
   * @return The largest deviation from the target time found.
   */
  public function checkSyncError(?targetTime:Float):Float
  {
    var error:Float = 0;

    forEachAlive(function(snd) {
      if (targetTime == null) targetTime = snd.time;
      else
      {
        var diff:Float = snd.time - targetTime;
        if (Math.abs(diff) > Math.abs(error)) error = diff;
      }
    });
    return error;
  }

  /**
   * Add a sound to the group.
   */
  public override function add(sound:FunkinSound):FunkinSound
  {
    var result:FunkinSound = super.add(sound);

    if (result == null) return null;

    // We have to play, then pause the sound to set the time,
    // else the sound will restart immediately when played.
    result.play(true, 0.0);
    result.pause();
    result.time = this.time;

    result.onComplete = function() {
      this.onComplete();
    }

    // Apply parameters to the new sound.
    result.pitch = this.pitch;
    result.volume = this.volume;

    return result;
  }

  public dynamic function onComplete():Void {}

  /**
   * Pause all the sounds in the group.
   */
  public function pause()
  {
    forEachAlive(function(sound:FunkinSound) {
      sound.pause();
    });
  }

  /**
   * Play all the sounds in the group.
   */
  public function play(forceRestart:Bool = false, startTime:Float = 0.0, ?endTime:Float)
  {
    forEachAlive(function(sound:FunkinSound) {
      sound.play(forceRestart, startTime, endTime);
    });
  }

  /**
   * Resume all the sounds in the group.
   */
  public function resume()
  {
    forEachAlive(function(sound:FunkinSound) {
      sound.resume();
    });
  }

  /**
   * Stop all the sounds in the group.
   */
  public function stop()
  {
    forEachAlive(function(sound:FunkinSound) {
      sound.stop();
    });
  }

  public override function destroy()
  {
    stop();
    super.destroy();
  }

  /**
   * Remove all sounds from the group.
   */
  public override function clear():Void
  {
    this.stop();

    super.clear();
  }

  function get_time():Float
  {
    if (getFirstAlive() != null) return getFirstAlive().time;
    else
      return 0;
  }

  function set_time(time:Float):Float
  {
    forEachAlive(function(snd:FunkinSound) {
      // account for different offsets per sound?
      snd.time = time;
    });

    return time;
  }

  function get_volume():Float
  {
    if (getFirstAlive() != null) return getFirstAlive().volume;
    else
      return 1;
  }

  // in PlayState, adjust the code so that it only mutes the player1 vocal tracks?
  function set_volume(volume:Float):Float
  {
    forEachAlive(function(snd:FunkinSound) {
      snd.volume = volume;
    });

    return volume;
  }

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
    forEachAlive(function(snd:FunkinSound) {
      snd.pitch = val;
    });
    #end
    return val;
  }
}
