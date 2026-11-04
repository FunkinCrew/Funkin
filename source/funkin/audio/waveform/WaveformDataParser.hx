package funkin.audio.waveform;

@:nullSafety
class WaveformDataParser
{
  @:native('int16_max')
  static final INT16_MAX:Int = 32767;
  @:native('int16_min')
  static final INT16_MIN:Int = -32768;
  @:native('int8_max')
  static final INT8_MAX:Int = 127;
  @:native('int8_min')
  static final INT8_MIN:Int = -128;

  public static function interpretFlxSound(sound:Null<flixel.sound.FlxSound>, samplesPerPoint:Int = 256, mono:Bool = false):Null<WaveformData>
  {
    if (sound == null) return null;

    // Method 1. This only works if the sound has been played before.
    @:privateAccess
    var soundBuffer:Null<lime.media.AudioBuffer> = sound?._source?.buffer;

    if (soundBuffer == null)
    {
      trace('[WAVEFORM] Failed to interpret FlxSound: ${sound}');
      return null;
    }

    return interpretAudioBuffer(soundBuffer, samplesPerPoint, mono);
  }

  /**
   * @param samplesPerPoint How many audio samples each data point covers.
   * @param mono Merge every channel into one, which halves the memory for stereo audio.
   */
  public static function interpretAudioBuffer(soundBuffer:lime.media.AudioBuffer, samplesPerPoint:Int = 256, mono:Bool = false):Null<WaveformData>
  {
    var inputChannels = soundBuffer.channels;
    var channels = mono ? 1 : inputChannels;
    var bitsPerSample = soundBuffer.bitsPerSample;

    // TODO: Make this work better on HTML5.
    var soundData:lime.utils.Int16Array = cast soundBuffer.data;

    // Lime decodes 16 bit audio into an Int16Array, so its length is already in samples and not bytes.
    var soundDataSampleCount:Int = Std.int(Math.ceil(soundData.length / inputChannels));
    var outputPointCount:Int = Std.int(Math.ceil(soundDataSampleCount / samplesPerPoint));

    // Pre-allocate Vector with exact final size for better performance and memory efficiency
    var outputDataLength:Int = outputPointCount * channels * 2;
    var outputData = new haxe.ds.Vector<Int>(outputDataLength);

    // Reusable min/max tracking arrays to avoid allocation in the loop
    var minValues = new haxe.ds.Vector<Int>(channels);
    var maxValues = new haxe.ds.Vector<Int>(channels);

    for (pointIndex in 0...outputPointCount)
    {
      var rangeStart:Int = pointIndex * samplesPerPoint;
      var rangeEnd:Int = Std.int(Math.min(rangeStart + samplesPerPoint, soundDataSampleCount));

      // Reset min/max values for this range
      for (i in 0...channels)
      {
        minValues[i] = bitsPerSample == 16 ? INT16_MAX : INT8_MAX;
        maxValues[i] = bitsPerSample == 16 ? INT16_MIN : INT8_MIN;
      }

      // Process all samples in this range
      for (sampleIndex in rangeStart...rangeEnd)
      {
        for (channelIndex in 0...inputChannels)
        {
          var sampleValue:Int = soundData[sampleIndex * inputChannels + channelIndex];
          var outputChannel:Int = mono ? 0 : channelIndex;

          if (sampleValue < minValues[outputChannel]) minValues[outputChannel] = sampleValue;
          if (sampleValue > maxValues[outputChannel]) maxValues[outputChannel] = sampleValue;
        }
      }

      // Write directly to final positions in output Vector
      var baseIndex:Int = pointIndex * channels * 2;
      for (channelIndex in 0...channels)
      {
        outputData[baseIndex + channelIndex * 2] = minValues[channelIndex];
        outputData[baseIndex + channelIndex * 2 + 1] = maxValues[channelIndex];
      }
    }

    var result = new WaveformData(null, channels, soundBuffer.sampleRate, samplesPerPoint, bitsPerSample, outputPointCount, outputData.toArray());

    return result;
  }

