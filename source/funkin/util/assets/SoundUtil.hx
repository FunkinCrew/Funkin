package funkin.util.assets;

import lime.media.openal.AL;
import lime.media.openal.ALSource;
import flixel.sound.FlxSound;
import haxe.io.Bytes;
import openfl.media.Sound as OpenFLSound;
import funkin.audio.FunkinSound;
import lime.media.AudioBuffer;

class SoundUtil
{
  /**
   * Convert byte data into a playable sound.
   *
   * @param input The byte data.
   * @return The playable sound, or `null` if loading failed.
   */
  public static function buildSoundFromBytes(input:Null<Bytes>):Null<FunkinSound>
  {
    if (input == null) return null;

    var openflSound:OpenFLSound = OpenFLSound.fromAudioBuffer(AudioBuffer.fromBytes(input));
    var output:FunkinSound = FunkinSound.load(openflSound, 1.0, false);
    return output;
  }

  /**
   * Gets the hardware delay this sound is playing with.
   * On platforms not supporting OpenAL, this will always be 0.
   *
   * @param sound The sound to get the delay for.
   * @return The hardware playback delay (in milliseconds)
   */
  public static function getPlaybackDeviceDelay(sound:FlxSound):Float
  {
    #if (lime_cffi && lime_openal && !macro)
    @:privateAccess
    {
      if (sound.time <= 0 || sound._channel == null) return 0;
      var handle:ALSource = sound._channel.__audioSource.__backend.handle;
      var offsets = AL.getSourcedvSOFT(handle, AL.SEC_OFFSET_LATENCY_SOFT, 2);
      return offsets[1] * 1000;
    }
    #else
    return 0;
    #end
  }
}
