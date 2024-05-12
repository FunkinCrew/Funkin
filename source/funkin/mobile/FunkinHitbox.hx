package funkin.mobile;

import funkin.mobile.FunkinButton;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.FlxG;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;

/**
 * A zone with 4 buttons (A hitbox).
 * It's really easy to customize the layout.
 */
class FunkinHitbox extends FlxTypedSpriteGroup<FunkinButton>
{
  /**
   * The array containing the hitbox's buttons.
   */
  public var hints(default, null):Array<FunkinButton> = [];

  /**
   * Create the zone.
   *
   * @param ammo The ammount of buttons you want to create.
   * @param perHintWidth The width that the buttons will use.
   * @param perHintHeight The height that the buttons will use.
   * @param colors The color per button.
   */
  public function new(ammo:UInt, perHintWidth:Int, perHintHeight:Int, colors:Array<FlxColor>):Void
  {
    super();

    if (colors == null || colors.length < ammo) colors = [for (i in 0...ammo) 0xFFFFFFFF];

    for (i in 0...ammo)
      add(hints[i] = createHint(i * perHintWidth, 0, perHintWidth, perHintHeight, colors[i]));

    scrollFactor.set();
  }

  /**
   * Clean up memory.
   */
  override public function destroy():Void
  {
    super.destroy();

    hints = FlxDestroyUtil.destroyArray(hints);
  }

  private function createHint(x:Float, y:Float, width:Int, height:Int, color:FlxColor = 0xFFFFFFFF):FunkinButton
  {
    var hint:FunkinButton = new FunkinButton(x, y);
    hint.loadGraphic(createHintGraphic(width, height, color));
    hint.solid = false;
    hint.multiTouch = true;
    hint.immovable = true;
    hint.alpha = 0.00001;
    hint.onDown = hint.onOver = function():Void {
      if (hint.alpha != 0.2) hint.alpha = 0.2;
    }
    hint.onUp = hint.onOut = function():Void {
      if (hint.alpha != 0.00001) hint.alpha = 0.00001;
    }
    #if FLX_DEBUG
    hint.ignoreDrawDebug = true;
    #end
    return hint;
  }

  private function createHintGraphic(width:Int, height:Int, baseColor:FlxColor = 0xFFFFFFFF):BitmapData
  {
    var shape:Shape = new Shape();

    // Back color rectangle
    var matrix = new Matrix();
    matrix.createGradientBox(width - 12, height - 12, 0, 0, 0);
    shape.graphics.beginGradientFill(RADIAL, [baseColor, baseColor], [0, 0.6], [60, 255], matrix, PAD, RGB, 0);
    shape.graphics.drawRect(6, 6, Width - 12, Height - 12);
    shape.graphics.endFill();

    // Outline
    shape.graphics.lineStyle(6, baseColor);
    shape.graphics.drawRect(0, 0, width, height);
    shape.graphics.endFill();

    var bitmap:BitmapData = new BitmapData(width, height, true, 0);
    bitmap.draw(shape, true); // Smoothed so it looks good
    return bitmap;
  }
}
