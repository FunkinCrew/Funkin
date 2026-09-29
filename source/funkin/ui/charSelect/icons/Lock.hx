package funkin.ui.charSelect.icons;

import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;

/**
 * The lock icon that takes the place of a locked character in the Character Select screen.
 */
@:nullSafety
class Lock extends FunkinSprite
{
  /**
   * All of the colors that the lock icon can be.
   */
  public static final AVAILABLE_COLORS:Array<FlxColor> = [
    0xFF31F2A5, 0xFF20ECCD, 0xFF24D9E8,
    0xFF20ECCD, 0xFF20C8D4, 0xFF209BDD,
    0xFF209BDD, 0xFF2362C9, 0xFF243FB9
  ];

  public function new(x:Float = 0, y:Float = 0, index:Int)
  {
    var cycle:Int = AVAILABLE_COLORS.length * 2;
    var wrapped:Int = index % cycle;
    var colorIndex:Int = wrapped;

    if (wrapped >= AVAILABLE_COLORS.length)
    {
      colorIndex = cycle - wrapped - 1;
    }

    var tint:FlxColor = AVAILABLE_COLORS[colorIndex];

    super(x, y);

    loadTextureAtlas('ui/character-select/interface/lock', {
      swfMode: true,
      useRenderTexture: true,
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
