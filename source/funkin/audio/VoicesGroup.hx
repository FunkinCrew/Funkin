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
  public var playerVolume(default, set):Float;

  /**
   * Control the volume of only the sounds in the opponent group.
   */
  public var opponentVolume(default, set):Float;

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
