package funkin.audio.visualize;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import funkin.audio.visualize.VisShit;
import funkin.graphics.rendering.MeshRender;
import lime.utils.Int16Array;

class PolygonSpectogram extends MeshRender
{
  var sampleRate:Int;

  public var vis:VisShit;
  public var visType:VISTYPE = UPDATED;
  public var daHeight:Float = FlxG.height;
  public var realtimeVisLenght:Float = 0.2;
  public var realtimeStartOffset:Float = 0;

  var numSamples:Int = 0;
  var setBuffer:Bool = false;

  public var audioData:Int16Array;
  public var detail:Float = 1;

  public var thickness:Float = 2;
  public var waveAmplitude:Int = 100;

  public function new(?daSound:FlxSound, ?col:FlxColor = FlxColor.WHITE, ?height:Float = 720, ?detail:Float = 1)
  {
    super(0, 0, col);

    if (daSound != null) setSound(daSound);

    if (height != null) this.daHeight = height;

    this.detail = detail;

    // col not in yet
  }

  public function setSound(daSound:FlxSound)
  {
    vis = new VisShit(daSound);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    switch (visType)
    {
      case UPDATED:
        realtimeVis();
      default:
    }
  }

  var prevAudioData:Int16Array;

  /**
   * Generates and draws a section of the audio data to a visual waveform
   * @param start start of the song in milliseconds
   * @param seconds how long to generate (also in milliseconds)
   */
  public function generateSection(start:Float = 0, seconds:Float = 1):Void
  {
    checkAndSetBuffer();

    if (setBuffer)
    {
      clear();

      start = Math.max(start, 0);

      // gets how many samples to generate
      var samplesToGen:Int = Std.int(sampleRate * seconds);

      if (samplesToGen == 0) return;
      // gets which sample to start at
      var startSample:Int = Std.int(FlxMath.remapToRange(start, 0, vis.snd.length, 0, numSamples));

      // Check if startSample and samplesToGen are within the bounds of the audioData array
      if (startSample < 0 || startSample >= numSamples) return;
      if (samplesToGen <= 0 || startSample + samplesToGen > numSamples) samplesToGen = numSamples - startSample;

      var prevPoint:FlxPoint = new FlxPoint();

      var funnyPixels:Int = Std.int(daHeight * detail); // sorta redundant but just need it for different var...

      if (prevAudioData == audioData.subarray(startSample, startSample + samplesToGen)) return; // optimize / finish funciton here, no need to re-render

      prevAudioData = audioData.subarray(startSample, samplesToGen);

      for (i in 0...funnyPixels)
      {
        var sampleApprox:Int = Std.int(FlxMath.remapToRange(i, 0, funnyPixels, startSample, startSample + samplesToGen));
        var curAud:CurAudioInfo = VisShit.getCurAud(audioData, sampleApprox);

        var coolPoint:FlxPoint = new FlxPoint();
        coolPoint.x = (curAud.balanced * waveAmplitude);
        coolPoint.y = (i / funnyPixels * daHeight);

        build_quad(prevPoint.x, prevPoint.y, prevPoint.x
          + thickness, prevPoint.y, coolPoint.x, coolPoint.y, coolPoint.x
          + thickness, coolPoint.y
          + thickness);

        prevPoint.x = coolPoint.x;
        prevPoint.y = coolPoint.y;
      }
    }
  }

  var curTime:Float = 0;

  function realtimeVis():Void
  {
    if (vis.snd != null)
    {
      if (curTime != vis.snd.time)
      {
        // trace("DOIN SHIT" + FlxG.random.int(0, 200));

        if (vis.snd.playing) curTime = vis.snd.time;
        else
        {
          if (Math.abs(curTime - vis.snd.time) > 10) curTime = FlxMath.lerp(curTime, vis.snd.time, 0.5);
        }

        curTime = vis.snd.time;

        if (vis.snd.time < vis.snd.length - realtimeVisLenght) generateSection(vis.snd.time + realtimeStartOffset, realtimeVisLenght);
      }
    }
  }

  public function checkAndSetBuffer()
  {
    vis.checkAndSetBuffer();

    if (vis.setBuffer)
    {
      audioData = vis.audioData;
      sampleRate = vis.sampleRate;
      setBuffer = vis.setBuffer;
      numSamples = Std.int(audioData.length / 2);
    }
  }
}

enum VISTYPE
{
  STATIC;
  UPDATED;
  FREQUENCIES;
}
