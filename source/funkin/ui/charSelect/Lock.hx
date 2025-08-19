package funkin.ui.charSelect;

import flixel.util.FlxColor;
import funkin.graphics.adobeanimate.FlxAtlasSprite;

class Lock extends FlxAtlasSprite
{
  var colors:Array<FlxColor> = [
    0xFF31F2A5, 0xFF20ECCD, 0xFF24D9E8,
    0xFF20ECCD, 0xFF20C8D4, 0xFF209BDD,
    0xFF209BDD, 0xFF2362C9, 0xFF243FB9
  ];

  public function new(x:Float = 0, y:Float = 0, index:Int)
  {
    super(x, y, Paths.animateAtlas("charSelect/lock"),
      {
        swfMode: true,
        cacheOnLoad: true,
        filterQuality: HIGH,
        uniqueInCache: true
      });

    var tint:FlxColor = colors[index];

    var arr:Array<String> = ["lock", "lock top 1", "lock top 2", "lock top 3", "lock base fuck it"];

    var func = function(name) {
      var symbol = library.getSymbol(name);
      if (symbol != null && symbol.timeline.getLayer("color") != null)
      {
        var colorSymbol = symbol.timeline.getLayer("color").getFrameAtIndex(0).convertToSymbol(0, 1);
        colorSymbol.setColorTransform(0, 0, 0, 1, tint.red, tint.green, tint.blue, 0);
      }
    }

    for (symbol in arr)
    {
      func(symbol);
    }

    playAnimation("idle");
  }
}
