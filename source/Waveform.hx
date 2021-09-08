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

		var index = 0;

		var samplesPerCollumn:Int = 600;
		var min:Float = 0;
		var max:Float = 0;

		while ((index * 4) < (data.length - 1))
			{
				var byte:Int = data.getUInt16(index * 4);
	
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
	
				if ((index % samplesPerCollumn) == 0)
					h++;

				index += 1;
			}
	
		trace(h + " - calculated height");

		length = h;

		makeGraphic(h, 720, FlxColor.TRANSPARENT);

	}

	public function drawWaveform()
	{
		var currentTime:Float = Sys.time();
		var finishedTime:Float;

		var index:Int = 0;
		var drawIndex:Int = 0;
		var samplesPerCollumn:Int = 600;

		var min:Float = 0;
		var max:Float = 0;

		Sys.println("Interating");

		while ((index * 4) < (data.length - 1))
		{
			var byte:Int = data.getUInt16(index * 4);

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

			if ((index % samplesPerCollumn) == 0)
			{
				// trace("min: " + min + ", max: " + max);

				if (drawIndex > length)
				{
					drawIndex = 0;
				}

				var pixelsMin:Float = Math.abs(min * 300);
				var pixelsMax:Float = max * 300;

				pixels.fillRect(new Rectangle(drawIndex, 0, 1, 720), 0xFF000000);
				pixels.fillRect(new Rectangle(drawIndex, (FlxG.height / 2) - pixelsMin, 1, pixelsMin + pixelsMax), FlxColor.WHITE);
				pixels.fillRect(new Rectangle(drawIndex, (FlxG.height / 2) - pixelsMin, 1, -(pixelsMin + pixelsMax)), FlxColor.WHITE);
				drawIndex += 1;

				min = 0;
				max = 0;
			}

			index += 1;
		}

		finishedTime = Sys.time();

		Sys.println("Took " + (finishedTime - currentTime) + " seconds.");
	}
}
