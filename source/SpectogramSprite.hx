package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import lime.utils.Int16Array;

using flixel.util.FlxSpriteUtil;

class SpectogramSprite extends FlxTypedSpriteGroup<FlxSprite>
{
	public function new()
	{
		super();

		for (i in 0...256)
		{
			var lineShit:FlxSprite = new FlxSprite(100, i / 256 * FlxG.height).makeGraphic(1, 1);
			// lineShit.origin.set();

			// var xClip = lineShit.clipRect;
			// xClip.width = 1;

			// lineShit.clipRect = xClip;
			add(lineShit);
		}

		// makeGraphic(200, 200, FlxColor.BLACK);
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
		{
			if (FlxG.sound.music.playing)
			{
				// FlxSpriteUtil.drawRect(this, 0, 0, width, height, 0x45000000);

				@:privateAccess
				var audioData:Int16Array = FlxG.sound.music._channel.__source.buffer.data; // jank and hacky lol!

				var numSamples:Int = Std.int(audioData.length / 2);
				var remappedShit:Int = Std.int(FlxMath.remapToRange(FlxG.sound.music.time, 0, FlxG.sound.music.length, 0, numSamples));
				var i = remappedShit;
				var prevLine:FlxPoint = new FlxPoint();

				var swagheight:Int = 200;

				for (sample in remappedShit...remappedShit + 256)
				{
					var left = audioData[i] / 32767;
					i += 2;

					var remappedSample:Float = FlxMath.remapToRange(sample, remappedShit, remappedShit + 256, 0, 255);

					group.members[Std.int(remappedSample)].x = prevLine.x;
					// group.members[0].y = prevLine.y;

					// FlxSpriteUtil.drawLine(this, prevLine.x, prevLine.y, width * remappedSample, left * height / 2 + height / 2);
					prevLine.x = left * swagheight / 2 + swagheight / 2;
					// width * (remappedSample / 255);
					// prevLine.y = left * swagheight / 2 + swagheight / 2;
				}
			}
		}

		super.update(elapsed);
	}
}
