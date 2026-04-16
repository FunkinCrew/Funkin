package funkin.graphics;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.FlxCamera;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;

/**
 * An FlxSkewedSprite that inherits the vcam positioning from FunkinSprite.
 **/
@:nullSafety
class FunkinSkewedSprite extends FlxSkewedSprite
{
  public var vcamPoint:Null<FlxPoint> = null;

  /**
   * Gets the screen position of the sprite, taking into account the camera scroll and the `vcamPoint` if it exists.
   * @param result An optional `FlxPoint` to store the result in. If null, a new `FlxPoint` will be created.
   * @param camera The camera to calculate the screen position relative to. If null, the default camera will be used.
   * @return The screen position of the sprite.
   **/
  override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
  {
    if (result == null) result = FlxPoint.get();
    if (camera == null) camera = getDefaultCamera();
    result.set(x, y);

    if (vcamPoint != null) return result.subtract((vcamPoint.x * scrollFactor.x) + camera.scroll.x, (vcamPoint.y * scrollFactor.y) + camera.scroll.y);

    return result.subtract(camera.scroll.x * scrollFactor.x, camera.scroll.y * scrollFactor.y);
  }
}
