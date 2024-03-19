package funkin.audio.visualize;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import funkin.audio.visualize.PolygonSpectogram.VISTYPE;
import funkin.audio.visualize.VisShit.CurAudioInfo;
import funkin.audio.visualize.dsp.FFT;
import lime.system.ThreadPool;
import lime.utils.Int16Array;

using Lambda;
using flixel.util.FlxSpriteUtil;

class SpectogramSprite extends FlxTypedSpriteGroup<FlxSprite>
{
  var sampleRate:Int;

  var lengthOfShit:Int = 500;

  public var visType:VISTYPE = UPDATED;

  public var col:Int = FlxColor.WHITE;
  public var daHeight:Float = FlxG.height;

  public var vis:VisShit;

  public function new(daSound:FlxSound, ?col:FlxColor = FlxColor.WHITE, ?height:Float = 720, ?amnt:Int = 500)
  {
    super();

    vis = new VisShit(daSound);
    this.col = col;
    this.daHeight = height;
    lengthOfShit = amnt;

    regenLineShit();

    // makeGraphic(200, 200, FlxColor.BLACK);
  }

  public function regenLineShit():Void
  {
    for (i in 0...lengthOfShit)
    {
      var lineShit:FlxSprite = new FlxSprite(100, i / lengthOfShit * daHeight).makeGraphic(1, 1, col);
      lineShit.active = false;
      lineShit.ID = i;
      add(lineShit);
    }
  }

  var setBuffer:Bool = false;

  public var audioData:Int16Array;

  var numSamples:Int = 0;

  public var wavOptimiz:Int = 10;

  override function update(elapsed:Float)
  {
    switch (visType)
    {
      case UPDATED:
        updateVisulizer();

      case FREQUENCIES:
        updateFFT();
      default:
    }

    forEach(spr -> {
      spr.visible = spr.ID % wavOptimiz == 0;
    });

    // if visType is static, call updateVisulizer() manually whenever you want to update it!

    super.update(elapsed);
  }

