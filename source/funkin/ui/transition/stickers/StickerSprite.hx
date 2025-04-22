package funkin.ui.transition.stickers;

import funkin.graphics.FunkinSprite;

class StickerSprite extends FunkinSprite
{
  public var timing:Float = 0;

  public function new(x:Float, y:Float, filePath:String):Void
  {
    super(x, y);
    loadTexture(filePath);
    updateHitbox();
    scrollFactor.set();
  }
}
