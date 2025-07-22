package funkin.audio.waveform;

@:nullSafety
class WaveformData
{
  static final DEFAULT_VERSION:Int = 2;

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
  public var samplesPerPoint(default, null):Int = 256;

  /**
   * Number of bits to use for each sample value. Valid values are `8` and `16`.
   */
  public var bits(default, null):Int = 16;

  /**
   * The length of the data array, in points.
   */
  public var length(default, null):Int = 0;

  /**
   * Array of Int16 values representing the waveform.
   * TODO: Use an `openfl.Vector` for performance.
   */
  public var data(default, null):Array<Int> = [];

  @:jignored
  var channelData:Null<Array<WaveformDataChannel>> = null;

  public function new(?version:Int, channels:Int, sampleRate:Int, samplesPerPoint:Int, bits:Int, length:Int, data:Array<Int>)
  {
    this.version = version ?? DEFAULT_VERSION;
    this.channels = channels;
    this.sampleRate = sampleRate;
    this.samplesPerPoint = samplesPerPoint;
    this.bits = bits;
    this.length = length;
    this.data = data;
  }

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
    if (_maxSampleValue != 0) return _maxSampleValue;
    return _maxSampleValue = Std.int(Math.pow(2, bits));
  }

  /**
   * Cache the value because `Math.pow` is expensive and the value gets used a lot.
   */
  @:jignored
  var _maxSampleValue:Int = 0;

  /**
   * @return The length of the waveform in samples.
   */
  public function lenSamples():Int
  {
    return length * samplesPerPoint;
  }

  /**
   * @return The length of the waveform in seconds.
   */
  public function lenSeconds():Float
  {
    return inline lenSamples() / sampleRate;
  }

  /**
   * Given the time in seconds, return the waveform data point index.
   */
  public function secondsToIndex(seconds:Float):Int
  {
    return Std.int(seconds * inline pointsPerSecond());
  }

  /**
   * Given a waveform data point index, return the time in seconds.
   */
  public function indexToSeconds(index:Int):Float
  {
    return index / inline pointsPerSecond();
  }

  /**
   * The number of data points this waveform data provides per second of audio.
   */
  public inline function pointsPerSecond():Float
  {
    return sampleRate / samplesPerPoint;
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

  /**
   * Resample the waveform data to create a new WaveformData object matching the desired `samplesPerPoint` value.
   * This is useful for zooming in/out of the waveform in a performant manner.
   *
   * @param newSamplesPerPoint The new value for `samplesPerPoint`.
   */
  public function resample(newSamplesPerPoint:Int):WaveformData
  {
    var result = this.clone();

    var ratio = newSamplesPerPoint / samplesPerPoint;
    if (ratio == 1) return result;
    if (ratio < 1) trace('[WARNING] Downsampling will result in a low precision.');

    var inputSampleCount = this.lenSamples();
    var outputSampleCount = Std.int(inputSampleCount * ratio);

    var inputPointCount = this.length;
    var outputPointCount = Std.int(inputPointCount / ratio);
    var outputChannelCount = this.channels;

    // TODO: Actually figure out the dumbass logic for this.

    return result;
  }

  /**
   * Create a new WaveformData whose data represents the two waveforms overlayed.
   */
  public function merge(that:WaveformData):WaveformData
  {
    if (that == null) return this.clone();

    var result = this.clone([]);

    for (channelIndex in 0...this.channels)
    {
      var thisChannel = this.channel(channelIndex);
      var thatChannel = that.channel(channelIndex);
      var resultChannel = result.channel(channelIndex);

      for (index in 0...this.length)
      {
        var thisMinSample = thisChannel.minSample(index);
        var thatMinSample = thatChannel.minSample(index);

        var thisMaxSample = thisChannel.maxSample(index);
        var thatMaxSample = thatChannel.maxSample(index);

        resultChannel.setMinSample(index, Std.int(Math.min(thisMinSample, thatMinSample)));
        resultChannel.setMaxSample(index, Std.int(Math.max(thisMaxSample, thatMaxSample)));
      }
    }

    @:privateAccess
    result.length = this.length;

    return result;
  }

  /**
   * Create a new WaveformData whose parameters match the current object.
   */
  public function clone(?newData:Array<Int> = null):WaveformData
  {
    if (newData == null)
    {
      newData = this.data.clone();
    }

    var clone = new WaveformData(this.version, this.channels, this.sampleRate, this.samplesPerPoint, this.bits, newData.length, newData);

    return clone;
  }
}

@:nullSafety
class WaveformDataChannel
{
  var parent:WaveformData;
  var channelId:Int;

  public function new(parent:WaveformData, channelId:Int)
  {
    this.parent = parent;
    this.channelId = channelId;
  }

  /**
   * @param i Index
   * @return minimum point at an index.
   */
  public function minSample(i:Int):Int
  {
    var offset = (i * parent.channels + this.channelId) * 2;
    return inline parent.get(offset);
  }

  /**
   * Mapped to a value between 0 and 1.
   */
  public function minSampleMapped(i:Int)
  {
    return inline minSample(i) / inline parent.maxSampleValue();
  }

  /**
   * Minimum value within the range of samples.
   * NOTE: Inefficient for large ranges. Use `WaveformData.remap` instead.
   */
  public function minSampleRange(start:Int, end:Int)
  {
    var min = inline parent.maxSampleValue();
    for (i in start...end)
    {
      var sample = inline minSample(i);
      if (sample < min) min = sample;
    }
    return min;
  }

  /**
   * Maximum value within the range of samples, mapped to a value between 0 and 1.
   */
  public function minSampleRangeMapped(start:Int, end:Int)
  {
    return inline minSampleRange(start, end) / inline parent.maxSampleValue();
  }

  /**
   * Retrieve a given maximum point at an index.
   */
  public function maxSample(i:Int)
  {
    var offset = (i * parent.channels + this.channelId) * 2 + 1;
    return inline parent.get(offset);
  }

  /**
   * Mapped to a value between 0 and 1.
   */
  public function maxSampleMapped(i:Int)
  {
    return inline maxSample(i) / inline parent.maxSampleValue();
  }

  /**
   * Maximum value within the range of samples.
   * NOTE: Inefficient for large ranges. Use `WaveformData.remap` instead.
   */
  public function maxSampleRange(start:Int, end:Int)
  {
    var max = -(inline parent.maxSampleValue());
    for (i in start...end)
    {
      var sample = inline maxSample(i);
      if (sample > max) max = sample;
    }
    return max;
  }

  /**
   * Maximum value within the range of samples, mapped to a value between 0 and 1.
   */
  public function maxSampleRangeMapped(start:Int, end:Int)
  {
    return inline maxSampleRange(start, end) / inline parent.maxSampleValue();
  }

  public function setMinSample(i:Int, value:Int)
  {
    var offset = (i * parent.channels + this.channelId) * 2;
    inline parent.set(offset, value);
  }

  public function setMaxSample(i:Int, value:Int)
  {
    var offset = (i * parent.channels + this.channelId) * 2 + 1;
    inline parent.set(offset, value);
  }
}
