package funkin.mobile;

import funkin.mobile.FunkinButton;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import flixel.FlxG;
import openfl.display.Shape;
import openfl.display.BitmapData;
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
   * A `FlxTypedSignal` that triggers every time a button was pressed.
   */
  public var onHintDown:FlxTypedSignal<FunkinButton->Void> = new FlxTypedSignal<FunkinButton->Void>();

  /**
   * A `FlxTypedSignal` that triggers every time a button was released.
   */
  public var onHintUp:FlxTypedSignal<FunkinButton->Void> = new FlxTypedSignal<FunkinButton->Void>();

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
      add(hints[i] = createHint(i * perHintWidth, 0, perHintWidth, perHintHeight, i, colors[i]));

    scrollFactor.set();

    zIndex = 100000;
  }

  private function createHint(x:Float, y:Float, width:Int, height:Int, id:Int, color:FlxColor = 0xFFFFFFFF):FunkinButton
  {
    var hint:FunkinButton = new FunkinButton(x, y, DIRECTION_BUTTON);
    hint.loadGraphic(createHintGraphic(width, height, color));
    hint.alpha = 0.00001;
    hint.onDown.add(function():Void {
      onHintDown.dispatch(hint);

      if (hint.alpha != 0.25) hint.alpha = 0.25;
    });
    hint.onUp.add(function():Void {
      onHintUp.dispatch(hint);

      if (hint.alpha != 0.00001) hint.alpha = 0.00001;
    });
    hint.onOut.add(function():Void {
      onHintUp.dispatch(hint);

      if (hint.alpha != 0.00001) hint.alpha = 0.00001;
    });
    hint.ID = id;
    return hint;
  }

  private function createHintGraphic(width:Int, height:Int, baseColor:FlxColor = 0xFFFFFFFF):FlxGraphic
  {
    var matrix:Matrix = new Matrix();
    matrix.createGradientBox(width, height, 0, 0, 0);

    var shape:Shape = new Shape();
    shape.graphics.beginGradientFill(RADIAL, [baseColor, baseColor], [0, 1], [60, 255], matrix, PAD, RGB, 0);
    shape.graphics.drawRect(0, 0, width, height);
    shape.graphics.endFill();

    var graphicData:BitmapData = new BitmapData(width, height, true, 0);
    graphicData.draw(shape, true);
    return FlxGraphic.fromBitmapData(graphicData, false, null, false);
  }

  /**
   * Clean up memory.
   */
  override public function destroy():Void
  {
    super.destroy();

    hints = FlxDestroyUtil.destroyArray(hints);
  }
}
