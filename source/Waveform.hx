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

    public function new(x:Int,y:Int, audioPath:String, height:Int)
    {
        super(x,y);

        var path = StringTools.replace(audioPath, "songs:","");

        trace("loading " + path);

        buffer = AudioBuffer.fromFile(path);

        trace("BPS: " + buffer.bitsPerSample + " - Channels: " + buffer.channels);

        makeGraphic(height,350,FlxColor.TRANSPARENT);

        angle = 90;

        data = buffer.data.toBytes();
    }

    public function drawWaveform()
    {
		var index:Int = 0;
		var drawIndex:Int = 0;
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
				{
					// trace("min: " + min + ", max: " + max);

					if (drawIndex > 350)
					{
						drawIndex = 0;
					}

					var pixelsMin:Float = Math.abs(min * 300);
					var pixelsMax:Float = max * 300;

					pixels.fillRect(new Rectangle(drawIndex, x, 1, height), 0xFF000000);
					pixels.fillRect(new Rectangle(drawIndex, y - pixelsMin, 1, pixelsMin + pixelsMax), FlxColor.WHITE);
					drawIndex += 1;

					min = 0;
					max = 0;
				}

				index += 1;
			}
    }
}