  /**
   * @param start is the start in milliseconds?
   */
  public function generateSection(start:Float = 0, seconds:Float = 1):Void
  {
    checkAndSetBuffer();

    // vis.checkAndSetBuffer();

    if (setBuffer)
    {
      var samplesToGen:Int = Std.int(sampleRate * seconds);
      var startingSample:Int = Std.int(FlxMath.remapToRange(start, 0, vis.snd.length, 0, numSamples));

      var prevLine:FlxPoint = new FlxPoint();

      for (i in 0...group.members.length)
      {
        var sampleApprox:Int = Std.int(FlxMath.remapToRange(i, 0, group.members.length, startingSample, startingSample + samplesToGen));
        var curAud:CurAudioInfo = VisShit.getCurAud(audioData, sampleApprox);

        var swagheight:Int = 200;

        group.members[i].x = prevLine.x;
        group.members[i].y = prevLine.y;

        prevLine.x = (curAud.balanced * swagheight / 2 + swagheight / 2) + x;
        prevLine.y = (i / group.members.length * daHeight) + y;

        var line = FlxPoint.get(prevLine.x - group.members[i].x, prevLine.y - group.members[i].y);

        group.members[i].setGraphicSize(Std.int(Math.max(line.length, 1)), Std.int(1));
        group.members[i].angle = line.degrees;
      }

      wavOptimiz = 1; // hard set wavOptimiz to 1 so its a pure thing
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

  var doAnim:Bool = false;
  var frameCounter:Int = 0;

  public function updateFFT()
  {
    if (vis.snd != null)
    {
      var remappedShit:Int = 0;

      checkAndSetBuffer();

      if (!doAnim)
      {
        frameCounter++;

        if (frameCounter >= 0)
        {
          frameCounter = 0;
          doAnim = true;
        }
      }

      if (setBuffer && doAnim)
      {
        doAnim = false;

        if (vis.snd.playing) remappedShit = Std.int(FlxMath.remapToRange(vis.snd.time, 0, vis.snd.length, 0, numSamples));
        else
          remappedShit = Std.int(FlxMath.remapToRange(Conductor.instance.songPosition, 0, vis.snd.length, 0, numSamples));

        var fftSamples:Array<Float> = [];
        var i = remappedShit;

        for (sample in remappedShit...remappedShit + (Std.int((44100 * (1 / 144)))))
        {
          var curAud:CurAudioInfo = VisShit.getCurAud(audioData, i);
          i += 2;

          fftSamples.push(curAud.balanced);
        }

        var freqShit = vis.funnyFFT(fftSamples);
        var prevLine:FlxPoint = new FlxPoint();
        var swagheight:Int = 200;

        for (i in 0...group.members.length)
        {
          // needs to be exponential growth / scaling
          // still need to optmize the FFT to run better, gets only samples needed?
          // not every frequency is built the same!
          // 20hz to 40z is a LOT of subtle low ends, but somethin like 20,000hz to 20,020hz, the difference is NOT the same!

          var powedShit:Float = FlxMath.remapToRange(i, 0, group.members.length, 0, 4);

          // a value between 10hz and 100Khz
          var hzPicker:Float = Math.pow(10, powedShit);

          // var sampleApprox:Int = Std.int(FlxMath.remapToRange(i, 0, group.members.length, startingSample, startingSample + samplesToGen));
          var remappedFreq:Int = Std.int(FlxMath.remapToRange(hzPicker, 0, 10000, 0, freqShit[0].length - 1));

          group.members[i].x = prevLine.x;
          group.members[i].y = prevLine.y;

          var freqPower:Float = 0;

          for (pow in 0...freqShit.length)
            freqPower += freqShit[pow][remappedFreq];

          freqPower /= freqShit.length;
          var freqIDK:Float = FlxMath.remapToRange(freqPower, 0, 0.000005, 0, 50);

          prevLine.x = (freqIDK * swagheight / 2 + swagheight / 2) + x;
          prevLine.y = (i / group.members.length * daHeight) + y;

          var line = FlxPoint.get(prevLine.x - group.members[i].x, prevLine.y - group.members[i].y);

          // dont draw a line until i figure out a nicer way to view da spikes and shit idk lol!
          // group.members[i].setGraphicSize(Std.int(Math.max(line.length, 1)), Std.int(1));
          // group.members[i].angle = line.degrees;
        }
      }
    }
  }

  var curTime:Float = 0;

  public function updateVisulizer():Void
  {
    if (vis.snd != null)
    {
      var remappedShit:Int = 0;

      checkAndSetBuffer();

      if (setBuffer)
      {
        if (vis.snd.playing) remappedShit = Std.int(FlxMath.remapToRange(vis.snd.time, 0, vis.snd.length, 0, numSamples));
        else
        {
          if (curTime == Conductor.instance.songPosition)
          {
            wavOptimiz = 3;
            return; // already did shit, so finishes function early
          }

          curTime = Conductor.instance.songPosition;

          remappedShit = Std.int(FlxMath.remapToRange(Conductor.instance.songPosition, 0, vis.snd.length, 0, numSamples));
        }

        wavOptimiz = 8;

        var i = remappedShit;
        var prevLine:FlxPoint = new FlxPoint();

        var swagheight:Int = 200;

        for (sample in remappedShit...remappedShit + lengthOfShit)
        {
          var curAud:CurAudioInfo = VisShit.getCurAud(audioData, i);

          i += 2;

          var remappedSample:Float = FlxMath.remapToRange(sample, remappedShit, remappedShit + lengthOfShit, 0, lengthOfShit - 1);

          group.members[Std.int(remappedSample)].x = prevLine.x;
          group.members[Std.int(remappedSample)].y = prevLine.y;
          // group.members[0].y = prevLine.y;

          // FlxSpriteUtil.drawLine(this, prevLine.x, prevLine.y, width * remappedSample, left * height / 2 + height / 2);
          prevLine.x = (curAud.balanced * swagheight / 2 + swagheight / 2) + x;
          prevLine.y = (Std.int(remappedSample) / lengthOfShit * daHeight) + y;

          var line = FlxPoint.get(prevLine.x - group.members[Std.int(remappedSample)].x, prevLine.y - group.members[Std.int(remappedSample)].y);

          group.members[Std.int(remappedSample)].setGraphicSize(Std.int(Math.max(line.length, 1)), Std.int(1));
          group.members[Std.int(remappedSample)].angle = line.degrees;
        }
      }
    }
  }
}
