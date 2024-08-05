package funkin.util.assets;

import haxe.io.Bytes;
import openfl.media.Sound as OpenFLSound;
import funkin.audio.FunkinSound;
import flixel.sound.FlxSound;
import lime.media.AudioSource;

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

    var openflSound:OpenFLSound = new OpenFLSound();
    openflSound.loadCompressedDataFromByteArray(openfl.utils.ByteArray.fromBytes(input), input.length);
    var output:FunkinSound = FunkinSound.load(openflSound, 1.0, false);
    return output;
  }

  /**
   * Gets an FlxSound audio source, mainly used for visualisers.
   *
   * @param input The byte data.
   * @return The playable sound, or `null` if loading failed.
   */
  public static function getSoundChannelSource(input:FlxSound):AudioSource
  {
    #if (openfl < "9.3.2") @:privateAccess
    return input._channel.__source;
    // if (input._channel.__source != null)
    #else
    @:privateAccess
    return input._channel.__audioSource;
    // if (input._channel.__audioSource != null) return input._channel.__audioSource;
    #end
    return null;
  }
}
