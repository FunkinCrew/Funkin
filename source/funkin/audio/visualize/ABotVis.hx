package funkin.audio.visualize;

import funkin.graphics.FunkinSprite;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.sound.FlxSound;
import funkin.vis.dsp.SpectralAnalyzer;

using Lambda;

@:nullSafety
class ABotVis extends FlxTypedSpriteGroup<FlxSprite>
{
  // public var vis:VisShit;
  var analyzer:Null<SpectralAnalyzer> = null;

  var volumes:Array<Float> = [];

  public var snd:Null<FlxSound> = null;

  static final BAR_COUNT:Int = 7;

  // TODO: Make the sprites easier to soft code.
  public function new(snd:FlxSound, pixel:Bool)
  {
    super();

    this.snd = snd;

    var visCount = pixel ? (BAR_COUNT + 1) : (BAR_COUNT + 1);
    var visScale = pixel ? 6 : 1;

    var visFrms:FlxAtlasFrames = Paths.getSparrowAtlas(pixel ? 'characters/abotPixel/aBotVizPixel' : 'characters/abot/aBotViz');

    // these are the differences in X position, from left to right
    var positionX:Array<Float> = pixel ? [0, 7 * 6, 8 * 6, 9 * 6, 10 * 6, 6 * 6, 7 * 6] : [0, 59, 56, 66, 54, 52, 51];
    var positionY:Array<Float> = pixel ? [0, -2 * 6, -1 * 6, 0, 0, 1 * 6, 2 * 6] : [0, -8, -3.5, -0.4, 0.5, 4.7, 7];

    for (index in 1...visCount)
    {
      // pushes initial value
      volumes.push(0.0);

      // Sum the offsets up to the current index
      var sum = function(num:Float, total:Float) return total += num;
      var posX:Float = positionX.slice(0, index).fold(sum, 0);
      var posY:Float = positionY.slice(0, index).fold(sum, 0);

      var viz:FunkinSprite = new FunkinSprite(posX, posY);
      viz.frames = visFrms;
      viz.antialiasing = pixel ? false : true;
      viz.scale.set(visScale, visScale);
      add(viz);

      var visStr = 'viz';
      viz.animation.addByPrefix('VIZ', '$visStr${index}0', 0);
      viz.animation.play('VIZ', false, false, 1);
    }
  }

  public function initAnalyzer():Void
  {
    if (snd == null) return;

    @:privateAccess
    analyzer = new SpectralAnalyzer(snd._channel.__audioSource, BAR_COUNT, 0.1, 40);
    // A-Bot tuning...
    analyzer.minDb = -65;
    analyzer.maxDb = -25;
    analyzer.maxFreq = 22000;
    // we use a very low minFreq since some songs use low low subbass like a boss
    analyzer.minFreq = 10;

    #if sys
    // On native it uses FFT stuff that isn't as optimized as the direct browser stuff we use on HTML5
    // So we want to manually change it!
    analyzer.fftN = 256;
    #end

    // analyzer.maxDb = -35;
    // analyzer.fftN = 2048;
  }

  public function dumpSound():Void
  {
    snd = null;
    analyzer = null;
  }

  var visTimer:Float = -1;
  var visTimeMax:Float = 1 / 30;

  override function update(elapsed:Float)
  {
    super.update(elapsed);
  }

  static inline function min(x:Int, y:Int):Int
  {
    return x > y ? y : x;
  }

  override function draw()
  {
    super.draw();
    drawFFT();
  }

  /**
   * TJW funkin.vis based visualizer! updateFFT() is the old nasty shit that dont worky!
   */
  function drawFFT():Void
  {
    var levels = (analyzer != null) ? analyzer.getLevels() : getDefaultLevels();

    for (i in 0...min(group.members.length, levels.length))
    {
      var animFrame:Int = (FlxG.sound.volume == 0 || FlxG.sound.muted) ? 0 : Math.round(levels[i].value * 6);

      // don't display if we're at 0 volume from the level
      group.members[i].visible = animFrame > 0;

      // decrement our animFrame, so we can get a value from 0-5 for animation frames
      animFrame -= 1;

      animFrame = Math.floor(Math.min(5, animFrame));
      animFrame = Math.floor(Math.max(0, animFrame));

      animFrame = Std.int(Math.abs(animFrame - 5)); // shitty dumbass flip, cuz dave got da shit backwards lol!

      group.members[i].animation.curAnim.curFrame = animFrame;
    }
  }

  /**
   * Explicitly define the default levels to draw when the analyzer is not available.
   * @return Array<Bar>
   */
  static function getDefaultLevels():Array<Bar>
  {
    var result:Array<Bar> = [];

    for (i in 0...BAR_COUNT)
    {
      result.push({value: 0, peak: 0.0});
    }

    return result;
  }
}
