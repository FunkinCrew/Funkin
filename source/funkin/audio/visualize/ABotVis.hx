package funkin.audio.visualize;

import funkin.audio.visualize.dsp.FFT;
import flixel.FlxSprite;
import flixel.addons.plugin.taskManager.FlxTask;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import funkin.util.MathUtil;
import funkin.vis.dsp.SpectralAnalyzer;
import funkin.vis.audioclip.frontends.LimeAudioClip;

using Lambda;

class ABotVis extends FlxTypedSpriteGroup<FlxSprite>
{
  // public var vis:VisShit;
  var analyzer:SpectralAnalyzer;

  var volumes:Array<Float> = [];

  public var snd:FlxSound;

  public function new(snd:FlxSound)
  {
    super();

    this.snd = snd;

    // vis = new VisShit(snd);
    // vis.snd = snd;

    var visFrms:FlxAtlasFrames = Paths.getSparrowAtlas('aBotViz');

    // these are the differences in X position, from left to right
    var positionX:Array<Float> = [0, 59, 56, 66, 54, 52, 51];
    var positionY:Array<Float> = [0, -8, -3.5, -0.4, 0.5, 4.7, 7];

    for (lol in 1...8)
    {
      // pushes initial value
      volumes.push(0.0);
      var sum = function(num:Float, total:Float) return total += num;
      var posX:Float = positionX.slice(0, lol).fold(sum, 0);
      var posY:Float = positionY.slice(0, lol).fold(sum, 0);

      var viz:FlxSprite = new FlxSprite(posX, posY);
      viz.frames = visFrms;
      add(viz);

      var visStr = 'viz';
      viz.animation.addByPrefix('VIZ', visStr + lol, 0);
      viz.animation.play('VIZ', false, false, 6);
    }
  }

  public function initAnalyzer()
  {
    @:privateAccess
    analyzer = new SpectralAnalyzer(7, new LimeAudioClip(cast snd._channel.__source), 0.01, 30);
    analyzer.maxDb = -35;
    // analyzer.fftN = 2048;
  }

  var visTimer:Float = -1;
  var visTimeMax:Float = 1 / 30;

  override function update(elapsed:Float)
  {
    // updateViz();

    // updateFFT(elapsed);

    //
    super.update(elapsed);
  }

  static inline function min(x:Int, y:Int):Int
  {
    return x > y ? y : x;
  }

  override function draw()
  {
    #if web
    if (analyzer != null) drawFFT();
    #end
    super.draw();
  }

  /**
   * TJW funkin.vis based visualizer! updateFFT() is the old nasty shit that dont worky!
   */
  function drawFFT():Void
  {
    var levels = analyzer.getLevels(false);

    for (i in 0...min(group.members.length, levels.length))
    {
      var animFrame:Int = Math.round(levels[i].value * 5);

      animFrame = Math.floor(Math.min(5, animFrame));
      animFrame = Math.floor(Math.max(0, animFrame));

      animFrame = Std.int(Math.abs(animFrame - 5)); // shitty dumbass flip, cuz dave got da shit backwards lol!

      group.members[i].animation.curAnim.curFrame = animFrame;
    }
  }

  // function updateFFT(elapsed:Float)
  // {
  //   if (vis.snd != null)
  //   {
  //     vis.checkAndSetBuffer();
  //     if (vis.setBuffer)
  //     {
  //       var remappedShit:Int = 0;
  //       if (vis.snd.playing) remappedShit = Std.int(FlxMath.remapToRange(vis.snd.time, 0, vis.snd.length, 0, vis.numSamples));
  //       else
  //         remappedShit = Std.int(FlxMath.remapToRange(Conductor.instance.songPosition, 0, vis.snd.length, 0, vis.numSamples));
  //       var fftSamples:Array<Float> = [];
  //       var swagBucks = remappedShit;
  //       for (i in remappedShit...remappedShit + (Std.int((44100 * (1 / 144)))))
  //       {
  //         var left = vis.audioData[swagBucks] / 32767;
  //         var right = vis.audioData[swagBucks + 1] / 32767;
  //         var balanced = (left + right) / 2;
  //         swagBucks += 2;
  //         fftSamples.push(balanced);
  //       }
  //       var freqShit = vis.funnyFFT(fftSamples);
  //       for (i in 0...group.members.length)
  //       {
  //         var getSliceShit = function(s:Int) {
  //           var powShit = FlxMath.remapToRange(s, 0, group.members.length, 0, MathUtil.logBase(10, freqShit[0].length));
  //           return Math.round(Math.pow(10, powShit));
  //         };
  //         // var powShit:Float = getSliceShit(i);
  //         var hzSliced:Int = getSliceShit(i);
  //         var sliceLength:Int = Std.int(freqShit[0].length / group.members.length);
  //         var volSlice = freqShit[0].slice(hzSliced, getSliceShit(i + 1));
  //         var avgVel:Float = 0;
  //         for (slice in volSlice)
  //         {
  //           avgVel += slice;
  //         }
  //         avgVel /= volSlice.length;
  //         avgVel *= 10000000;
  //         volumes[i] += avgVel - (elapsed * (volumes[i] * 50));
  //         var animFrame:Int = Std.int(volumes[i]);
  //         animFrame = Math.floor(Math.min(5, animFrame));
  //         animFrame = Math.floor(Math.max(0, animFrame));
  //         animFrame = Std.int(Math.abs(animFrame - 5)); // shitty dumbass flip, cuz dave got da shit backwards lol!
  //         group.members[i].animation.curAnim.curFrame = animFrame;
  //         if (FlxG.keys.justPressed.U)
  //         {
  //           trace(avgVel);
  //           trace(group.members[i].animation.curAnim.curFrame);
  //         }
  //       }
  //       // group.members[0].animation.curAnim.curFrame =
  //     }
  //   }
  // }
  // public function updateViz()
  // {
  //   if (vis.snd != null)
  //   {
  //     var remappedShit:Int = 0;
  //     vis.checkAndSetBuffer();
  //     if (vis.setBuffer)
  //     {
  //       // var startingSample:Int = Std.int(FlxMath.remapToRange)
  //       if (vis.snd.playing) remappedShit = Std.int(FlxMath.remapToRange(vis.snd.time, 0, vis.snd.length, 0, vis.numSamples));
  //       for (i in 0...group.members.length)
  //       {
  //         var sampleApprox:Int = Std.int(FlxMath.remapToRange(i, 0, group.members.length, remappedShit, remappedShit + 500));
  //         var left = vis.audioData[sampleApprox] / 32767;
  //         var animFrame:Int = Std.int(FlxMath.remapToRange(left, -1, 1, 0, 6));
  //         group.members[i].animation.curAnim.curFrame = animFrame;
  //       }
  //     }
  //   }
  // }
}
