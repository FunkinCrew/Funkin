package funkin.graphics;

import funkin.graphics.FunkinSprite;
import flixel.animation.FlxAnimationController;

/**
 * A version of `FlxAnimationController` that has custom offsets support.
 */
class FunkinAnimationController extends FlxAnimationController
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
   * We override `FlxAnimationController`'s `play` method to account for animation offsets.
   */
  public override function play(animName:String, force = false, reversed = false, frame = 0):Void
  {
    _parentSprite.applyAnimationOffsets(animName);
    super.play(animName, force, reversed, frame);
  }
}
