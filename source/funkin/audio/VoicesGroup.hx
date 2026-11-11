package funkin.audio;

import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.audio.waveform.WaveformData;

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
   * Voices which need to wait for their positive offset to elapse before playback.
   * The matching offset is stored at the same index in pendingVoiceOffsets.
   */
  var pendingVoices:Array<FunkinSound> = [];
  var pendingVoiceOffsets:Array<Float> = [];

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

  override public function play(forceRestart:Bool = false, startTime:Float = 0.0)
  {
    playerVoices?.forEachAlive(function(voice:FunkinSound)
    {
      playVoice(voice, forceRestart, startTime, playerVoicesOffset);
    });
    opponentVoices?.forEachAlive(function(voice:FunkinSound)
    {
      playVoice(voice, forceRestart, startTime, opponentVoicesOffset);
    });
  }

  function playVoice(voice:FunkinSound, forceRestart:Bool, startTime:Float, offset:Float):Void
  {
    var time:Float = startTime - offset;

    if (time < 0)
    {
      // Match FlxSound.play(false, ...): do not disturb a sound which is already playing.
      if (!forceRestart && voice.playing) return;

      if (voice.playing) voice.pause();
      voice.time = time;
      queueVoice(voice, offset);
      return;
    }

    var wasPending:Bool = removePendingVoice(voice);

    #if web
    if (voice.length > 0 && time > voice.length) return;
    #else
    if (time > voice.length) return;
    #end

    voice.play(forceRestart || wasPending, time);
  }

  public function updatePending(masterTime:Float, masterPlaying:Bool):Void
  {
    if (!masterPlaying || pendingVoices.length == 0) return;

    var i:Int = pendingVoices.length - 1;
    while (i >= 0)
    {
      var voice:FunkinSound = pendingVoices[i];
      var time:Float = masterTime - pendingVoiceOffsets[i];

      if (!voice.exists || !voice.alive)
      {
        pendingVoices.splice(i, 1);
        pendingVoiceOffsets.splice(i, 1);
        i--;
        continue;
      }

      voice.time = time;

      if (time >= 0)
      {
        pendingVoices.splice(i, 1);
        pendingVoiceOffsets.splice(i, 1);

        #if web
        if (voice.length <= 0 || time <= voice.length)
        {
          voice.play(true, time);
        }
        #else
        if (time <= voice.length)
        {
          voice.play(true, time);
        }
        #end
      }

      i--;
    }
  }

  function queueVoice(voice:FunkinSound, offset:Float):Void
  {
    removePendingVoice(voice);
    pendingVoices.push(voice);
    pendingVoiceOffsets.push(offset);
  }

  function removePendingVoice(voice:FunkinSound):Bool
  {
    var index:Int = pendingVoices.indexOf(voice);
    if (index < 0) return false;

    pendingVoices.splice(index, 1);
    pendingVoiceOffsets.splice(index, 1);
    return true;
  }

  override function set_time(time:Float):Float
  {
    playerVoices?.forEachAlive(function(voice:FunkinSound)
    {
      setVoiceTime(voice, time - playerVoicesOffset, playerVoicesOffset);
    });
    opponentVoices?.forEachAlive(function(voice:FunkinSound)
    {
      setVoiceTime(voice, time - opponentVoicesOffset, opponentVoicesOffset);
    });

    return time;
  }

  function setVoiceTime(voice:FunkinSound, time:Float, offset:Float):Void
  {
    if (time < 0)
    {
      if (voice.playing) voice.pause();
      voice.time = time;
      queueVoice(voice, offset);
    }
    else
    {
      voice.time = time;
    }
  }

  function set_playerVoicesOffset(offset:Float):Float
  {
    playerVoices?.forEachAlive(function(voice:FunkinSound)
    {
      updateVoiceOffset(voice, playerVoicesOffset, offset);
    });
    return playerVoicesOffset = offset;
  }

  function set_opponentVoicesOffset(offset:Float):Float
  {
    opponentVoices?.forEachAlive(function(voice:FunkinSound)
    {
      updateVoiceOffset(voice, opponentVoicesOffset, offset);
    });
    return opponentVoicesOffset = offset;
  }

  function updateVoiceOffset(voice:FunkinSound, oldOffset:Float, newOffset:Float):Void
  {
    var wasPending:Bool = removePendingVoice(voice);
    var wasPlaying:Bool = voice.playing;
    var masterTime:Float = voice.time + oldOffset;
    var time:Float = masterTime - newOffset;

    if (time < 0)
    {
      if (wasPlaying) voice.pause();
      voice.time = time;
      if (wasPending || wasPlaying) queueVoice(voice, newOffset);
    }
    else if (wasPending)
    {
      // Keep it queued until the instrumental clock confirms playback is active.
      voice.time = time;
      queueVoice(voice, newOffset);
    }
    else
    {
      voice.time = time;
    }
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

  override public function stop():Void
  {
    pendingVoices.resize(0);
    pendingVoiceOffsets.resize(0);
    super.stop();
  }

  override public function clear():Void
  {
    pendingVoices.resize(0);
    pendingVoiceOffsets.resize(0);
    playerVoices?.clear();
    opponentVoices?.clear();
    super.clear();
  }

  override public function destroy():Void
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
