package funkin.audio;

import funkin.audio.FunkinSound;
import flixel.group.FlxGroup.FlxTypedGroup;

class VoicesGroup extends SoundGroup
{
  var playerVoices:FlxTypedGroup<FunkinSound>;
  var opponentVoices:FlxTypedGroup<FunkinSound>;

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
    playerVoices = new FlxTypedGroup<FunkinSound>();
    opponentVoices = new FlxTypedGroup<FunkinSound>();
  }

  /**
   * Add a voice to the player group.
   */
  public function addPlayerVoice(sound:FunkinSound):Void
  {
    super.add(sound);
    playerVoices.add(sound);
  }

  function set_playerVolume(volume:Float):Float
  {
    playerVoices.forEachAlive(function(voice:FunkinSound) {
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

    playerVoices.forEachAlive(function(voice:FunkinSound) {
      voice.time -= playerVoicesOffset;
    });
    opponentVoices.forEachAlive(function(voice:FunkinSound) {
      voice.time -= opponentVoicesOffset;
    });

    return time;
  }

  function set_playerVoicesOffset(offset:Float):Float
  {
    playerVoices.forEachAlive(function(voice:FunkinSound) {
      voice.time += playerVoicesOffset;
      voice.time -= offset;
    });
    return playerVoicesOffset = offset;
  }

  function set_opponentVoicesOffset(offset:Float):Float
  {
    opponentVoices.forEachAlive(function(voice:FunkinSound) {
      voice.time += opponentVoicesOffset;
      voice.time -= offset;
    });
    return opponentVoicesOffset = offset;
  }

  /**
   * Add a voice to the opponent group.
   */
  public function addOpponentVoice(sound:FunkinSound):Void
  {
    super.add(sound);
    opponentVoices.add(sound);
  }

  function set_opponentVolume(volume:Float):Float
  {
    opponentVoices.forEachAlive(function(voice:FunkinSound) {
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
