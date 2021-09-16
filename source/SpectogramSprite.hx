package;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import lime.utils.Int16Array;

using flixel.util.FlxSpriteUtil;

class SpectogramSprite extends FlxSprite
{
	public function new()
	{
		super();

		makeGraphic(200, 200, FlxColor.BLUE);
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
		{
			if (FlxG.sound.music.playing)
			{
				FlxSpriteUtil.drawRect(this, 0, 0, width, height, FlxColor.BLUE);

				@:privateAccess
				var audioData:Int16Array = FlxG.sound.music._channel.__source.buffer.data; // jank and hacky lol!

				var numSamples:Int = Std.int(audioData.length / 2);

				var remappedShit:Int = Std.int(FlxMath.remapToRange(FlxG.sound.music.time, 0, FlxG.sound.music.length, 0, numSamples));

				var i = remappedShit;

				var prevLine:FlxPoint = new FlxPoint();

				for (sample in remappedShit...remappedShit + 256)
				{
					var left = audioData[i] / 32767;
					i += 2;

					var remappedSample:Float = FlxMath.remapToRange(sample, remappedShit, remappedShit + 256, 0, 1);

					FlxSpriteUtil.drawLine(this, prevLine.x, prevLine.y, width * remappedSample, left * height / 2 + height / 2);
					prevLine.x = width * remappedSample;
					prevLine.y = left * height / 2 + height / 2;
				}
			}
		}

		super.update(elapsed);
	}
}
