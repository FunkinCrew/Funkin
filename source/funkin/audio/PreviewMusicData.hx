package funkin.audio;

import haxe.io.Bytes;
import lime._internal.format.Base64;
import lime.media.AudioBuffer;
import openfl.utils.Assets;
import flixel.sound.FlxSoundData;
import flixel.tweens.FlxEase;

#if native
import sys.thread.Mutex;

import haxe.Int64;
import lime.media.AudioDecoder;
import lime.utils.ArrayBuffer;
import lime.utils.ArrayBufferView;
import lime.utils.ArrayBufferView.ArrayBufferIO;
import lime.utils.Int8Array;
import lime.utils.Int16Array;
#elseif web
import js.html.audio.AudioBuffer as JSAudioBuffer;
import lime.utils.Float32Array;
import funkin.util.flixel.sound.FlxPartialSound;
#end

class PreviewMusicData extends FlxSoundData
{
  /**
   * For the audio preview, the duration of the fade-in effect.
   */
  public static final FADE_IN_DURATION:Float = 2.0;

  /**
   * For the audio preview, the duration of the fade-out effect.
   */
  public static final FADE_OUT_DURATION:Float = 2.0;

  /**
   * For the audio preview, what easing function to use for fading of the fade-in effect.
   */
  public static final FADE_IN_EASE_FUNCTION:EaseFunction = FlxEase.quadOut;

  /**
   * For the audio preview, what easing function to use for fading of the fade-out effect.
   */
  public static final FADE_OUT_EASE_FUNCTION:EaseFunction = FlxEase.quadIn;

  #if native
  var audioBufferProcess:AudioBuffer;
  var audioDecoderProcess:PreviewMusicDecoder;
  #end

  public function new()
  {
    super('PreviewMusicData', null, true);

    #if native
    audioBufferProcess = new AudioBuffer();
    audioBufferProcess.decoder = audioDecoderProcess = new PreviewMusicDecoder(this);
    #end
  }

  public function setAssetPath(path:String, startPercentage:Float = 0, endPercentage:Float = 0.15, ?stream:Bool, ?onLoad:PreviewMusicData->Void):Void
  {
    var cacheName = 'PreviewMusicData-$path-$startPercentage-$endPercentage';

    var cache = FlxG.sound.getCache(cacheName);
    if (cache != null)
    {
      buffer = cache.buffer;
      if (onLoad != null) onLoad(this);
      return;
    }

    #if native
    final openflAssetExists = Assets.exists(path);
    var decoder = AudioDecoder.fromFile(openflAssetExists ? Assets.getPath(path) : path);
    if (decoder == null)
    {
      if (!openflAssetExists) return;

      decoder = AudioDecoder.fromBytes(Assets.getBytes(path));
      if (decoder == null) return;
    }

    final total = decoder.total();
    final duration = (total.high * 4294967296.0 + total.low) / decoder.sampleRate * 1000.0;
    final startTime = startPercentage * duration;
    final endTime = endPercentage * duration;

    audioDecoderProcess.resetDecoder(decoder, startTime, endTime);

    if (stream == null) stream = FlxSoundData.allowStreaming && (endTime - startTime) >= FlxSoundData.streamMinimumLength;
    if (stream && decoder.seekable())
    {
      audioBufferProcess.bitsPerSample = audioDecoderProcess.bitsPerSample;
      audioBufferProcess.channels = audioDecoderProcess.channels;
      audioBufferProcess.sampleRate = audioDecoderProcess.sampleRate;
      buffer = audioBufferProcess;

      if (onLoad != null) onLoad(this);
    }
    else
    {
      var cache = FlxSoundData.fromAudioBuffer(buffer = new AudioBuffer(), cacheName, true);
      buffer.decoder = audioDecoderProcess;

      buffer.loadAsync((_) -> {
        buffer.decoder = null;

        // Reset the buffer in the sound datas.
        buffer = buffer;
        cache.buffer = buffer;

        // DEBUG TESTING THE AUDIO.
        // var output = sys.io.File.write("../../../../tempPartial.wav", true);
        // output.writeString("RIFF");
        // output.writeInt32(36 + buffer.data.byteLength);
        // output.writeString("WAVE"); // 4
        // output.writeString("fmt "); // 4 + 4
        // output.writeInt32(16); // 8 + 4
        // output.writeUInt16(1); // 12 + 2
        // output.writeUInt16(buffer.channels); // 14 + 2
        // output.writeInt32(buffer.sampleRate); // 16 + 4
        // output.writeInt32(buffer.sampleRate * buffer.channels * (buffer.bitsPerSample >> 3)); // 20 + 4
        // output.writeUInt16(buffer.channels * (buffer.bitsPerSample >> 3)); // 24 + 2
        // output.writeUInt16(buffer.bitsPerSample); // 26 + 2
        // output.writeString("data"); // 28 + 4
        // output.writeInt32(buffer.data.byteLength); // 32 + 4 = 36
        // output.write(buffer.data.buffer);
        // output.close();

        if (onLoad != null) onLoad(this);
      });
    }
    #elseif web
    // apparently we have to split the path from the library? according to FunkinSound.loadPartial
    var promise = FlxPartialSound.partialLoadFromFile(Paths.stripLibrary(path), startPercentage, endPercentage);
    if (promise == null) return;

    @:privateAccess
    var soundData = FlxSoundData.createSoundData(null, cacheName, true);
    soundData.persist = true; // make it persist, or partialLoadFromFile will fail in next clearCache cycle.

    promise.future.onComplete(function(partialSound)
    @:privateAccess {
      soundData.buffer = buffer = partialSound.__buffer;
      if (buffer.__srcAudioBuffer != null)
      {
        processFading(buffer.__srcAudioBuffer);
        onLoad(this);
      }
      else
      {
        buffer.loadAsync((_) -> {
          if (buffer.__srcAudioBuffer != null) processFading(buffer.__srcAudioBuffer);
          onLoad(this);
        });
      }
    });
    #end
  }