  /**
   * Filters the audio buffer with a high pass or low pass filter before interpreting it as waveform data.
   * https://www.w3.org/TR/audio-eq-cookbook/
   * https://github.com/uvcat7/ArrowVortex/blob/5b63ff72ac8e6ef6af12801ebe042acdc479324f/src/Editor/Waveform.cpp#L37-L99 (thanks arrow vortex)
   *
   * @param highPass `true` for a high pass filter, `false` for a low pass filter.
   * @param cutoffHz The filter's cutoff frequency, in Hz.
   */
  public static function interpretAudioBufferFiltered(soundBuffer:lime.media.AudioBuffer, samplesPerPoint:Int, highPass:Bool, cutoffHz:Float):Null<WaveformData>
  {
    var channels:Int = soundBuffer.channels;
    var bitsPerSample:Int = soundBuffer.bitsPerSample;
    var sampleRate:Int = soundBuffer.sampleRate;
    var soundData:lime.utils.Int16Array = cast soundBuffer.data;

    var sampleCount:Int = Std.int(soundData.length / channels);
    var outputPointCount:Int = Std.int(Math.ceil(sampleCount / samplesPerPoint));
    var outputData = new haxe.ds.Vector<Int>(outputPointCount * 2);

    var w0:Float = 2 * Math.PI * Math.min(cutoffHz, sampleRate * 0.45) / sampleRate;
    var cosW0:Float = Math.cos(w0);

    var q:Float = 0.7071067811865476;
    var alpha:Float = Math.sin(w0) / (2 * q);
    var a0:Float = 1 + alpha;
    var b0:Float = (highPass ? (1 + cosW0) : (1 - cosW0)) / 2 / a0;
    var b1:Float = (highPass ? -(1 + cosW0) : (1 - cosW0)) / a0;
    var b2:Float = b0;
    var a1:Float = -2 * cosW0 / a0;
    var a2:Float = (1 - alpha) / a0;

    var x1:Float = 0;
    var x2:Float = 0;
    var y1:Float = 0;
    var y2:Float = 0;

    var maxValue:Int = bitsPerSample == 16 ? INT16_MAX : INT8_MAX;
    var minValue:Int = bitsPerSample == 16 ? INT16_MIN : INT8_MIN;

    for (pointIndex in 0...outputPointCount)
    {
      var rangeStart:Int = pointIndex * samplesPerPoint;
      var rangeEnd:Int = Std.int(Math.min(rangeStart + samplesPerPoint, sampleCount));

      var low:Float = maxValue;
      var high:Float = minValue;

      for (sampleIndex in rangeStart...rangeEnd)
      {
        // Mix the channels down to mono before filtering.
        var x0:Float = 0;
        for (channelIndex in 0...channels)
          x0 += soundData[sampleIndex * channels + channelIndex];
        x0 /= channels;

        var y0:Float = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
        x2 = x1;
        x1 = x0;
        y2 = y1;
        y1 = y0;

        if (y0 < low) low = y0;
        if (y0 > high) high = y0;
      }

      outputData[pointIndex * 2] = Std.int(Math.max(minValue, low));
      outputData[pointIndex * 2 + 1] = Std.int(Math.min(maxValue, high));
    }

    return new WaveformData(null, 1, sampleRate, samplesPerPoint, bitsPerSample, outputPointCount, outputData.toArray());
  }

  public static function parseWaveformData(path:String):Null<WaveformData>
  {
    var rawJson:String = openfl.Assets.getText(path).trim();
    return parseWaveformDataString(rawJson, path);
  }

  public static function parseWaveformDataString(contents:String, ?fileName:String):Null<WaveformData>
  {
    var parser = new json2object.JsonParser<WaveformData>({
      ignoreUnknownVariables: false
    });
    trace('[WAVEFORM] Parsing waveform data: ${fileName ?? 'unknown'} (${contents.length} characters)');
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }

  static function printErrors(errors:Array<json2object.Error>, id:String = ''):Void
  {
    trace('[WAVEFORM] Failed to parse waveform data: ${id}');

    for (error in errors)
    {
      funkin.data.DataError.printError(error);
    }
  }
}
