package funkin.ui.charSelect.icons;

import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import flixel.FlxCamera;
import flixel.math.FlxPoint;

@:nullSafety
class Lock extends FunkinSprite
{
  var colors:Array<FlxColor> = [
    0xFF31F2A5, 0xFF20ECCD, 0xFF24D9E8,
    0xFF20ECCD, 0xFF20C8D4, 0xFF209BDD,
    0xFF209BDD, 0xFF2362C9, 0xFF243FB9
  ];

  public function new(x:Float = 0, y:Float = 0, index:Int)
  {
    var cycle:Int = colors.length * 2;
    var wrapped:Int = index % cycle;
    var colorIndex:Int = wrapped;

    if (wrapped >= colors.length)
    {
      colorIndex = cycle - wrapped - 1;
    }

    var tint:FlxColor = colors[colorIndex];

    super(x, y);

    loadTextureAtlas('ui/character-select/interface/lock', {
      swfMode: true,
      cacheKey: 'char-select-lock-${tint.toHexString()}',
      onSymbolCreate: (symbol) ->
      {
        if (symbol.timeline.getLayer('color') != null)
        {
          var colorSymbol:Null<animate.internal.elements.SymbolInstance> = symbol.timeline.getLayer(
            'color'
          )?.getFrameAtIndex(0)?.convertToSymbol(0, 1) ?? null;

          if (colorSymbol != null)
          {
            colorSymbol.setColorTransform(0, 0, 0, 1, tint.red, tint.green, tint.blue, 0);
          }
        }
      }
    });

    loadAnimations();

    animation.play('idle');
    offset.set(230, 110);
  }

  function loadAnimations():Void
  {
    anim.addByFrameLabel('idle', 'idle', 24, false);
    anim.addByFrameLabel('selected', 'selected', 24, false);
    anim.addByFrameLabel('clicked', 'clicked', 24, false);
    anim.addByFrameLabel('unlock', 'unlock', 24, false);
  }
}
