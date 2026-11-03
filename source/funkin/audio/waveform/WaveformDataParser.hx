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
