package funkin.ui.options.items;

import funkin.graphics.FunkinSprite;

class CheckboxPreferenceItem extends FunkinSprite
{
  public var currentValue(default, set):Bool;

  public function new(x:Float, y:Float, defaultValue:Bool = false, available:Bool = true)
  {
    super(x, y);

    loadSparrow('checkboxThingie');
    animation.addByPrefix('static', 'Check Box unselected', 24, false);
    animation.addByPrefix('checked', 'Check Box selecting animation', 24, false);
    setAnimationOffsets('checked', 17, 70);

    setGraphicSize(Std.int(width * 0.7));
    updateHitbox();

    if (!available) this.alpha = 0.5;

    this.currentValue = defaultValue;
  }

  function set_currentValue(value:Bool):Bool
  {
    if (value)
    {
      animation.play('checked', true);
    }
    else
    {
      animation.play('static');
    }

    return currentValue = value;
  }
}
