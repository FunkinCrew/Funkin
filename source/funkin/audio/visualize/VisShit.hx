package funkin.audio.visualize;

import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import funkin.audio.visualize.dsp.FFT;
import lime.system.ThreadPool;
import lime.utils.Int16Array;
import funkin.util.MathUtil;

using Lambda;

class VisShit
{
  public var snd:FlxSound;
  public var setBuffer:Bool = false;
  public var audioData:Int16Array;
  public var sampleRate:Int = 44100; // default, ez?
  public var numSamples:Int = 0;

  public function new(snd:FlxSound)
  {
    this.snd = snd;
  }

  public function funnyFFT(samples:Array<Float>, ?skipped:Int = 1):Array<Array<Float>>
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
    final indexToFreq = function(k:Int) {
      var powShit:Float = FlxMath.remapToRange(k, 0, halfN, 0, MathUtil.logBase(10, halfN)); // 4.3 is almost the log of 20Khz or so. Close enuf lol

      return 1.0 * (Math.pow(10, powShit)); // we need the `1.0` to avoid overflows
    };

    // "melodic" band-pass filter
    final minFreq = 20.70;
    final maxFreq = 4000.01;
    final melodicBandPass = function(k:Int, s:Float) {
      final freq = indexToFreq(k);
      final filter = freq > minFreq - binSize && freq < maxFreq + binSize ? 1 : 0;
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
        if (freq < maxFreq) freqOutput[indexOfArray].push(power);
        //
      }
      // haxe.Log.trace("", null);

      indexOfArray++;
      // move to next (overlapping) chunk
      c += hop;
    }

    if (FlxG.keys.justPressed.C) trace(freqOutput.length);

    return freqOutput;
  }

  public static function getCurAud(aud:Int16Array, index:Int):CurAudioInfo
  {
    var left = aud[index] / 32767;
    var right = aud[index + 2] / 32767;
    var balanced = (left + right) / 2;

    var funny:CurAudioInfo = {left: left, right: right, balanced: balanced};

    return funny;
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
        numSamples = Std.int(audioData.length / 2);
      }
    }
  }
}

typedef CurAudioInfo =
{
  var left:Float;
  var right:Float;
  var balanced:Float;
}
