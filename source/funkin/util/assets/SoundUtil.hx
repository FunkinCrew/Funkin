package funkin.util.assets;

import haxe.io.Bytes;
import flixel.system.FlxSound;

class SoundUtil
{
  /**
   * Convert byte data into a playable sound.
   *
   * @param input The byte data.
   * @return The playable sound, or `null` if loading failed.
   */
  public static function buildFlxSoundFromBytes(input:Null<Bytes>):Null<FlxSound>
  {
    if (input == null) return null;

    var openflSound:openfl.media.Sound = new openfl.media.Sound();
    openflSound.loadCompressedDataFromByteArray(openfl.utils.ByteArray.fromBytes(input), input.length);
    var output:FlxSound = FlxG.sound.load(openflSound, 1.0, false);
    return output;
  }
}
