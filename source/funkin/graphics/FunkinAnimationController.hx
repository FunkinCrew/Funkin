package funkin.graphics;

import funkin.graphics.FunkinSprite;
import animate.FlxAnimateController;

class FunkinAnimationController extends FlxAnimateController
{
  /**
   * The sprite that this animation controller is attached to.
   */
  var _parentSprite:FunkinSprite;

  public function new(sprite:FunkinSprite)
  {
    super(sprite);
    _parentSprite = sprite;
  }

  /**
   * We override `FlxAnimationController`'s `play` method to account for texture atlases.
   */
  public override function play(animName:String, force = false, reversed = false, frame = 0):Void
  {
    if (animName == null || animName == '') animName = _parentSprite.getDefaultSymbol();

    if (!_parentSprite.hasAnimation(animName))
    {
      // Skip if the animation doesn't exist
      trace('Animation ${animName} does not exist!');
      return;
    }

    super.play(animName, force, reversed, frame);
  }
}
