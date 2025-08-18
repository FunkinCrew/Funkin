package funkin.ui.charSelect;

import flixel.util.FlxColor;
import funkin.graphics.adobeanimate.FlxAtlasSprite;

class Lock extends FlxAtlasSprite
{
  var colors:Array<FlxColor> = [
    0x31F2A5, 0x20ECCD, 0x24D9E8,
    0x20ECCD, 0x20C8D4, 0x209BDD,
    0x209BDD, 0x2362C9, 0x243FB9
  ]; // lock colors, in a nx3 matrix format

  public function new(x:Float = 0, y:Float = 0, index:Int)
  {
    super(x, y, Paths.animateAtlas("charSelect/lock"),
      {
        swfMode: true,
        cacheOnLoad: true,
        filterQuality: HIGH
      });

    var tint:FlxColor = colors[index];

    var arr:Array<String> = ["lock", "lock top 1", "lock top 2", "lock top 3", "lock base fuck it"];

    var func = function(name) {
      var color = FlxColor.fromInt(tint);
      var symbol = library.getSymbol(name);
      if (symbol != null && symbol.timeline.getLayer("color") != null)
      {
        var colorSymbol = symbol.timeline.getLayer("color").getFrameAtIndex(0).convertToSymbol(0, 0);

        @:privateAccess
        colorSymbol.transform.color = color;
      }
    }

    for (symbol in arr)
    {
      func(symbol);
    }

    playAnimation("idle");
  }
}
