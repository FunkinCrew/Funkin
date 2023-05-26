package funkin.audiovis;

import funkin.audiovis.dsp.FFT;
import flixel.FlxSprite;
import flixel.addons.plugin.taskManager.FlxTask;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import funkin.ui.PreferencesMenu.CheckboxThingie;

using Lambda;

class ABotVis extends FlxTypedSpriteGroup<FlxSprite>
{
  public var vis:VisShit;

  var volumes:Array<Float> = [];

  public function new(snd:FlxSound)
  {
    super();

    vis = new VisShit(snd);
    // vis.snd = snd;

    var visFrms:FlxAtlasFrames = Paths.getSparrowAtlas('aBotViz');

    for (lol in 1...8)
    {
      // pushes initial value
      volumes.push(0.0);

      var viz:FlxSprite = new FlxSprite(50 * lol, 0);
      viz.frames = visFrms;
      add(viz);

      var visStr = 'VIZ';
      if (lol == 5) visStr = 'viz'; // lol makes it lowercase, accomodates for art that I dont wanna rename!

      viz.animation.addByPrefix('VIZ', visStr + lol, 0);
      viz.animation.play('VIZ', false, false, -1);
    }
  }

  override function update(elapsed:Float)
  {
    // updateViz();

    updateFFT(elapsed);

    super.update(elapsed);
  }

  function updateFFT(elapsed:Float)
  {
    if (vis.snd != null)
    {
      vis.checkAndSetBuffer();

      if (vis.setBuffer)
      {
        var remappedShit:Int = 0;

        if (vis.snd.playing) remappedShit = Std.int(FlxMath.remapToRange(vis.snd.time, 0, vis.snd.length, 0, vis.numSamples));
        else
          remappedShit = Std.int(FlxMath.remapToRange(Conductor.songPosition, 0, vis.snd.length, 0, vis.numSamples));

        var fftSamples:Array<Float> = [];

        var swagBucks = remappedShit;

        for (i in remappedShit...remappedShit + (Std.int((44100 * (1 / 144)))))
        {
          var left = vis.audioData[swagBucks] / 32767;
          var right = vis.audioData[swagBucks + 1] / 32767;

          var balanced = (left + right) / 2;

          swagBucks += 2;

          fftSamples.push(balanced);
        }

        var freqShit = vis.funnyFFT(fftSamples);

        for (i in 0...group.members.length)
        {
          var getSliceShit = function(s:Int) {
            var powShit = FlxMath.remapToRange(s, 0, group.members.length, 0, CoolUtil.coolBaseLog(10, freqShit[0].length));
            return Math.round(Math.pow(10, powShit));
          };

          // var powShit:Float = getSliceShit(i);
          var hzSliced:Int = getSliceShit(i);

          var sliceLength:Int = Std.int(freqShit[0].length / group.members.length);

          var volSlice = freqShit[0].slice(hzSliced, getSliceShit(i + 1));

          var avgVel:Float = 0;

          for (slice in volSlice)
          {
            avgVel += slice;
          }

          avgVel /= volSlice.length;

          avgVel *= 10000000;

          volumes[i] += avgVel - (elapsed * (volumes[i] * 50));

          var animFrame:Int = Std.int(volumes[i]);

          animFrame = Math.floor(Math.min(5, animFrame));
          animFrame = Math.floor(Math.max(0, animFrame));

          animFrame = Std.int(Math.abs(animFrame - 5)); // shitty dumbass flip, cuz dave got da shit backwards lol!

          group.members[i].animation.curAnim.curFrame = animFrame;
          if (FlxG.keys.justPressed.U)
          {
            trace(avgVel);
            trace(group.members[i].animation.curAnim.curFrame);
          }
        }

        // group.members[0].animation.curAnim.curFrame =
      }
    }
  }

  public function updateViz()
  {
    if (vis.snd != null)
    {
      var remappedShit:Int = 0;
      vis.checkAndSetBuffer();

      if (vis.setBuffer)
      {
        // var startingSample:Int = Std.int(FlxMath.remapToRange)

        if (vis.snd.playing) remappedShit = Std.int(FlxMath.remapToRange(vis.snd.time, 0, vis.snd.length, 0, vis.numSamples));

        for (i in 0...group.members.length)
        {
          var sampleApprox:Int = Std.int(FlxMath.remapToRange(i, 0, group.members.length, remappedShit, remappedShit + 500));

          var left = vis.audioData[sampleApprox] / 32767;

          var animFrame:Int = Std.int(FlxMath.remapToRange(left, -1, 1, 0, 6));

          group.members[i].animation.curAnim.curFrame = animFrame;
        }
      }
    }
  }
}
