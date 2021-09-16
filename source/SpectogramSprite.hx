package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import lime.utils.Int16Array;

using flixel.util.FlxSpriteUtil;

class SpectogramSprite extends FlxTypedSpriteGroup<FlxSprite>
{
	var lengthOfShit:Int = 500;

	var daSound:FlxSound;

	public function new(daSound:FlxSound, ?col:FlxColor = FlxColor.WHITE)
	{
		super();

		this.daSound = daSound;

		for (i in 0...lengthOfShit)
		{
			var lineShit:FlxSprite = new FlxSprite(100, i / lengthOfShit * FlxG.height).makeGraphic(1, 1, col);
			lineShit.active = false;
			add(lineShit);
		}

		// makeGraphic(200, 200, FlxColor.BLACK);
	}

	var setBuffer:Bool = false;
	var audioData:Int16Array;
	var numSamples:Int = 0;

	override function update(elapsed:Float)
	{
		if (daSound != null)
		{
			var remappedShit:Int = 0;

			if (daSound.playing)
			{
				if (!setBuffer)
				{
					@:privateAccess
					audioData = cast daSound._channel.__source.buffer.data; // jank and hacky lol!
					setBuffer = true;
					numSamples = Std.int(audioData.length / 2);
				}
				else
				{
					remappedShit = Std.int(FlxMath.remapToRange(daSound.time, 0, daSound.length, 0, numSamples));
				}
			}
			else
			{
				if (setBuffer)
					remappedShit = Std.int(FlxMath.remapToRange(Conductor.songPosition, 0, daSound.length, 0, numSamples));
			}

			if (setBuffer)
			{
				var i = remappedShit;
				var prevLine:FlxPoint = new FlxPoint();

				var swagheight:Int = 200;

				for (sample in remappedShit...remappedShit + lengthOfShit)
				{
					var left = audioData[i] / 32767;
					var right = audioData[i + 1] / 32767;

					var balanced = (left + right) / 2;

					i += 2;

					var remappedSample:Float = FlxMath.remapToRange(sample, remappedShit, remappedShit + lengthOfShit, 0, lengthOfShit - 1);

					group.members[Std.int(remappedSample)].x = prevLine.x;
					// group.members[0].y = prevLine.y;

					// FlxSpriteUtil.drawLine(this, prevLine.x, prevLine.y, width * remappedSample, left * height / 2 + height / 2);
					prevLine.x = balanced * swagheight / 2 + swagheight / 2;
					// width * (remappedSample / 255);
					// prevLine.y = left * swagheight / 2 + swagheight / 2;
				}
			}
		}

		super.update(elapsed);
	}
}