  #if web
  private function processFading(buffer:JSAudioBuffer):Void
  {
    inline function processChannel(arr:Float32Array)
    {
      var n = Std.int(FADE_IN_DURATION * buffer.sampleRate);
      var step = 0;
      for (i in 0...n)
      {
        arr[i] = arr[i] * FADE_IN_EASE_FUNCTION(step / n);
        step++;
      }

      step = n = Std.int(FADE_OUT_DURATION * buffer.sampleRate);
      for (i in (arr.length - n)...arr.length)
      {
        arr[i] = arr[i] * FADE_OUT_EASE_FUNCTION(step / n);
        step--;
      }
    }

    processChannel(buffer.getChannelData(0));
    processChannel(buffer.getChannelData(1));
  }
  #end

  override function destroy():Void
  {
    #if native
    if (audioBufferProcess != null)
    {
      audioBufferProcess.dispose();
      audioBufferProcess = null;
    }
    #end
    buffer = null;
  }
}

#if native
@:access(lime.utils.ArrayBufferView)
private class PreviewMusicDecoder extends AudioDecoder
{
  public var parent:PreviewMusicData;
  public var decoder(default, null):AudioDecoder;

  var bytePerSample:Int;
  var startSamples:Int64;
  var endSamples:Int64;
  var totalSamples:Int64;
  var fadeStartSamples:Int64;
  var fadeEndSamples:Int64;
  var fadeEndStartSampleOffset:Int64;
  var fadeEndEndSampleOffset:Int64;
  var bufferInt8View:Int8Array;
  var bufferInt16View:Int16Array;
  var mutex:Mutex;

  public function new(parent:PreviewMusicData)
  {
    super();
    this.parent = parent;
    mutex = new Mutex();
  }

