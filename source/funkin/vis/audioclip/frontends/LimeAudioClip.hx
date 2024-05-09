package funkin.vis.audioclip.frontends;

import flixel.FlxG;
import flixel.math.FlxMath;
import funkin.vis.AudioBuffer;
import lime.media.AudioSource;

/**
 * Implementation of AudioClip for Lime.
 * On OpenFL you will want SoundChannel.__source (with @:privateAccess)
 * For Flixel, you will want to get the FlxSound._channel.__source
 * 
 * Note: On one of the recent OpenFL versions (9.3.2)
 * __source was renamed to __audioSource
 * https://github.com/openfl/openfl/commit/eec48a
 * 
 */
class LimeAudioClip implements funkin.vis.AudioClip
{
	public var audioBuffer(default, null):AudioBuffer;
    public var currentFrame(get, never):Int;
	public var source:Dynamic;

	public function new(audioSource:AudioSource)
	{
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

		return Std.int(FlxMath.remapToRange(FlxG.sound.music.time, 0, FlxG.sound.music.length, 0, dataLength / 2));
	}
}