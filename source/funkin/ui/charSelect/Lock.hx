package funkin.ui.charSelect;

import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import flixel.FlxCamera;
import flixel.math.FlxPoint;

class Lock extends FunkinSprite
{
  var colors:Array<FlxColor> = [
    0xFF31F2A5, 0xFF20ECCD, 0xFF24D9E8,
    0xFF20ECCD, 0xFF20C8D4, 0xFF209BDD,
    0xFF209BDD, 0xFF2362C9, 0xFF243FB9
  ];

  public function new(x:Float = 0, y:Float = 0, index:Int, settings:AtlasSpriteSettings)
  {
    var tint:FlxColor = colors[index];

    super(x, y);

    loadTextureAtlas("charSelect/lock",
      {
        swfMode: settings.swfMode,
        cacheOnLoad: settings.cacheOnLoad,
        filterQuality: settings.filterQuality,
        uniqueInCache: settings.uniqueInCache,
        onSymbolCreate: (symbol) -> {
          if (symbol.timeline.getLayer("color") != null)
          {
            var colorSymbol = symbol.timeline.getLayer("color").getFrameAtIndex(0).convertToSymbol(0, 1);
            colorSymbol.setColorTransform(0, 0, 0, 1, tint.red, tint.green, tint.blue, 0);
          }
        }
      });

    anim.play("idle");
  }

  /**
   * Offset the lock.
   */
  override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
  {
    var output:FlxPoint = super.getScreenPosition(result, camera);
    output.x -= 320;
    output.y -= 90;
    return output;
  }
}