  public function resetDecoder(decoder:AudioDecoder, startTime:Float, endTime:Float):Void
  {
    mutex.acquire();

    var oldDecoder = this.decoder;
    if (oldDecoder != null) oldDecoder.dispose();
    
    this.decoder = decoder;
    if (decoder != null)
    {
      bitsPerSample = decoder.bitsPerSample;
      channels = decoder.channels;
      sampleRate = decoder.sampleRate;

      startSamples = Int64.fromFloat(startTime / 1000 * sampleRate);
      endSamples = Int64.fromFloat(endTime / 1000 * sampleRate);
      totalSamples = Int64.fromFloat((endTime - startTime) / 1000 * sampleRate);

      var realTotal = decoder.total();
      if (realTotal < totalSamples) totalSamples = realTotal;

      fadeStartSamples = Int64.fromFloat(PreviewMusicData.FADE_IN_DURATION * sampleRate);
      fadeEndEndSampleOffset = endSamples - startSamples;
      fadeEndSamples = Int64.fromFloat(PreviewMusicData.FADE_OUT_DURATION * sampleRate);
      fadeEndStartSampleOffset = fadeEndEndSampleOffset - fadeEndSamples;

      rewind();
    }

    mutex.release();
  }

  override function clone():PreviewMusicDecoder
  {
    return null;
  }

  override function dispose():Void
  {
    super.dispose();

    bufferInt16View = null;
    bufferInt8View = null;
  }

  override function decode(buffer:ArrayBuffer, pos:Int, len:Int, word:Int):Int
  {
    if (decoder == null) return 0;

    mutex.acquire();

    var currentSampleOffset = decoder.tell() - startSamples;
    var remainingBytes = (endSamples - currentSampleOffset) * channels * word;

    var result:Int;
    if (remainingBytes < len)
    {
      result = decoder.decode(buffer, pos, Int64.toInt(remainingBytes), word);
      eof = true;
    }
    else
    {
      result = decoder.decode(buffer, pos, len, word);
      eof = decoder.eof;
    }

    // 24 and 32 bits per sample are incompatible, and never get decoded with for playbacks.
    if (word > 2)
    {
      mutex.release();
      return result;
    }
    else if (word == 2)
    {
      if (bufferInt16View == null) bufferInt16View = new Int16Array(buffer);
      else if (bufferInt16View.buffer != buffer) bufferInt16View.initBuffer(buffer);
    }
    else if (word == 1)
    {
      if (bufferInt8View == null) bufferInt8View = new Int8Array(buffer);
      else if (bufferInt8View.buffer != buffer) bufferInt8View.initBuffer(buffer);
    }

    // Fading processing starts here
    pos = Std.int(pos / word);
    len = pos + Std.int(result / word);

    var channel = 0, b:Int;
    while (pos < len)
    {
      if (currentSampleOffset < fadeStartSamples)
      {
        switch (word)
        {
          case 1:
            bufferInt8View[pos] = Std.int(bufferInt8View[pos] *
              PreviewMusicData.FADE_IN_EASE_FUNCTION(currentSampleOffset.low / fadeStartSamples.low).clamp(0, 1));
          case 2:
            bufferInt16View[pos] = Std.int(bufferInt16View[pos] *
              PreviewMusicData.FADE_IN_EASE_FUNCTION(currentSampleOffset.low / fadeStartSamples.low).clamp(0, 1));
          default:
        }
      }
      else if (currentSampleOffset > fadeEndStartSampleOffset)
      {
        switch (word)
        {
          case 1:
            bufferInt8View[pos] = Std.int(bufferInt8View[pos] *
              PreviewMusicData.FADE_OUT_EASE_FUNCTION((fadeEndEndSampleOffset - currentSampleOffset).low / fadeEndSamples.low).clamp(0, 1));
          case 2:
            bufferInt16View[pos] = Std.int(bufferInt16View[pos] *
              PreviewMusicData.FADE_OUT_EASE_FUNCTION((fadeEndEndSampleOffset - currentSampleOffset).low / fadeEndSamples.low).clamp(0, 1));
          default:
        }
      }

      if (++channel == channels)
      {
        channel = 0;
        currentSampleOffset++;
      }
      pos++;
    }

    mutex.release();

    return result;
  }

  override function rewind():Bool
  {
    var result = startSamples == 0 ? decoder.rewind() : decoder.seek(startSamples);
    eof = decoder.eof;

    return result;
  }

  override function seek(samples:Int64):Bool
  {
    var result = decoder.seek(samples + startSamples);
    eof = decoder.eof;

    return result;
  }

  override function seekable():Bool
  {
    return true;
  }

  override function tell():Int64
  {
    return decoder.tell() - startSamples;
  }

  override function total():Int64
  {
    return totalSamples;
  }
}
#end
