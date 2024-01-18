package funkin.graphics;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;

/**
 * An FlxSprite with additional functionality.
 */
class FunkinSprite extends FlxSprite
{
  /**
   * @param x Starting X position
   * @param y Starting Y position
   */
  public function new(?x:Float = 0, ?y:Float = 0)
  {
    super(x, y);
  }

  /**
   * Acts similarly to `makeGraphic`, but with improved memory usage,
   * at the expense of not being able to paint onto the sprite.
   *
   * @param width The target width of the sprite.
   * @param height The target height of the sprite.
   * @param color The color to fill the sprite with.
   */
  public function makeSolidColor(width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FunkinSprite
  {
    var graphic:FlxGraphic = FlxG.bitmap.create(2, 2, color, false, 'solid#${color.toHexString(true, false)}');
    frames = graphic.imageFrame;
    scale.set(width / 2, height / 2);
    updateHitbox();

    return this;
  }

  /**
   * Ensure scale is applied when cloning a sprite.
   * The default `clone()` method acts kinda weird TBH.
   * @return A clone of this sprite.
   */
  public override function clone():FunkinSprite
  {
    var result = new FunkinSprite(this.x, this.y);
    result.frames = this.frames;
    result.scale.set(this.scale.x, this.scale.y);
    result.updateHitbox();

    return result;
  }
}
