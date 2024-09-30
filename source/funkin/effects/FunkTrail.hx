package funkin.effects;

import flixel.addons.effects.FlxTrail;
import funkin.play.stage.Bopper;
import flixel.FlxSprite;
import flixel.system.FlxAssets;

/**
 * An offshoot of FlxTrail, but accomodates the way Funkin
 * does offsets for characters. example, fixes Spirits trail
 */
class FunkTrail extends FlxTrail
{
  /**
   * Creates a new FunkTrail effect for a specific FlxSprite.
   *
   * @param	Target		The FlxSprite the trail is attached to.
   * @param  	Graphic		The image to use for the trailsprites. Optional, uses the sprite's graphic if null.
   * @param	Length		The amount of trailsprites to create.
   * @param	Delay		How often to update the trail. 0 updates every frame.
   * @param	Alpha		The alpha value for the very first trailsprite.
   * @param	Diff		How much lower the alpha of the next trailsprite is.
   */
  public function new(Target:FlxSprite, ?Graphic:FlxGraphicAsset, Length:Int = 10, Delay:Int = 3, Alpha:Float = 0.4, Diff:Float = 0.05)
  {
    super(Target, Graphic, Length, Delay, Alpha, Diff);
  }

  override public function update(elapsed:Float):Void
  {
    if (target is Bopper)
    {
      var targ:Bopper = cast target;
      @:privateAccess effectOffset.set((targ.animOffsets[0] - targ.globalOffsets[0]) * targ.scale.x,
        (targ.animOffsets[1] - targ.globalOffsets[1]) * targ.scale.y);
    }

    super.update(elapsed);
  }
}
