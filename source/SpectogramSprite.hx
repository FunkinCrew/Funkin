package;

import dsp.FFT;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import lime.utils.Int16Array;

using Lambda;
using flixel.util.FlxSpriteUtil;

class SpectogramSprite extends FlxTypedSpriteGroup<FlxSprite>
{
	var sampleRate:Int;

	var lengthOfShit:Int = 500;

	public var visType:VISTYPE = UPDATED;

	public var col:Int = FlxColor.WHITE;
	public var daHeight:Float = FlxG.height;

	public var vis:VisShit;

	public function new(daSound:FlxSound, ?col:FlxColor = FlxColor.WHITE, ?height:Float = 720)
	{
		super();

		vis = new VisShit(daSound);
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

	public var audioData:Int16Array;

	var numSamples:Int = 0;

	override function update(elapsed:Float)
	{
		switch (visType)
		{
			case UPDATED:
				updateVisulizer();

			case FREQUENCIES:
				updateFFT();
			default:
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

		// vis.checkAndSetBuffer();

		if (setBuffer)
		{
			var samplesToGen:Int = Std.int(sampleRate * seconds);
			var startingSample:Int = Std.int(FlxMath.remapToRange(start, 0, vis.snd.length, 0, numSamples));

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
		vis.checkAndSetBuffer();

		if (vis.setBuffer)
		{
			audioData = vis.audioData;
			sampleRate = vis.sampleRate;
			setBuffer = vis.setBuffer;
			numSamples = Std.int(audioData.length / 2);
		}
	}

	var doAnim:Bool = false;
	var frameCounter:Int = 0;

	public function updateFFT()
	{
		if (vis.snd != null)
		{
			var remappedShit:Int = 0;

			checkAndSetBuffer();

			if (!doAnim)
			{
				frameCounter++;

				if (frameCounter >= 0)
				{
					frameCounter = 0;
					doAnim = true;
				}
			}

			if (setBuffer && doAnim)
			{
				doAnim = false;

				if (vis.snd.playing)
					remappedShit = Std.int(FlxMath.remapToRange(vis.snd.time, 0, vis.snd.length, 0, numSamples));
				else
					remappedShit = Std.int(FlxMath.remapToRange(Conductor.songPosition, 0, vis.snd.length, 0, numSamples));

				var i = remappedShit;
				var prevLine:FlxPoint = new FlxPoint();

				var swagheight:Int = 200;

				var fftSamples:Array<Float> = [];

				// var array:Array<Float> = cast audioData.subarray(remappedShit, remappedShit + lengthOfShit);

				if (FlxG.keys.justPressed.M)
				{
					trace('POOP LOL');
					var funnyAud = audioData.subarray(remappedShit, remappedShit + lengthOfShit);

					for (poop in funnyAud)
					{
						// trace("actual audio: " + poop);
						trace("win: " + poop);
					}

					// trace(audioData.subarray(remappedShit, remappedShit + lengthOfShit).buffer);
				}

				for (sample in remappedShit...remappedShit + (Std.int((44100 * (1 / 144)))))
				{
					var left = audioData[i] / 32767;
					var right = audioData[i + 1] / 32767;

					var balanced = (left + right) / 2;

					i += 2;

					// var remappedSample:Float = FlxMath.remapToRange(sample, remappedShit, remappedShit + lengthOfShit, 0, lengthOfShit - 1);
					fftSamples.push(balanced);
				}

				var freqShit = funnyFFT(fftSamples);

				for (i in 0...group.members.length)
				{
					// needs to be exponential growth / scaling
					// still need to optmize the FFT to run better, gets only samples needed?
					// not every frequency is built the same!
					// 20hz to 40z is a LOT of subtle low ends, but somethin like 20,000hz to 20,020hz, the difference is NOT the same!

					var powedShit:Float = FlxMath.remapToRange(i, 0, group.members.length, 0, 4);

					// a value between 10hz and 100Khz
					var hzPicker:Float = Math.pow(10, powedShit);

					// var sampleApprox:Int = Std.int(FlxMath.remapToRange(i, 0, group.members.length, startingSample, startingSample + samplesToGen));
					var remappedFreq:Int = Std.int(FlxMath.remapToRange(hzPicker, 0, 10000, 0, freqShit[0].length - 1));

					group.members[i].x = prevLine.x;
					group.members[i].y = prevLine.y;

					var freqPower:Float = 0;

					for (pow in 0...freqShit.length)
						freqPower += freqShit[pow][remappedFreq];

					freqPower /= freqShit.length;
					var freqIDK:Float = FlxMath.remapToRange(freqPower, 0, 0.000005, 0, 50);

					prevLine.x = (freqIDK * swagheight / 2 + swagheight / 2) + x;
					prevLine.y = (i / group.members.length * daHeight) + y;

					var line = FlxVector.get(prevLine.x - group.members[i].x, prevLine.y - group.members[i].y);

					// dont draw a line until i figure out a nicer way to view da spikes and shit idk lol!
					// group.members[i].setGraphicSize(Std.int(Math.max(line.length, 1)), Std.int(1));
					// group.members[i].angle = line.degrees;
				}
			}
		}
	}

	public function updateVisulizer():Void
	{
		if (vis.snd != null)
		{
			var remappedShit:Int = 0;

			checkAndSetBuffer();

			if (setBuffer)
			{
				if (vis.snd.playing)
					remappedShit = Std.int(FlxMath.remapToRange(vis.snd.time, 0, vis.snd.length, 0, numSamples));
				else
					remappedShit = Std.int(FlxMath.remapToRange(Conductor.songPosition, 0, vis.snd.length, 0, numSamples));

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

	function funnyFFT(samples:Array<Float>, ?skipped:Int = 1):Array<Array<Float>>
	{
		// nab multiple samples at once in while / for loops?

		var fs:Float = 44100 / skipped; // sample rate shit?

		final fftN = 1024;
		final halfN = Std.int(fftN / 2);
		final overlap = 0.5;
		final hop = Std.int(fftN * (1 - overlap));

		// window function to compensate for overlapping
		final a0 = 0.5; // => Hann(ing) window
		final window = (n:Int) -> a0 - (1 - a0) * Math.cos(2 * Math.PI * n / fftN);

		// helpers, note that spectrum indexes suppose non-negative frequencies
		final binSize = fs / fftN;
		final indexToFreq = function(k:Int)
		{
			var powShit:Float = FlxMath.remapToRange(k, 0, halfN, 0, 4.3); // 4.3 is almost 20khz

			return 1.0 * (Math.pow(10, powShit)); // we need the `1.0` to avoid overflows
		};

		// "melodic" band-pass filter
		final minFreq = 20.70;
		final maxFreq = 4000.01;
		final melodicBandPass = function(k:Int, s:Float)
		{
			// final freq = indexToFreq(k);
			// final filter = freq > minFreq - binSize && freq < maxFreq + binSize ? 1 : 0;
			return s;
		};

		var freqOutput:Array<Array<Float>> = [];

		var c = 0; // index where each chunk begins
		var indexOfArray:Int = 0;
		while (c < samples.length)
		{
			// take a chunk (zero-padded if needed) and apply the window
			final chunk = [
				for (n in 0...fftN)
					(c + n < samples.length ? samples[c + n] : 0.0) * window(n)
			];

			// compute positive spectrum with sampling correction and BP filter
			final freqs = FFT.rfft(chunk).map(z -> z.scale(1 / fftN).magnitude).mapi(melodicBandPass);

			freqOutput.push([]);

			// find spectral peaks and their instantaneous frequencies
			for (k => s in freqs)
			{
				final time = c / fs;
				final freq = indexToFreq(k);
				final power = s * s;
				if (FlxG.keys.justPressed.N)
				{
					trace(k);
					haxe.Log.trace('${time};${freq};${power}', null);
				}
				if (freq < maxFreq)
					freqOutput[indexOfArray].push(power);
				//
			}
			// haxe.Log.trace("", null);

			indexOfArray++;
			// move to next (overlapping) chunk
			c += hop;
		}

		if (FlxG.keys.justPressed.C)
			trace(freqOutput.length);

		return freqOutput;
	}
}

enum VISTYPE
{
	STATIC;
	UPDATED;
	FREQUENCIES;
}
