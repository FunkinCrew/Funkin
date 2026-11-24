package funkin.util.assets;

import haxe.io.Bytes;
import openfl.media.Sound as OpenFLSound;
import funkin.audio.FunkinSound;
import lime.media.AudioBuffer;

@:nullSafety
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
    if (openflSound == null) return null;
    var snd:Null<FunkinSound> = new FunkinSound();
    snd.loadAudio(openflSound, false);
    snd.volume = 1;
    FlxG.sound.list.add(snd);
    FlxG.sound.defaultSoundGroup.add(snd);
    return snd;
  }
}
