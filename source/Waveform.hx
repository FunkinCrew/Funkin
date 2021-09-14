import flixel.util.FlxColor;
import flixel.FlxG;
import openfl.geom.Rectangle;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import flixel.FlxSprite;

class Waveform extends FlxSprite
{
	/// referenced from https://github.com/gedehari/HaxeFlixel-Waveform-Rendering/blob/master/source/PlayState.hx
	/// by gedehari
	public var buffer:AudioBuffer;
	public var data:Bytes;

	public var length:Int;

	public function new(x:Int, y:Int, audioPath:String, height:Int)
	{
		super(x, y);

		var path = StringTools.replace(audioPath, "songs:", "");

		trace("loading " + path);

		buffer = AudioBuffer.fromFile(path);

		trace("BPS: " + buffer.bitsPerSample + " - Channels: " + buffer.channels);

		data = buffer.data.toBytes();

		var h = 0;

		var trackDurationSeconds = (data.length / (buffer.bitsPerSample / 8) / buffer.channels) / buffer.sampleRate;

		var pixelsPerCollumn:Int = Math.floor(1280 / (trackDurationSeconds / 1000));

		var totalSamples = (data.length / (buffer.bitsPerSample / 8) / buffer.channels);

		h = Math.round(totalSamples / pixelsPerCollumn);

		trace(h + " - calculated height");

		length = h;

		makeGraphic(h, 720, FlxColor.TRANSPARENT);
	}

	public function drawWaveform()
	{
		var index:Int = 0;
		var drawIndex:Int = 0;

		var totalSamples = (data.length / (buffer.bitsPerSample / 8) / buffer.channels);

		var min:Float = 0;
		var max:Float = 0;

		for (index in 0...Math.round(totalSamples))
		{
			var byte:Int = data.getUInt16(index);

			if (byte > 65535 / 2)
				byte -= 65535;

			var sample:Float = (byte / 65535);

			if (sample > 0)
			{
				if (sample > max)
					max = sample;
			}
			else if (sample < 0)
			{
				if (sample < min)
					min = sample;
			}

			trace("sample " + index);

			var pixelsMin:Float = Math.abs(min * 300);
			var pixelsMax:Float = max * 300;

			pixels.fillRect(new Rectangle(drawIndex, 0, 1, 720), 0xFF000000);
			pixels.fillRect(new Rectangle(drawIndex, (FlxG.height / 2) - pixelsMin, 1, pixelsMin + pixelsMax), FlxColor.GRAY);
			pixels.fillRect(new Rectangle(drawIndex, (FlxG.height / 2) - pixelsMin, 1, -(pixelsMin + pixelsMax)), FlxColor.GRAY);
			drawIndex += 1;

			min = 0;
			max = 0;
		}
	}
}
