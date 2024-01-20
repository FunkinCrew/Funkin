package funkin.audio.waveform;

import funkin.util.MathUtil;

@:nullSafety
class WaveformData
{
  /**
   * The version of the waveform data format.
   * @default `2` (-1 if not specified/invalid)
   */
  public var version(default, null):Int = -1;

  /**
   * The number of channels in the waveform.
   */
  public var channels(default, null):Int = 1;

  @:alias('sample_rate')
  public var sampleRate(default, null):Int = 44100;

  /**
   * Number of input audio samples per output waveform data point.
   * At base zoom level this is number of samples per pixel.
   * Lower values can more accurately represent the waveform when zoomed in, but take more data.
   */
  @:alias('samples_per_pixel')
  public var samplesPerPixel(default, null):Int = 256;

  /**
   * Number of bits to use for each sample value. Valid values are `8` and `16`.
   */
  public var bits(default, null):Int = 16;

  /**
   * Number of output waveform data points.
   */
  public var length(default, null):Int = 0; // Array size is (4 * length)

  /**
   * Array of Int16 values representing the waveform.
   * TODO: Use an `openfl.Vector` for performance.
   */
  public var data(default, null):Array<Int> = [];

  @:jignored
  var channelData:Null<Array<WaveformDataChannel>> = null;

  public function new() {}

  function buildChannelData():Array<WaveformDataChannel>
  {
    channelData = [];
    for (i in 0...channels)
    {
      channelData.push(new WaveformDataChannel(this, i));
    }
    return channelData;
  }

  public function channel(index:Int)
  {
    return (channelData == null) ? buildChannelData()[index] : channelData[index];
  }

  public function get(index:Int):Int
  {
    return data[index] ?? 0;
  }

  public function set(index:Int, value:Int)
  {
    data[index] = value;
  }

  /**
   * Maximum possible value for a waveform data point.
   * The minimum possible value is (-1 * maxSampleValue)
   */
  public function maxSampleValue():Int
  {
    if (_maxSampleValue != -1) return _maxSampleValue;
    return _maxSampleValue = Std.int(Math.pow(2, bits));
  }

  /**
   * Cache the value because `Math.pow` is expensive and the value gets used a lot.
   */
  @:jignored
  var _maxSampleValue:Int = -1;

  /**
   * @return The length of the waveform in samples.
   */
  public function lenSamples():Int
  {
    return length * samplesPerPixel;
  }

  /**
   * @return The length of the waveform in seconds.
   */
  public function lenSeconds():Float
  {
    return lenSamples() / sampleRate;
  }

  /**
   * Given the time in seconds, return the waveform data point index.
   */
  public function secondsToIndex(seconds:Float):Int
  {
    return Std.int(seconds * sampleRate / samplesPerPixel);
  }

  /**
   * Given a waveform data point index, return the time in seconds.
   */
  public function indexToSeconds(index:Int):Float
  {
    return index * samplesPerPixel / sampleRate;
  }

  /**
   * Given the percentage progress through the waveform, return the waveform data point index.
   */
  public function percentToIndex(percent:Float):Int
  {
    return Std.int(percent * length);
  }

  /**
   * Given a waveform data point index, return the percentage progress through the waveform.
   */
  public function indexToPercent(index:Int):Float
  {
    return index / length;
  }
}

class WaveformDataChannel
{
  var parent:WaveformData;
  var channelId:Int;

  public function new(parent:WaveformData, channelId:Int)
  {
    this.parent = parent;
    this.channelId = channelId;
  }

  public function minSample(i:Int)
  {
    var offset = (i * parent.channels + this.channelId) * 2;
    return parent.get(offset);
  }

  /**
   * Mapped to a value between 0 and 1.
   */
  public function minSampleMapped(i:Int)
  {
    return minSample(i) / parent.maxSampleValue();
  }

  /**
   * Minimum value within the range of samples.
   * @param i
   */
  public function minSampleRange(start:Int, end:Int)
  {
    var min = parent.maxSampleValue();
    for (i in start...end)
    {
      var sample = minSample(i);
      if (sample < min) min = sample;
    }
    return min;
  }

  /**
   * Maximum value within the range of samples, mapped to a value between 0 and 1.
   * @param i
   */
  public function minSampleRangeMapped(start:Int, end:Int)
  {
    return minSampleRange(start, end) / parent.maxSampleValue();
  }

  public function maxSample(i:Int)
  {
    var offset = (i * parent.channels + this.channelId) * 2 + 1;
    return parent.get(offset);
  }

  /**
   * Mapped to a value between 0 and 1.
   */
  public function maxSampleMapped(i:Int)
  {
    return maxSample(i) / parent.maxSampleValue();
  }

  /**
   * Maximum value within the range of samples.
   * @param i
   */
  public function maxSampleRange(start:Int, end:Int)
  {
    var max = -parent.maxSampleValue();
    for (i in start...end)
    {
      var sample = maxSample(i);
      if (sample > max) max = sample;
    }
    return max;
  }

  /**
   * Maximum value within the range of samples, mapped to a value between 0 and 1.
   * @param i
   */
  public function maxSampleRangeMapped(start:Int, end:Int)
  {
    return maxSampleRange(start, end) / parent.maxSampleValue();
  }

  /**
   * Maximum value within the range of samples, mapped to a value between 0 and 1.
   * @param i
   */
  public function setMinSample(i:Int, value:Int)
  {
    var offset = (i * parent.channels + this.channelId) * 2;
    parent.set(offset, value);
  }

  public function setMaxSample(i:Int, value:Int)
  {
    var offset = (i * parent.channels + this.channelId) * 2 + 1;
    parent.set(offset, value);
  }
}
