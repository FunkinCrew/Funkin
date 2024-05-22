package funkin.util.assets;

import haxe.io.Bytes;
import openfl.media.Sound as OpenFLSound;
import funkin.audio.FunkinSound;

class SoundUtil
{
  /**
   * Convert byte data into a playable sound.
   *
   * @param input The byte data.
   * @return The playable sound, or `null` if loading failed.
   */
  public static function buildSoundFromBytes(input:Null<Bytes>, label:String = 'unknown'):Null<FunkinSound>
  {
    if (input == null) return null;

    var openflSound:OpenFLSound = new OpenFLSound();
    openflSound.loadCompressedDataFromByteArray(openfl.utils.ByteArray.fromBytes(input), input.length);
    var output:FunkinSound = FunkinSound.load(openflSound, 1.0, false);
    @:privateAccess
    output._label = label;
    return output;
  }
}
