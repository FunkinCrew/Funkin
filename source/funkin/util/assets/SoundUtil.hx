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
   * @param stream Whether to stream the sound instead of loading it fully into memory.
   * @return The playable sound, or `null` if loading failed.
   */
  public static function buildSoundFromBytes(input:Null<Bytes>, stream:Bool = false):Null<FunkinSound>
  {
    if (input == null) return null;
    #if !FEATURE_STREAMED_AUDIO
    stream = false;
    #end

    var buffer:Null<AudioBuffer> = AudioBuffer.fromBytes(input, stream);
    if (buffer == null) return null;
    var openflSound:OpenFLSound = OpenFLSound.fromAudioBuffer(buffer);
    if (openflSound == null) return null;
    var snd:Null<FunkinSound> = new FunkinSound();
    snd.loadAudio(openflSound, stream);
    snd.volume = 1;
    FlxG.sound.list.add(snd);
    FlxG.sound.defaultSoundGroup.add(snd);
    return snd;
  }
}
