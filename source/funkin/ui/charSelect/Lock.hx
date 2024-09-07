package funkin.ui.charSelect;

import flixel.util.FlxColor;
import flxanimate.effects.FlxTint;
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
    super(x, y, Paths.animateAtlas("charSelect/lock"));

    var tint:FlxTint = new FlxTint(colors[index], 1);

    var arr:Array<String> = ["lock", "lock top 1", "lock top 2", "lock top 3", "lock base fuck it"];

    var func = function(name) {
      var symbol = anim.symbolDictionary[name];
      if (symbol != null && symbol.timeline.get("color") != null) symbol.timeline.get("color").get(0).colorEffect = tint;
    }
    for (symbol in arr)
    {
      func(symbol);
    }

    playAnimation("idle");
  }
}
