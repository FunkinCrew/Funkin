import dsp.FFT;
import flixel.FlxSprite;
import flixel.addons.plugin.taskManager.FlxTask;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import ui.PreferencesMenu.CheckboxThingie;

using Lambda;

class ABotVis extends FlxTypedSpriteGroup<FlxSprite>
{
	public var vis:VisShit;

	var volumes:Array<Float> = [];

	public function new(snd:FlxSound)
	{
		super();

		vis = new VisShit(snd);
		// vis.snd = snd;

		var visFrms:FlxAtlasFrames = Paths.getSparrowAtlas('aBotViz');

		for (lol in 1...8)
		{
			// pushes initial value
			volumes.push(0.0);

			var viz:FlxSprite = new FlxSprite(50 * lol, 0);
			viz.frames = visFrms;
			add(viz);

			var visStr = 'VIZ';
			if (lol == 5)
				visStr = 'viz'; // lol makes it lowercase, accomodates for art that I dont wanna rename!

			viz.animation.addByPrefix('VIZ', visStr + lol, 0);
			viz.animation.play('VIZ', false, false, -1);
		}
	}

	override function update(elapsed:Float)
	{
		// updateViz();

		updateFFT();

		super.update(elapsed);
	}

	function updateFFT()
	{
		if (vis.snd != null)
		{
			vis.checkAndSetBuffer();

			if (vis.setBuffer)
			{
				var remappedShit:Int = 0;

				if (vis.snd.playing)
					remappedShit = Std.int(FlxMath.remapToRange(vis.snd.time, 0, vis.snd.length, 0, vis.numSamples));
				else
					remappedShit = Std.int(FlxMath.remapToRange(Conductor.songPosition, 0, vis.snd.length, 0, vis.numSamples));

				var fftSamples:Array<Float> = [];

				var swagBucks = remappedShit;

				for (i in remappedShit...remappedShit + (Std.int((44100 * (1 / 144)))))
				{
					var left = vis.audioData[swagBucks] / 32767;
					var right = vis.audioData[swagBucks + 1] / 32767;

					var balanced = (left + right) / 2;

					swagBucks += 2;

					fftSamples.push(balanced);
				}

				var freqShit = funnyFFT(fftSamples);

				for (i in 0...group.members.length)
				{
					var sliceLength:Int = Std.int(freqShit[0].length / group.members.length);

					var volSlice = freqShit[0].slice(Std.int(sliceLength * i), Std.int(sliceLength * i) + sliceLength);

					var avgVel:Float = 0;

					for (slice in volSlice)
					{
						avgVel += slice;
					}

					avgVel /= volSlice.length;

					avgVel *= 10000000;

					volumes[i] += avgVel - (FlxG.elapsed * (volumes[i] * 50));

					var animFrame:Int = Std.int(volumes[i]);

					animFrame = Math.floor(Math.min(5, animFrame));
					animFrame = Math.floor(Math.max(0, animFrame));

					animFrame = Std.int(Math.abs(animFrame - 5)); // shitty dumbass flip, cuz dave got da shit backwards lol!

					group.members[i].animation.curAnim.curFrame = animFrame;
					if (FlxG.keys.justPressed.U)
					{
						trace(avgVel);
						trace(group.members[i].animation.curAnim.curFrame);
					}
				}

				// group.members[0].animation.curAnim.curFrame =
			}
		}
	}

	public function updateViz()
	{
		if (vis.snd != null)
		{
			var remappedShit:Int = 0;
			vis.checkAndSetBuffer();

			if (vis.setBuffer)
			{
				// var startingSample:Int = Std.int(FlxMath.remapToRange)

				if (vis.snd.playing)
					remappedShit = Std.int(FlxMath.remapToRange(vis.snd.time, 0, vis.snd.length, 0, vis.numSamples));

				for (i in 0...group.members.length)
				{
					var sampleApprox:Int = Std.int(FlxMath.remapToRange(i, 0, group.members.length, remappedShit, remappedShit + 500));

					var left = vis.audioData[sampleApprox] / 32767;

					var animFrame:Int = Std.int(FlxMath.remapToRange(left, -1, 1, 0, 6));

					group.members[i].animation.curAnim.curFrame = animFrame;
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

		// NOTE TO SELF FOR WHEN I WAKE UP

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

			// if (FlxG.keys.justPressed.M)
			// trace(FFT.rfft(chunk).map(z -> z.scale(1 / fs).magnitude));

			// find spectral peaks and their instantaneous frequencies
			for (k => s in freqs)
			{
				final time = c / fs;
				final freq = indexToFreq(k);
				final power = s * s;
				if (FlxG.keys.justPressed.I)
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
