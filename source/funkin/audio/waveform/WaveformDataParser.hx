package funkin.audio.waveform;

@:nullSafety
class WaveformDataParser
{
  static final INT16_MAX:Int = 32767;
  static final INT16_MIN:Int = -32768;

  static final INT8_MAX:Int = 127;
  static final INT8_MIN:Int = -128;

  public static function interpretFlxSound(sound:Null<flixel.sound.FlxSound>):Null<WaveformData>
  {
    if (sound == null) return null;

    // Method 1. This only works if the sound has been played before.
    @:privateAccess
    var soundBuffer:Null<lime.media.AudioBuffer> = sound?._channel?.__audioSource?.buffer;

    if (soundBuffer == null)
    {
      // Method 2. This works if the sound has not been played before.
      @:privateAccess
      soundBuffer = sound?._sound?.__buffer;

      if (soundBuffer == null)
      {
        trace('[WAVEFORM] Failed to interpret FlxSound: ${sound}');
        return null;
      }
      else
      {
        // trace('[WAVEFORM] Method 2 worked.');
      }
    }
    else
    {
      // trace('[WAVEFORM] Method 1 worked.');
    }

    return interpretAudioBuffer(soundBuffer);
  }

  public static function interpretAudioBuffer(soundBuffer:lime.media.AudioBuffer):Null<WaveformData>
  {
    var channels = soundBuffer.channels;
    var bitsPerSample = soundBuffer.bitsPerSample;
    var samplesPerPoint:Int = 256; // I don't think we need to configure this.

    // TODO: Make this work better on HTML5.
    var soundData:haxe.io.Bytes = soundBuffer.data.toBytes();
    var soundDataSampleCount:Int = Math.ceil(soundData.length / channels / (bitsPerSample / 8));
    var outputPointCount:Int = Math.ceil(soundDataSampleCount / samplesPerPoint);

    // Pre-allocate Vector with exact final size for better performance and memory efficiency
    var outputDataLength:Int = outputPointCount * channels * 2;
    var outputData = new haxe.ds.Vector<Int>(outputDataLength);

    // Reusable min/max tracking array to avoid allocation in the loop
    var values = new haxe.ds.Vector<Int>(channels * 2);

    for (pointIndex in 0...outputPointCount)
    {
      var rangeStart:Int = pointIndex * samplesPerPoint;
      var rangeEnd:Int = Std.int(Math.min(rangeStart + samplesPerPoint, soundDataSampleCount));

      // Reset min/max values for this range
      for (i in 0...channels)
      {
        values[i * 2] = bitsPerSample == 8 ? INT8_MAX : INT16_MAX;
        values[i * 2 + 1] = bitsPerSample == 8 ? INT8_MIN : INT16_MIN;
      }

      // Process all samples in this range
      for (sampleIndex in rangeStart...rangeEnd)
      {
        for (channelIndex in 0...channels)
        {
          var sampleIndex:Int = sampleIndex * channels + channelIndex;
          var sampleValue:Int = switch (bitsPerSample)
          {
            case 8:
              final byte = soundData.get(sampleIndex);
              (byte & 0x80) != 0 ? (byte | ~0xFF) : (byte & 0xFF);
            case 16:
              final word = soundData.getUInt16(sampleIndex * 2);
              (word & 0x8000) != 0 ? (word | ~0xFFFF) : (word & 0xFFFF);
            case 32:
              Std.int(soundData.getFloat(sampleIndex * 4) * INT16_MAX);
            default:
              0;
          }

          if (sampleValue < values[channelIndex * 2]) values[channelIndex * 2] = sampleValue;
          if (sampleValue > values[channelIndex * 2 + 1]) values[channelIndex * 2 + 1] = sampleValue;
        }
      }

      // Write directly to final positions in output Vector
      var baseIndex:Int = pointIndex * values.length;
      haxe.ds.Vector.blit(values, 0, outputData, baseIndex, values.length);
    }

    if (bitsPerSample == 32) bitsPerSample = 16;
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
    var parser = new json2object.JsonParser<WaveformData>();
    parser.ignoreUnknownVariables = false;
    trace('[WAVEFORM] Parsing waveform data: ${contents}');
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
      funkin.data.DataError.printError(error);
  }
}
