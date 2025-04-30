package funkin.effects;

import flixel.addons.effects.FlxTrail;
import funkin.play.stage.Bopper;
import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.math.FlxPoint;

/**
 * An offshoot of FlxTrail, but accomodates the way Funkin
 * does offsets for characters. example, fixes Spirits trail
 */
@:nullSafety
class FunkTrail extends FlxTrail
{
  /**
   * Creates a new FunkTrail effect for a specific FlxSprite.
   *
   * @param	target		The FlxSprite the trail is attached to.
   * @param graphic		The image to use for the trailsprites. Optional, uses the sprite's graphic if null.
   * @param	length		The amount of trailsprites to create.
   * @param	delay		How often to update the trail. 0 updates every frame.
   * @param	alpha		The alpha value for the very first trailsprite.
   * @param	diff		How much lower the alpha of the next trailsprite is.
   */
  public function new(target:FlxSprite, ?graphic:FlxGraphicAsset, length:Int = 10, delay:Int = 3, alpha:Float = 0.4, diff:Float = 0.05)
  {
    super(target, graphic, length, delay, alpha, diff);
  }

  /**
   * An offset applied to the target position whenever a new frame is saved.
   */
  public final frameOffset:FlxPoint = FlxPoint.get();

  override function destroy():Void
  {
    super.destroy();

    frameOffset.put();
  }

  override function addTrailFrame():Void
  {
    super.addTrailFrame();

    if (target is Bopper)
    {
      var targ:Bopper = cast target;
      @:privateAccess
      frameOffset.set((targ.animOffsets[0] - targ.globalOffsets[0]) * targ.scale.x, (targ.animOffsets[1] - targ.globalOffsets[1]) * targ.scale.y);

      _recentPositions[0]?.subtract(frameOffset.x, frameOffset.y);
    }
  }
}
