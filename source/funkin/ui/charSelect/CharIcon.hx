package funkin.ui.charSelect;

import flixel.FlxSprite;

class CharIcon extends FlxSprite
{
  public var locked:Bool = false;

  public function new(x:Float, y:Float, locked:Bool = false)
  {
    super(x, y);

    this.locked = locked;

    makeGraphic(128, 128);
  }
}
