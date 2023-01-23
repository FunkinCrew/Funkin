package funkin;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;

// different than FlxSoundGroup cuz this can control all the sounds time and shit
// when needed
class VoicesGroup extends FlxTypedGroup<FlxSound>
{
  public var time(get, set):Float;

  public var volume(get, set):Float;

  public var pitch(get, set):Float;

  // make it a group that you add to?
  public function new()
  {
    super();
  }

  // TODO: Remove this.
  public static function build(song:String, ?files:Array<String> = null):VoicesGroup
  {
    var result = new VoicesGroup();

    if (files == null)
    {
      // Add an empty voice.
      result.add(new FlxSound());
      return result;
    }

    for (sndFile in files)
    {
      var snd:FlxSound = new FlxSound().loadEmbedded(Paths.voices(song, '$sndFile'));
      FlxG.sound.list.add(snd); // adds it to sound group for proper volumes
      result.add(snd); // adds it to main group for other shit
    }

    return result;
  }

  /**
   * Finds the largest deviation from the desired time inside this VoicesGroup.
   * 
   * @param targetTime	The time to check against.
   * 						If none is provided, it checks the time of all members against the first member of this VoicesGroup.
   * @return The largest deviation from the target time found.
   */
  public function checkSyncError(?targetTime:Float):Float
  {
    var error:Float = 0;

    forEachAlive(function(snd)
    {
      if (targetTime == null) targetTime = snd.time;
      else
      {
        var diff:Float = snd.time - targetTime;
        if (Math.abs(diff) > Math.abs(error)) error = diff;
      }
    });
    return error;
  }

  // prob a better / cleaner way to do all these forEach stuff?
  public function pause()
  {
    forEachAlive(function(snd)
    {
      snd.pause();
    });
  }

  public function play()
  {
    forEachAlive(function(snd)
    {
      snd.play();
    });
  }

  public function stop()
  {
    forEachAlive(function(snd)
    {
      snd.stop();
    });
  }

  function get_time():Float
  {
    if (getFirstAlive() != null) return getFirstAlive().time;
    else
      return 0;
  }

  function set_time(time:Float):Float
  {
    forEachAlive(function(snd)
    {
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
    forEachAlive(function(snd)
    {
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
    forEachAlive(function(snd)
    {
      snd.pitch = val;
    });
    #end
    return val;
  }
}
