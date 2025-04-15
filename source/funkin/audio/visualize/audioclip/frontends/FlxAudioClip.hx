package funkin.audio.visualize.audioclip.frontends;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import funkin.vis.AudioBuffer;
import lime.media.AudioSource;

/**
 * Implementation of AudioClip for flixel.
 *
 */
class FlxAudioClip implements funkin.vis.AudioClip
{
  public var audioBuffer(default, null):AudioBuffer;
  public var currentFrame(get, never):Int;
  public var source:Dynamic;
  public var snd:FlxSound;

  public function new(snd:FlxSound)
  {
    this.snd = snd;
    @:privateAccess
    var audioSource = snd._channel.__audioSource;

    var data:lime.utils.UInt16Array = cast audioSource.buffer.data;

    #if web
    var sampleRate:Float = audioSource.buffer.src._sounds[0]._node.context.sampleRate;
    #else
    var sampleRate = audioSource.buffer.sampleRate;
    #end

    this.audioBuffer = new AudioBuffer(data, sampleRate);
    this.source = audioSource.buffer.src;
  }

  private function get_currentFrame():Int
  {
    var dataLength:Int = 0;

    #if web
    dataLength = source.length;
    #else
    dataLength = audioBuffer.data.length;
    #end

    return Std.int(FlxMath.remapToRange(snd.time, 0, snd.length, 0, dataLength));
  }
}
