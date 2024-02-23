package funkin.audio.visualize;

import flixel.FlxG;
import flixel.math.FlxMath;
import funkVis.AudioBuffer;
import lime.media.AudioSource;

class AudioClip implements funkVis.AudioClip
{
  public var audioBuffer(default, null):AudioBuffer;
  public var currentFrame(get, never):Int;

  public function new(audioSource:AudioSource)
  {
    var data:lime.utils.UInt16Array = cast audioSource.buffer.data;
    this.audioBuffer = new AudioBuffer(data, audioSource.buffer.sampleRate);
  }

  private function get_currentFrame():Int
  {
    return Std.int(FlxMath.remapToRange(FlxG.sound.music.time, 0, FlxG.sound.music.length, 0, audioBuffer.data.length / 2));
  }
}
