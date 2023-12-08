package funkin.audio;

import flixel.sound.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;

class VoicesGroup extends SoundGroup
{
  var playerVoices:FlxTypedGroup<FlxSound>;
  var opponentVoices:FlxTypedGroup<FlxSound>;

  /**
   * Control the volume of only the sounds in the player group.
   */
  public var playerVolume(default, set):Float = 1.0;

  /**
   * Control the volume of only the sounds in the opponent group.
   */
  public var opponentVolume(default, set):Float = 1.0;

  /**
   * Set the time offset for the player's vocal track.
   */
  public var playerVoicesOffset(default, set):Float = 0.0;

  /**
   * Set the time offset for the opponent's vocal track.
   */
  public var opponentVoicesOffset(default, set):Float = 0.0;

  public function new()
  {
    super();
    playerVoices = new FlxTypedGroup<FlxSound>();
    opponentVoices = new FlxTypedGroup<FlxSound>();
  }

  /**
   * Add a voice to the player group.
   */
  public function addPlayerVoice(sound:FlxSound):Void
  {
    super.add(sound);
    playerVoices.add(sound);
  }

  function set_playerVolume(volume:Float):Float
  {
    playerVoices.forEachAlive(function(voice:FlxSound) {
      voice.volume = volume;
    });
    return playerVolume = volume;
  }

  override function set_time(time:Float):Float
  {
    forEachAlive(function(snd) {
      // account for different offsets per sound?
      snd.time = time;
    });

    playerVoices.forEachAlive(function(voice:FlxSound) {
      voice.time -= playerVoicesOffset;
    });
    opponentVoices.forEachAlive(function(voice:FlxSound) {
      voice.time -= opponentVoicesOffset;
    });

    return time;
  }

  function set_playerVoicesOffset(offset:Float):Float
  {
    playerVoices.forEachAlive(function(voice:FlxSound) {
      voice.time += playerVoicesOffset;
      voice.time -= offset;
    });
    return playerVoicesOffset = offset;
  }

  function set_opponentVoicesOffset(offset:Float):Float
  {
    opponentVoices.forEachAlive(function(voice:FlxSound) {
      voice.time += opponentVoicesOffset;
      voice.time -= offset;
    });
    return opponentVoicesOffset = offset;
  }

  public override function update(elapsed:Float):Void
  {
    forEachAlive(function(snd) {
      if (snd.time < 0)
      {
        // Sync the time without calling update().
        // time gets reset if it's negative.
        snd.time += elapsed * 1000;
      }
      else
      {
        snd.update(elapsed);
      }
    });
  }

  /**
   * Add a voice to the opponent group.
   */
  public function addOpponentVoice(sound:FlxSound):Void
  {
    super.add(sound);
    opponentVoices.add(sound);
  }

  function set_opponentVolume(volume:Float):Float
  {
    opponentVoices.forEachAlive(function(voice:FlxSound) {
      voice.volume = volume;
    });
    return opponentVolume = volume;
  }

  public override function clear():Void
  {
    playerVoices.clear();
    opponentVoices.clear();
    super.clear();
  }

  public override function destroy():Void
  {
    playerVoices.destroy();
    opponentVoices.destroy();
    super.destroy();
  }
}
