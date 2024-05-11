package funkin.mobile;

import funkin.util.tools.IntTools;
import funkin.mobile.FunkinButton;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.FlxG;
import openfl.display.BitmapData;
import openfl.display.GradientType;
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

    if (colors == null || colors.length < ammo) colors = [for (i in 0...ammo) 0xFFFFFF];

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

  private function createHint(x:Float, y:Float, width:Int, height:Int, color:Int = 0xFFFFFF):FunkinButton
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

  private function createHintGraphic(width:Int, height:Int, baseColor:Int = 0xFFFFFF):BitmapData
  {
    final darkerColor:Int = adjustColorBrightness(baseColor, -30);
    final lighterColor:Int = adjustColorBrightness(baseColor, 30);

    var gradientMatrix:Matrix = new Matrix();
    gradientMatrix.createGradientBox(width, height, 0, 0, 0);

    var shape:Shape = new Shape();

    shape.graphics.beginGradientFill(GradientType.LINEAR, [darkerColor, baseColor, lighterColor], [0, 1, 0], [0, 128, 255], gradientMatrix);
    shape.graphics.drawRect(0, 0, width, height);
    shape.graphics.endFill();

    shape.graphics.lineStyle(2, baseColor);
    shape.graphics.drawRect(0, 0, width - 1, height - 1);
    shape.graphics.endFill();

    var bitmap:BitmapData = new BitmapData(width, height, true, 0);
    bitmap.draw(shape, true);
    return bitmap;
  }

  private function adjustColorBrightness(color:Int, delta:Int):Int
  {
    var r:Int = (color >> 16) & 0xFF;
    var g:Int = (color >> 8) & 0xFF;
    var b:Int = color & 0xFF;

    r = IntTools.clamp(r + delta, 0, 255);
    g = IntTools.clamp(g + delta, 0, 255);
    b = IntTools.clamp(b + delta, 0, 255);

    return (r << 16) | (g << 8) | b;
  }
}
