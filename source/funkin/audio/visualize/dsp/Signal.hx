package funkin.audio.visualize.dsp;

using Lambda;

/**
  Signal processing miscellaneous utilities.
**/
@:nullSafety
class Signal
{
  /**
    Returns a smoothed version of the input array using a moving average.
  **/
  public static function smooth(y:Array<Float>, n:Int):Null<Array<Float>>
  {
    if (n <= 0)
    {
      return null;
    }
    else if (n == 1)
    {
      return y.copy();
    }
    else
    {
      var smoothed = new Array<Float>();
      smoothed.resize(y.length);
      for (i in 0...y.length)
      {
        var m = i + 1 < n ? i : n - 1;
        smoothed[i] = sum(y.slice(i - m, i + 1));
      }
      return smoothed;
    }
  }

  /**
    Finds indexes of peaks in the order they appear in the input sequence.

    @param threshold Minimal peak height wrt. its neighbours, defaults to 0.
    @param minHeight Minimal peak height wrt. the whole input, defaults to global minimum.
  **/
  public static function findPeaks(y:Array<Float>, ?threshold:Float, ?minHeight:Float):Array<Int>
  {
    threshold = threshold == null ? 0.0 : Math.abs(threshold);
    minHeight = minHeight == null ? Signal.min(y) : minHeight;

    var peaks = new Array<Int>();

    final dy = [for (i in 1...y.length) y[i] - y[i - 1]];
    for (i in 1...dy.length)
    {
      // peak: function growth positive to its left and negative to its right
      if (dy[i - 1] > threshold && dy[i] < -threshold && y[i] > minHeight)
      {
        peaks.push(i);
      }
    }

    return peaks;
  }

  /**
    Returns the sum of all the elements of a given array.

    This function tries to minimize floating-point precision errors.
  **/
  public static function sum(array:Array<Float>):Float
  {
    // Neumaier's "improved Kahan-Babuska algorithm":

    var sum = 0.0;
    var c = 0.0; // running compensation for lost precision

    for (v in array)
    {
      var t = sum + v;
      c += Math.abs(sum) >= Math.abs(v) ? (sum - t) + v // sum is bigger => low-order digits of v are lost
        : (v - t) + sum; // v is bigger => low-order digits of sum are lost
      sum = t;
    }

    return sum + c; // correction only applied at the very end
  }

  /**
    Returns the average value of an array.
  **/
  public static function mean(y:Array<Float>):Float
    return sum(y) / y.length;

  /**
    Returns the global maximum.
  **/
  public static function max(y:Array<Float>):Float
    return y.fold(Math.max, y[0]);

  /**
    Returns the global maximum's index.
  **/
  public static function maxi(y:Array<Float>):Int
    return y.foldi((yi, m, i) -> yi > y[m] ? i : m, 0);

  /**
    Returns the global minimum.
  **/
  public static function min(y:Array<Float>):Float
    return y.fold(Math.min, y[0]);

  /**
    Returns the global minimum's index.
  **/
  public static function mini(y:Array<Float>):Int
    return y.foldi((yi, m, i) -> yi < y[m] ? i : m, 0);
}
