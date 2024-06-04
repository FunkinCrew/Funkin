package funkin.mobile;

import flixel.input.actions.FlxActionInput;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import flixel.FlxG;
import funkin.graphics.shaders.HSVShader;
import funkin.mobile.ControlsHandler;
import funkin.mobile.FunkinButton;
import funkin.play.notes.NoteSprite;
import openfl.display.Shape;
import openfl.display.BitmapData;
import openfl.geom.Matrix;

/**
 * This class mainly exist just for the hints to be able to use the hsvs shader like the notes.
 */
class FunkinHint extends FunkinButton
{
  var hsvShader:HSVShader;

  /**
   * Creates a new `FunkinButton` object.
   *
   * @param X The x position of the button.
   * @param Y The y position of the button.
   */
  public function new(X:Float = 0, Y:Float = 0):Void
  {
    super(X, Y);

    hsvShader = new HSVShader();
    hsvShader.hue = 1.0;
    hsvShader.saturation = 1.0;
    hsvShader.value = 1.0;

    shader = hsvShader;
  }

  public function desaturate():Void
  {
    this.hsvShader.saturation = 0.2;
  }

  public function setHue(hue:Float):Void
  {
    this.hsvShader.hue = hue;
  }
}

/**
 * A zone with 4 buttons (A hitbox).
 *
 * It's really easy to customize the layout.
 */
class FunkinHitbox extends FlxTypedSpriteGroup<FunkinHint>
{
  /**
   * The array containing the hitbox's buttons.
   */
  public var hints(default, null):Array<FunkinHint> = [];

  /**
   * A `FlxTypedSignal` that triggers every time a button was pressed.
   */
  public var onHintDown:FlxTypedSignal<FunkinHint->Void> = new FlxTypedSignal<FunkinHint->Void>();

  /**
   * A `FlxTypedSignal` that triggers every time a button was released.
   */
  public var onHintUp:FlxTypedSignal<FunkinHint->Void> = new FlxTypedSignal<FunkinHint->Void>();

  var trackedInputs:Array<FlxActionInput> = [];

  /**
   * Create the zone.
   */
  @:access(funkin.play.notes.NoteSprite)
  public function new():Void
  {
    super();

    final hintsColors:Array<FlxColor> = [0xFFC34B9A, 0xFF00FFFF, 0xFF12FB06, 0xFFF9393F];
    final hintWidth:Int = Math.floor(FlxG.width / NoteSprite.DIRECTION_COLORS);
    final hintHeight:Int = FlxG.height;

    for (i in 0...NoteSprite.DIRECTION_COLORS)
    {
      var hint:FunkinHint = createHint(i * perHintWidth, 0, perHintWidth, perHintHeight, i, hintsColors[i]);
      hints[hint.ID] = hint;
      add(hint);
    }

    scrollFactor.set();

    zIndex = 100000;

    ControlsHandler.setupHitbox(PlayerSettings.player1.controls, this, trackedInputs);
  }

  private function createHint(x:Float, y:Float, width:Int, height:Int, id:Int, color:FlxColor = 0xFFFFFFFF):FunkinHint
  {
    var hint:FunkinHint = new FunkinHint(x, y);
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
    if (trackedInputs != null && trackedInputs.length > 0) ControlsHandler.removeCachedInput(PlayerSettings.player1.controls, trackedInputs);

    super.destroy();

    hints = FlxDestroyUtil.destroyArray(hints);
  }
}
