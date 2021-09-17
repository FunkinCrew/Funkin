package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import lime.utils.Int16Array;

using flixel.util.FlxSpriteUtil;

class SpectogramSprite extends FlxTypedSpriteGroup<FlxSprite>
{
	var sampleRate:Int;

	var lengthOfShit:Int = 500;
	var daSound:FlxSound;

	public var visType:VISTYPE = UPDATED;

	public var col:Int = FlxColor.WHITE;
	public var daHeight:Float = FlxG.height;

	public function new(daSound:FlxSound, ?col:FlxColor = FlxColor.WHITE, ?height:Float = 720)
	{
		super();

		this.daSound = daSound;
		this.col = col;
		this.daHeight = height;

		regenLineShit();

		// makeGraphic(200, 200, FlxColor.BLACK);
	}

	public function regenLineShit():Void
	{
		for (i in 0...lengthOfShit)
		{
			var lineShit:FlxSprite = new FlxSprite(100, i / lengthOfShit * daHeight).makeGraphic(1, 1, col);
			lineShit.active = false;
			add(lineShit);
		}
	}

	var setBuffer:Bool = false;
	var audioData:Int16Array;
	var numSamples:Int = 0;

	override function update(elapsed:Float)
	{
		if (visType == UPDATED)
		{
			updateVisulizer();
		}

		// if visType is static, call updateVisulizer() manually whenever you want to update it!

		super.update(elapsed);
	}

	/**
	 * @param start is the start in milliseconds?
	 */
	public function generateSection(start:Float = 0, seconds:Float = 1):Void
	{
		checkAndSetBuffer();

		if (setBuffer)
		{
			var samplesToGen:Int = Std.int(sampleRate * seconds);
			var startingSample:Int = Std.int(FlxMath.remapToRange(start, 0, daSound.length, 0, numSamples));

			var prevLine:FlxPoint = new FlxPoint();

			for (i in 0...group.members.length)
			{
				var sampleApprox:Int = Std.int(FlxMath.remapToRange(i, 0, group.members.length, startingSample, startingSample + samplesToGen));

				var left = audioData[sampleApprox] / 32767;
				var right = audioData[sampleApprox + 1] / 32767;

				var swagheight:Int = 200;
				var balanced = (left + right) / 2;

				group.members[i].x = prevLine.x;
				group.members[i].y = prevLine.y;

				prevLine.x = (balanced * swagheight / 2 + swagheight / 2) + x;
				prevLine.y = (i / group.members.length * daHeight) + y;

				var line = FlxVector.get(prevLine.x - group.members[i].x, prevLine.y - group.members[i].y);

				group.members[i].setGraphicSize(Std.int(Math.max(line.length, 1)), Std.int(1));
				group.members[i].angle = line.degrees;
			}
		}
	}

	public function checkAndSetBuffer()
	{
		if (daSound.playing)
		{
			if (!setBuffer)
			{
				// Math.pow3
				@:privateAccess
				var buf = daSound._channel.__source.buffer;

				// @:privateAccess
				audioData = cast buf.data; // jank and hacky lol! kinda busted on HTML5 also!!
				sampleRate = buf.sampleRate;

				trace('got audio buffer shit');
				trace(sampleRate);
				trace(buf.bitsPerSample);

				setBuffer = true;
				numSamples = Std.int(audioData.length / 2);
			}
		}
	}

	public function updateVisulizer():Void
	{
		if (daSound != null)
		{
			var remappedShit:Int = 0;

			checkAndSetBuffer();

			if (setBuffer)
			{
				if (daSound.playing)
					remappedShit = Std.int(FlxMath.remapToRange(daSound.time, 0, daSound.length, 0, numSamples));
				else
					remappedShit = Std.int(FlxMath.remapToRange(Conductor.songPosition, 0, daSound.length, 0, numSamples));

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
					group.members[Std.int(remappedSample)].y = prevLine.y;
					// group.members[0].y = prevLine.y;

					// FlxSpriteUtil.drawLine(this, prevLine.x, prevLine.y, width * remappedSample, left * height / 2 + height / 2);
					prevLine.x = (balanced * swagheight / 2 + swagheight / 2) + x;
					prevLine.y = (Std.int(remappedSample) / lengthOfShit * daHeight) + y;

					var line = FlxVector.get(prevLine.x - group.members[Std.int(remappedSample)].x, prevLine.y - group.members[Std.int(remappedSample)].y);

					group.members[Std.int(remappedSample)].setGraphicSize(Std.int(Math.max(line.length, 1)), Std.int(1));
					group.members[Std.int(remappedSample)].angle = line.degrees;
				}
			}
		}
	}
}

enum VISTYPE
{
	STATIC;
	UPDATED;
}
