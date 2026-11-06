package funkin.audio.visualize;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.sound.FlxSound;
import funkin.graphics.FunkinSprite;
import funkin.vis.dsp.Bar;
import funkin.vis.dsp.SpectralAnalyzer;

using Lambda;

@:nullSafety
class ABotVis extends FlxSpriteGroup
{
  static final BAR_COUNT:Int = 7;

  public var snd:Null<FlxSound> = null;

  var analyzer:Null<SpectralAnalyzer> = null;
  var analyzerCache:Array<Bar> = new Array<Bar>();
  var volumes:Array<Float> = [];

  public function new(snd:FlxSound, pixel:Bool):Void
  {
    super();

    this.snd = snd;

    var visCount = pixel ? (BAR_COUNT + 1) : (BAR_COUNT + 1);
    var visScale = pixel ? 6 : 1;

    var visFrms:FlxAtlasFrames = Paths.getSparrowAtlas(
      pixel ? 'gameplay/characters/nene-pixel/abot-pixel/abot-pixel-viz' : 'gameplay/characters/nene/abot-viz'
    );

    // these are the differences in X position, from left to right
    var positionX:Array<Float> = pixel ? [
      0,
      7 * 6,
      8 * 6,
      9 * 6,
      10 * 6,
      6 * 6,
      7 * 6
    ] : [
      0,
      59,
      56,
      66,
      54,
      52,
      51
      ];
    var positionY:Array<Float> = pixel ? [
      0,
      -2 * 6,
      -1 * 6,
      0,
      0,
      1 * 6,
      2 * 6
    ] : [
      0,
      -8,
      -3.5,
      -0.4,
      0.5,
      4.7,
      7
      ];

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

    if (analyzer != null) analyzer.dispose();

    @:privateAccess
    analyzer = new SpectralAnalyzer(snd._source, BAR_COUNT, 0.1, 40);
  }

  public function dumpSound():Void
  {
    snd = null;

    if (analyzer != null)
    {
      analyzer.dispose();
      analyzer = null;
    }
  }

  override function draw():Void
  {
    super.draw();

    analyzerCache = analyzer != null ? analyzer.getLevels(analyzerCache) : getDefaultLevels();

    for (i in 0...Std.int(Math.min(group.members.length, analyzerCache.length)))
    {
      var animFrame:Int = (FlxG.sound.volume == 0 || FlxG.sound.muted) ? 0 : Math.round(analyzerCache[i].value * 6);

      group.members[i].visible = animFrame > 0;

      animFrame -= 1;

      animFrame = Math.floor(Math.min(5, animFrame));
      animFrame = Math.floor(Math.max(0, animFrame));
      animFrame = Std.int(Math.abs(animFrame - 5));

      group.members[i].animation.curAnim.curFrame = animFrame;
    }
  }

  override function destroy():Void
  {
    if (analyzer != null)
    {
      analyzer.dispose();
      analyzer = null;
    }

    super.destroy();
  }

  static function getDefaultLevels():Array<Bar>
  {
    var result:Array<Bar> = [];

    for (i in 0...BAR_COUNT)
    {
      result.push({
        value: 0,
        peak: 0.0
      });
    }

    return result;
  }
}
