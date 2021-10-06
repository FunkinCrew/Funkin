package;

import flixel.system.FlxSound;
import lime.utils.Int16Array;

class VisShit
{
	public var snd:FlxSound;
	public var setBuffer:Bool = false;
	public var audioData:Int16Array;
	public var sampleRate:Int = 44100; // default, ez?

	public function new(snd:FlxSound)
	{
		this.snd = snd;
	}

	public function checkAndSetBuffer()
	{
		if (snd != null && snd.playing)
		{
			if (!setBuffer)
			{
				// Math.pow3
				@:privateAccess
				var buf = snd._channel.__source.buffer;

				// @:privateAccess
				audioData = cast buf.data; // jank and hacky lol! kinda busted on HTML5 also!!
				sampleRate = buf.sampleRate;

				trace('got audio buffer shit');
				trace(sampleRate);
				trace(buf.bitsPerSample);

				setBuffer = true;
				// numSamples = Std.int(audioData.length / 2);
			}
		}
	}
}
