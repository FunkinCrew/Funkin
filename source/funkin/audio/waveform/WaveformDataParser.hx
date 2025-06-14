package funkin.audio.waveform;

import funkin.util.TimerUtil;
import haxe.ds.Vector;
import haxe.io.Bytes;

class WaveformDataParser
{
  static final INT16_MAX:Int = 32767;
  static final INT16_MIN:Int = -32768;

  static final INT8_MAX:Int = 127;
  static final INT8_MIN:Int = -128;

  public static function interpretFlxSound(sound:flixel.sound.FlxSound):Null<WaveformData>
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
    var sampleRate = soundBuffer.sampleRate;
    var channels = soundBuffer.channels;
    var bitsPerSample = soundBuffer.bitsPerSample;
    var samplesPerPoint:Int = 256; // I don't think we need to configure this.
    var pointsPerSecond:Float = sampleRate / samplesPerPoint; // 172 samples per second for most songs is plenty precise while still being performant..

    // TODO: Make this work better on HTML5.
    var soundData:Bytes = soundBuffer.data.toBytes();
    var fakeBitsPerSample:Int = bitsPerSample;
    var minSampleValue:Int;
    var maxSampleValue:Int;

    switch (bitsPerSample)
    {
      case 8:
        minSampleValue = INT8_MIN;
        maxSampleValue = INT8_MAX;
      case 16:
        minSampleValue = INT16_MIN;
        maxSampleValue = INT16_MAX;
      case 32:
        // We'll cheat by scaling the values to fit in a 16-bit range.
        minSampleValue = INT16_MIN;
        maxSampleValue = INT16_MAX;
        fakeBitsPerSample = 16;
      default:
        throw 'Unsupported bits per sample: $bitsPerSample';
    }

    var soundDataRawLength:Int = soundData.length;
    var soundDataSampleCount:Int = Math.ceil(soundDataRawLength / channels / (bitsPerSample / 8));
    var outputPointCount:Int = Math.ceil(soundDataSampleCount / samplesPerPoint);

    // trace('Interpreting audio buffer:');
    // trace('  sampleRate: ${sampleRate}');
    // trace('  channels: ${channels}');
    // trace('  bitsPerSample: ${bitsPerSample}');
    // trace('  samplesPerPoint: ${samplesPerPoint}');
    // trace('  pointsPerSecond: ${pointsPerSecond}');
    // trace('  soundDataRawLength: ${soundDataRawLength}');
    // trace('  soundDataSampleCount: ${soundDataSampleCount}');
    // trace('  soundDataRawLength/4: ${soundDataRawLength / 4}');
    // trace('  outputPointCount: ${outputPointCount}');

    var outputData:Vector<Int> = new Vector<Int>(outputPointCount * 2 * channels);

    var perfStart:Float = TimerUtil.start();

    // minChannel1, maxChannel1, minChannel2, maxChannel2, ...
    var values:Vector<Int> = new Vector<Int>(2 * channels);

    for (pointIndex in 0...outputPointCount)
    {
      for (i in 0...channels)
      {
        values[i * 2] = maxSampleValue;
        values[i * 2 + 1] = minSampleValue;
      }

      var rangeStart = pointIndex * samplesPerPoint;
      var rangeEnd = rangeStart + samplesPerPoint;
      if (rangeEnd > soundDataSampleCount) rangeEnd = soundDataSampleCount;

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

          if (sampleValue < values[channelIndex * 2]) values[(channelIndex * 2)] = sampleValue;
          if (sampleValue > values[channelIndex * 2 + 1]) values[(channelIndex * 2) + 1] = sampleValue;
        }
      }

      // We now have the min and max values for the range.
      Vector.blit(values, 0, outputData, pointIndex * values.length, values.length);
    }

    var outputDataLength:Int = Std.int(outputData.length / channels / 2);
    var result = new WaveformData(null, channels, sampleRate, samplesPerPoint, fakeBitsPerSample, outputPointCount, outputData.toArray());

    trace('[WAVEFORM] Interpreted audio buffer in ${TimerUtil.seconds(perfStart)}.');

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
