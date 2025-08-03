package funkin.audio.visualize.dsp;

using funkin.audio.visualize.dsp.OffsetArray;
using funkin.audio.visualize.dsp.Signal;

// these are only used for testing, down in FFT.main()

/**
  Fast/Finite Fourier Transforms.
**/
@:nullSafety
class FFT
{
  /**
    Computes the Discrete Fourier Transform (DFT) of a `Complex` sequence.

    If the input has N data points (N should be a power of 2 or padding will be added)
    from a signal sampled at intervals of 1/Fs, the result will be a sequence of N
    samples from the Discrete-Time Fourier Transform (DTFT) - which is Fs-periodic -
    with a spacing of Fs/N Hz between them and a scaling factor of Fs.
  **/
  public static function fft(input:Array<Complex>):Array<Complex>
    return do_fft(input, false);

  /**
    Like `fft`, but for a real (Float) sequence input.

    Since the input time signal is real, its frequency representation is
    Hermitian-symmetric so we only return the positive frequencies.
  **/
  public static function rfft(input:Array<Float>):Array<Complex>
  {
    final s = fft(input.map(Complex.fromReal));
    return s.slice(0, Std.int(s.length / 2) + 1);
  }

  /**
    Computes the Inverse DFT of a periodic input sequence.

    If the input contains N (a power of 2) DTFT samples, each spaced Fs/N Hz
    from each other, the result will consist of N data points as sampled
    from a time signal at intervals of 1/Fs with a scaling factor of 1/Fs.
  **/
  public static function ifft(input:Array<Complex>):Array<Complex>
    return do_fft(input, true);

  // Handles padding and scaling for forwards and inverse FFTs.
  static function do_fft(input:Array<Complex>, inverse:Bool):Array<Complex>
  {
    final n = nextPow2(input.length);
    var ts = [for (i in 0...n) if (i < input.length) input[i] else Complex.zero];
    var fs = [for (_ in 0...n) Complex.zero];
    ditfft2(ts, 0, fs, 0, n, 1, inverse);
    return inverse ? fs.map(z -> z.scale(1 / n)) : fs;
    return fs;
  }

  // Radix-2 Decimation-In-Time variant of Cooley–Tukey's FFT, recursive.
  static function ditfft2(time:Array<Complex>, t:Int, freq:Array<Complex>, f:Int, n:Int, step:Int, inverse:Bool):Void
  {
    if (n == 1)
    {
      freq[f] = time[t].copy();
    }
    else
    {
      final halfLen = Std.int(n / 2);
      ditfft2(time, t, freq, f, halfLen, step * 2, inverse);
      ditfft2(time, t + step, freq, f + halfLen, halfLen, step * 2, inverse);
      for (k in 0...halfLen)
      {
        final twiddle = Complex.exp((inverse ? 1 : -1) * 2 * Math.PI * k / n);
        final even = freq[f + k].copy();
        final odd = freq[f + k + halfLen].copy();
        freq[f + k] = even + twiddle * odd;
        freq[f + k + halfLen] = even - twiddle * odd;
      }
    }
  }

  // Naive O(n^2) DFT, used for testing purposes.
  static function dft(ts:Array<Complex>, ?inverse:Bool):Array<Complex>
  {
    if (inverse == null) inverse = false;
    final n = ts.length;
    var fs = new Array<Complex>();
    fs.resize(n);
    for (f in 0...n)
    {
      var sum = Complex.zero;
      for (t in 0...n)
      {
        sum += ts[t] * Complex.exp((inverse ? 1 : -1) * 2 * Math.PI * f * t / n);
      }
      fs[f] = inverse ? sum.scale(1 / n) : sum;
    }
    return fs;
  }

  /**
    Finds the power of 2 that is equal to or greater than the given natural.
  **/
  static function nextPow2(x:Int):Int
  {
    if (x < 2) return 1;
    else if ((x & (x - 1)) == 0) return x;
    var pow = 2;
    x--;
    while ((x >>= 1) != 0)
      pow <<= 1;
    return pow;
  }

  // testing, but also acts like an example
  static function main()
  {
    // sampling and buffer parameters
    final Fs = 44100.0;
    final N = 512;
    final halfN = Std.int(N / 2);

    // build a time signal as a sum of sinusoids
    final freqs = [5919.911];
    final ts = [for (n in 0...N) freqs.map(f -> Math.sin(2 * Math.PI * f * n / Fs)).sum()];

    // get positive spectrum and use its symmetry to reconstruct negative domain
    final fs_pos = rfft(ts);
    final fs_fft = new OffsetArray([for (k in -(halfN - 1)...0) fs_pos[-k].conj()].concat(fs_pos), -(halfN - 1));

    // double-check with naive DFT
    final fs_dft = new OffsetArray(dft(ts.map(Complex.fromReal)).circShift(halfN - 1), -(halfN - 1));
    final fs_err = [for (k in -(halfN - 1)...halfN) fs_fft[k] - fs_dft[k]];
    final max_fs_err = fs_err.map(z -> z.magnitude).max();
    if (max_fs_err > 1e-6) haxe.Log.trace('FT Error: ${max_fs_err}', null);
    // else for (k => s in fs_fft) haxe.Log.trace('${k * Fs / N};${s.scale(1 / Fs).magnitude}', null);

    // find spectral peaks to detect signal frequencies
    final freqis = fs_fft.array.map(z -> z.magnitude)
      .findPeaks()
      .map(k -> (k - (halfN - 1)) * Fs / N)
      .filter(f -> f >= 0);
    if (freqis.length != freqs.length)
    {
      trace('Found frequencies: ${freqis}');
    }
    else
    {
      final freqs_err = [for (i in 0...freqs.length) freqis[i] - freqs[i]];
      final max_freqs_err = freqs_err.map(Math.abs).max();
      if (max_freqs_err > Fs / N) trace('Frequency Errors: ${freqs_err}');
    }

    // recover time signal from the frequency domain
    final ts_ifft = ifft(fs_fft.array.circShift(-(halfN - 1)).map(z -> z.scale(1 / Fs)));
    final ts_err = [for (n in 0...N) ts_ifft[n].scale(Fs).real - ts[n]];
    final max_ts_err = ts_err.map(Math.abs).max();
    if (max_ts_err > 1e-6) haxe.Log.trace('IFT Error: ${max_ts_err}', null);
    // else for (n in 0...ts_ifft.length) haxe.Log.trace('${n / Fs};${ts_ifft[n].scale(Fs).real}', null);
  }
}
