package funkin.audio;

import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.audio.waveform.WaveformData;

@:nullSafety
class VoicesGroup extends SoundGroup
{
  public var voices:Array<Null<VoicesGroupEntry>> = [];

  public var playerVoices(get, set):Null<VoicesGroupEntry>;
  public var opponentVoices(get, set):Null<VoicesGroupEntry>;

  /**
   * Control the volume of only the sounds in the player group.
   */
  public var playerVolume(get, set):Float;

  /**
   * Control the volume of only the sounds in the opponent group.
   */
  public var opponentVolume(get, set):Float;

  /**
   * Whether or not setting `playerVolume` does anything.
   * Set this to true if you want to control track volumes with a script.
   */
  public var playerManualVolume(get, set):Bool;

  /**
   * Whether or not setting `opponentVolume` does anything.
   * Set this to true if you want to control track volumes with a script.
   */
  public var opponentManualVolume(get, set):Bool;

  /**
   * Set the time offset for the player's vocal track.
   */
  public var playerVoicesOffset(get, set):Float;

  /**
   * Set the time offset for the opponent's vocal track.
   */
  public var opponentVoicesOffset(get, set):Float;

  public function new()
  {
    super();
    playerVoices = new VoicesGroupEntry();
    opponentVoices = new VoicesGroupEntry();
    @:nullSafety(Off)
    playerVoices.parentGroup = this;
    @:nullSafety(Off)
    opponentVoices.parentGroup = this;
  }

  function set_playerVoices(value:Null<VoicesGroupEntry>)
  {
    return voices[0] = value;
  }

  function get_playerVoices()
  {
    return voices[0];
  }

  function set_opponentVoices(value:Null<VoicesGroupEntry>)
  {
    return voices[1] = value;
  }

  function get_opponentVoices()
  {
    return voices[1];
  }

  function set_playerVolume(volume:Float):Float
  {
    if (playerVoices != null)
    {
      @:nullSafety(Off)
      playerVoices.volume = volume;
      return volume;
    }
    return 0;
  }

  function get_playerVolume():Float
  {
    return playerVoices?.volume ?? 0;
  }

  function set_opponentVolume(volume:Float):Float
  {
    if (opponentVoices != null)
    {
      @:nullSafety(Off)
      opponentVoices.volume = volume;
      return volume;
    }
    return 0;
  }

  function get_opponentVolume():Float
  {
    return opponentVoices?.volume ?? 0;
  }

  function set_playerManualVolume(manualVolume:Bool):Bool
  {
    if (playerVoices != null)
    {
      @:nullSafety(Off)
      playerVoices.manualVolume = manualVolume;
      return manualVolume;
    }
    return false;
  }

  function get_playerManualVolume():Bool
  {
    return playerVoices?.manualVolume ?? false;
  }

  function set_opponentManualVolume(manualVolume:Bool):Bool
  {
    if (opponentVoices != null)
    {
      @:nullSafety(Off)
      opponentVoices.manualVolume = manualVolume;
      return manualVolume;
    }
    return false;
  }

  function get_opponentManualVolume():Bool
  {
    return opponentVoices?.manualVolume ?? false;
  }

  function set_playerVoicesOffset(offset:Float):Float
  {
    if (playerVoices != null)
    {
      @:nullSafety(Off)
      playerVoices.voicesOffset = offset;
      return offset;
    }
    return 0;
  }

  function get_playerVoicesOffset():Float
  {
    return playerVoices?.voicesOffset ?? 0;
  }

  function set_opponentVoicesOffset(offset:Float):Float
  {
    if (opponentVoices != null)
    {
      @:nullSafety(Off)
      opponentVoices.voicesOffset = offset;
      return offset;
    }
    return 0;
  }

  function get_opponentVoicesOffset():Float
  {
    return opponentVoices?.voicesOffset ?? 0;
  }

  /**
   * Add a voice to the player group.
   */
  public function addPlayerVoice(sound:FunkinSound):Void
  {
    playerVoices?.addVoice(sound);
  }

  /**
   * Add a voice to the opponent group.
   */
  public function addOpponentVoice(sound:FunkinSound):Void
  {
    opponentVoices?.addVoice(sound);
  }

  public function getPlayerVoice(index:Int = 0):Null<FunkinSound>
  {
    return playerVoices?.getVoice(index);
  }

  public function getOpponentVoice(index:Int = 0):Null<FunkinSound>
  {
    return opponentVoices?.getVoice(index);
  }

  public function getPlayerVoiceWaveform():Null<WaveformData>
  {
    return playerVoices?.getVoiceWaveform();
  }

  public function getOpponentVoiceWaveform():Null<WaveformData>
  {
    return opponentVoices?.getVoiceWaveform();
  }

  /**
   * The length of the player's vocal track, in milliseconds.
   */
  public function getPlayerVoiceLength():Float
  {
    return playerVoices?.getVoiceLength() ?? 0.0;
  }

  /**
   * The length of the opponent's vocal track, in milliseconds.
   */
  public function getOpponentVoiceLength():Float
  {
    return opponentVoices?.getVoiceLength() ?? 0.0;
  }

  override function set_time(time:Float):Float
  {
    forEachAlive(function(snd) {
      // account for different offsets per sound?
      snd.time = time;
    });

    for (entry in voices)
    {
      entry?.forEachAlive(function(voice:FunkinSound) {
        voice.time -= entry.voicesOffset;
      });
    }

    return time;
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

class VoicesGroupEntry extends FlxTypedGroup<FunkinSound>
{
  /**
   * The parent group of this entry.
   * This should be assigned before adding tracks to this entry.
   * Otherwise, any tracks added here will not be added to the parent because it doesn't exist yet.
   */
  public var parentGroup:VoicesGroup;

  /**
   * Controls the volume of all voices in this entry.
   */
  public var volume(default, set):Float = 1.0;

  /**
   * Whether or not setting `volume` does anything.
   * Set this to true if you want to control track volumes with a script.
   */
  public var manualVolume:Bool = false;

  /**
   * Set the time offset for this vocal track.
   */
  public var voicesOffset(default, set):Float = 0.0;

  function set_volume(volume:Float):Float
  {
    if (!manualVolume) for (voice in members)
    {
      voice.volume = volume;
    }
    return this.volume = volume;
  }

  function set_voicesOffset(offset:Float):Float
  {
    for (voice in members)
    {
      voice.time += voicesOffset;
      voice.time -= offset;
    }
    return voicesOffset = offset;
  }

  public function new()
  {
    super();
    volume = 1.0;
    voicesOffset = 0.0;
  }

  public function getVoice(index:Int = 0):Null<FunkinSound>
  {
    return members[index];
  }

  public function getVoiceWaveform():Null<WaveformData>
  {
    if (members.length == 0) return null;

    return members[0].waveformData;
  }

  /**
   * The length of the vocal track, in milliseconds.
   */
  public function getVoiceLength():Float
  {
    if (members.length == 0) return 0.0;

    return members[0]?.length ?? 0.0;
  }

  /**
   * Add a voice to the group.
   * The `parentGroup` variable should be assigned before adding tracks to this entry.
   * Otherwise, any tracks added here will not be added to the parent because it doesn't exist yet.
   */
  public function addVoice(sound:FunkinSound):Void
  {
    if (parentGroup != null) parentGroup.add(sound);
    super.add(sound);
  }
}
