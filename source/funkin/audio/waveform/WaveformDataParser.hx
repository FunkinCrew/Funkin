package funkin.audio.waveform;

import funkin.util.TimerUtil;

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
    var soundBuffer:Null<lime.media.AudioBuffer> = sound?._channel?.__source?.buffer;

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
    var soundData:lime.utils.Int16Array = cast soundBuffer.data;

    var soundDataRawLength:Int = soundData.length;
    var soundDataSampleCount:Int = Std.int(Math.ceil(soundDataRawLength / channels / (bitsPerSample == 16 ? 2 : 1)));
    var outputPointCount:Int = Std.int(Math.ceil(soundDataSampleCount / samplesPerPoint));

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

    var minSampleValue:Int = bitsPerSample == 16 ? INT16_MIN : INT8_MIN;
    var maxSampleValue:Int = bitsPerSample == 16 ? INT16_MAX : INT8_MAX;

    var outputData:Array<Int> = [];

    var perfStart:Float = TimerUtil.start();

    for (pointIndex in 0...outputPointCount)
    {
      // minChannel1, maxChannel1, minChannel2, maxChannel2, ...
      var values:Array<Int> = [];

      for (i in 0...channels)
      {
        values.push(bitsPerSample == 16 ? INT16_MAX : INT8_MAX);
        values.push(bitsPerSample == 16 ? INT16_MIN : INT8_MIN);
      }

      var rangeStart = pointIndex * samplesPerPoint;
      var rangeEnd = rangeStart + samplesPerPoint;
      if (rangeEnd > soundDataSampleCount) rangeEnd = soundDataSampleCount;

      for (sampleIndex in rangeStart...rangeEnd)
      {
        for (channelIndex in 0...channels)
        {
          var sampleIndex:Int = sampleIndex * channels + channelIndex;
          var sampleValue = soundData[sampleIndex];

          if (sampleValue < values[channelIndex * 2]) values[(channelIndex * 2)] = sampleValue;
          if (sampleValue > values[channelIndex * 2 + 1]) values[(channelIndex * 2) + 1] = sampleValue;
        }
      }

      // We now have the min and max values for the range.
      for (value in values)
        outputData.push(value);
    }

    var outputDataLength:Int = Std.int(outputData.length / channels / 2);
    var result = new WaveformData(null, channels, sampleRate, samplesPerPoint, bitsPerSample, outputPointCount, outputData);

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
