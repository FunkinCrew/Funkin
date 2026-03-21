package funkin.audio;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import funkin.audio.waveform.WaveformData;

@:access(funkin.audio.FunkinSound)
@:nullSafety
class VoicesGroup extends SoundGroup
{
  /**
   * Whenever or not the game is using the legacy vocals system (shared Voices.ogg)
   */
  public var legacyVoiceSystem:Bool = false;

  public var legacyVoiceUsesPlayer:Bool = false;

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
    playerVoices?.forEachAlive(function(voice:FunkinSound)
    {
      voice.volume = volume;
    });
    return playerVolume = volume;
  }

  override function play(forceRestart:Bool = false, startTime:Float = 0.0, ?endTime:Float)
  {
    var sounds:Array<FlxSound> = [];

    forEachAlive(function(sound:FunkinSound) {
      var localTime = startTime;

      if (playerVoices?.members.contains(sound) ?? false) localTime -= playerVoicesOffset;
      else if (opponentVoices?.members.contains(sound) ?? false) localTime -= opponentVoicesOffset;

      if (sound.playing && !forceRestart || sound.length < localTime)
      {
        return;
      }

      sound.prepare(localTime, endTime);
      sounds.push(sound);
    });

    FlxSound.playSounds(sounds);
  }

  override function set_time(time:Float):Float
  {
    // account for different offsets per sound?

    var sounds:Array<FlxSound> = [];

    forEachAlive(function(sound:FunkinSound)
    {
      var localTime = time;

      if (playerVoices?.members.contains(sound) ?? false) localTime -= playerVoicesOffset;
      else if (opponentVoices?.members.contains(sound) ?? false) localTime -= opponentVoicesOffset;

      if (!sound.loaded || sound.length < localTime || !sound.playing) return;

      sound.prepare(localTime);
      sounds.push(sound);
    });

    FlxSound.playSounds(sounds);

    return time;
  }

  function set_playerVoicesOffset(offset:Float):Float
  {
    playerVoices?.forEachAlive(function(voice:FunkinSound)
    {
      voice.time += playerVoicesOffset - offset;
    });
    return playerVoicesOffset = offset;
  }

  function set_opponentVoicesOffset(offset:Float):Float
  {
    opponentVoices?.forEachAlive(function(voice:FunkinSound)
    {
      voice.time += opponentVoicesOffset - offset;
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
    opponentVoices?.forEachAlive(function(voice:FunkinSound)
    {
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
