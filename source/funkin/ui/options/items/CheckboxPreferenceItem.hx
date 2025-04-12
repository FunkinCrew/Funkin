package funkin.ui.options.items;

import flixel.FlxSprite.FlxSprite;

class CheckboxPreferenceItem extends FlxSprite
{
  public var currentValue(default, set):Bool;
  public var onChange:Null<Bool->Void>;

  public function new(x:Float, y:Float, defaultValue:Bool = false, ?onChange:Bool->Void)
  {
    super(x, y);

    frames = Paths.getSparrowAtlas('checkboxThingie');
    animation.addByPrefix('static', 'Check Box unselected', 24, false);
    animation.addByPrefix('checked', 'Check Box selecting animation', 24, false);

    setGraphicSize(Std.int(width * 0.7));
    updateHitbox();

    this.currentValue = defaultValue;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    switch (animation.curAnim.name)
    {
      case 'static':
        offset.set(10, 25);
      case 'checked':
        offset.set(27, 93);
    }
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

    if (onChange != null)
    {
      onChange(value);
    }

    return currentValue = value;
  }
}
