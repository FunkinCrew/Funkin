package funkin.audio;

import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.audio.waveform.WaveformData;

@:nullSafety
class VoicesGroup extends SoundGroup
{
  var playerVoices:Null<FlxTypedGroup<FunkinSound>>;
  var opponentVoices:Null<FlxTypedGroup<FunkinSound>>;

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
    playerVoices?.add(sound);
  }

  function set_playerVolume(volume:Float):Float
  {
    playerVoices?.forEachAlive(function(voice:FunkinSound) {
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

    playerVoices?.forEachAlive(function(voice:FunkinSound) {
      voice.time -= playerVoicesOffset;
    });
    opponentVoices?.forEachAlive(function(voice:FunkinSound) {
      voice.time -= opponentVoicesOffset;
    });

    return time;
  }

  function set_playerVoicesOffset(offset:Float):Float
  {
    playerVoices?.forEachAlive(function(voice:FunkinSound) {
      voice.time += playerVoicesOffset;
      voice.time -= offset;
    });
    return playerVoicesOffset = offset;
  }

  function set_opponentVoicesOffset(offset:Float):Float
  {
    opponentVoices?.forEachAlive(function(voice:FunkinSound) {
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
    opponentVoices?.add(sound);
  }

  function set_opponentVolume(volume:Float):Float
  {
    opponentVoices?.forEachAlive(function(voice:FunkinSound) {
      voice.volume = volume;
    });
    return opponentVolume = volume;
  }

  public function getPlayerVoice(index:Int = 0):Null<FunkinSound>
  {
    return playerVoices?.members[index];
  }

  public function getOpponentVoice(index:Int = 0):Null<FunkinSound>
  {
    return opponentVoices?.members[index];
  }

  public function getPlayerVoiceWaveform():Null<WaveformData>
  {
    if (playerVoices?.members.length == 0) return null;

    return playerVoices?.members[0].waveformData;
  }

  public function getOpponentVoiceWaveform():Null<WaveformData>
  {
    if (opponentVoices?.members.length == 0) return null;

    return opponentVoices?.members[0].waveformData;
  }

  /**
   * The length of the player's vocal track, in milliseconds.
   */
  public function getPlayerVoiceLength():Float
  {
    if (playerVoices?.members.length == 0) return 0.0;

    return playerVoices?.members[0]?.length ?? 0.0;
  }

  /**
   * The length of the opponent's vocal track, in milliseconds.
   */
  public function getOpponentVoiceLength():Float
  {
    if (opponentVoices?.members.length == 0) return 0.0;

    return opponentVoices?.members[0]?.length ?? 0.0;
  }

  public override function clear():Void
  {
    playerVoices?.clear();
    opponentVoices?.clear();
    super.clear();
  }

  public override function destroy():Void
  {
    if (playerVoices != null)
    {
      playerVoices?.destroy();
      playerVoices = null;
    }

    if (opponentVoices != null)
    {
      opponentVoices?.destroy();
      opponentVoices = null;
    }

    super.destroy();
  }
}
