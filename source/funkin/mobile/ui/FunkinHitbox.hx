package funkin.mobile.ui;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.input.actions.FlxActionInput;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import funkin.graphics.shaders.HSVShader;
import funkin.mobile.input.ControlsHandler;
import funkin.mobile.ui.FunkinButton;
import funkin.play.notes.NoteSprite;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;

/**
 * The `FunkinHint` class represents a button with HSV color properties, allowing hue and saturation adjustments.
 */
class FunkinHint extends FunkinButton
{
  /**
   * The alpha value when the hint is pressed.
   */
  static final HINT_ALPHA_DOWN:Float = 0.3;

  /**
   * The alpha value when the hint is not pressed.
   */
  static final HINT_ALPHA_UP:Float = 0.00001;

  /**
   * The HSV shader used to adjust the hue and saturation of the button.
   */
  var hsvShader:HSVShader;

  /**
   * The tween used to animate the alpha changes of the button.
   */
  var alphaTween:FlxTween;

  /**
   * Creates a new `FunkinHint` object.
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

  /**
   * Initializes alpha tween animations for the button.
   *
   * Sets up handlers for `onDown`, `onUp`, and `onOut` events to modify the button's
   * `alpha` property using tweens. Cancels any existing tween when an event occurs
   * and creates a new tween to transition the `alpha` property accordingly:
   * - `onDown`: Transitions `alpha` to `HINT_ALPHA_DOWN`.
   * - `onUp` and `onOut`: Transitions `alpha` to `HINT_ALPHA_UP`.
   *
   * Uses `FlxEase.circInOut` easing for smooth transitions.
   */
  public function initAlphaTween():Void
  {
    onDown.add(function():Void {
      if (alphaTween != null) alphaTween.cancel();

      alphaTween = FlxTween.tween(this, {alpha: HINT_ALPHA_DOWN}, HINT_ALPHA_UP, {ease: FlxEase.circInOut});
    });
    onUp.add(function():Void {
      if (alphaTween != null) alphaTween.cancel();

      alphaTween = FlxTween.tween(this, {alpha: HINT_ALPHA_UP}, HINT_ALPHA_DOWN, {ease: FlxEase.circInOut});
    });
    onOut.add(function():Void {
      if (alphaTween != null) alphaTween.cancel();

      alphaTween = FlxTween.tween(this, {alpha: HINT_ALPHA_UP}, HINT_ALPHA_DOWN, {ease: FlxEase.circInOut});
    });

    alpha = HINT_ALPHA_UP;
  }

  /**
   * Desaturates the button, setting its saturation to 0.2.
   */
  public function desaturate():Void
  {
    hsvShader.saturation = 0.2;
  }

  /**
   * Sets the hue of the button.
   *
   * @param hue The new hue value.
   */
  public function setHue(hue:Float):Void
  {
    hsvShader.hue = hue;
  }

  /**
   * Cleans up memory used by the `FunkinHint`.
   */
  public override function destroy():Void
  {
    super.destroy();

    if (alphaTween != null)
      alphaTween = FlxDestroyUtil.destroy(alphaTween);
  }
}

/**
 * The `FunkinHitbox` class represents a zone with four buttons, designed to be easily customizable in layout.
 * It extends `FlxTypedSpriteGroup` with `FunkinHint` as the type parameter.
 */
class FunkinHitbox extends FlxTypedSpriteGroup<FunkinHint>
{
  /**
   * The array containing the hitbox's buttons.
   */
  public var hints(default, null):Array<FunkinHint> = [];

  /**
   * A `FlxTypedSignal` that triggers every time a button is pressed.
   */
  public var onHintDown:FlxTypedSignal<FunkinHint->Void> = new FlxTypedSignal<FunkinHint->Void>();

  /**
   * A `FlxTypedSignal` that triggers every time a button is released.
   */
  public var onHintUp:FlxTypedSignal<FunkinHint->Void> = new FlxTypedSignal<FunkinHint->Void>();

  /**
   * The list of tracked inputs for the hitbox.
   */
  private var trackedInputs:Array<FlxActionInput> = [];

  /**
   * Creates a new `FunkinHitbox` object.
   */
  @:access(funkin.play.notes.NoteSprite)
  public function new():Void
  {
    super();

    final hintsColors:Array<FlxColor> = [0xFFC34B9A, 0xFF00FFFF, 0xFF12FB06, 0xFFF9393F];
    final hintWidth:Int = Math.floor(FlxG.width / NoteSprite.DIRECTION_COLORS.length);
    final hintHeight:Int = FlxG.height;

    for (i in 0...NoteSprite.DIRECTION_COLORS.length)
    {
      var hint:FunkinHint = createHint(i * hintWidth, 0, hintWidth, hintHeight, i, hintsColors[i]);
      hints[hint.ID] = hint;
      add(hint);
    }

    scrollFactor.set();

    ControlsHandler.setupHitbox(PlayerSettings.player1.controls, this, trackedInputs);
  }

  /**
   * Creates a new `FunkinHint` button with specified properties.
   *
   * @param x The x position of the button.
   * @param y The y position of the button.
   * @param width The width of the button.
   * @param height The height of the button.
   * @param id The ID of the button.
   * @param color The color of the button.
   * @return A new `FunkinHint` object.
   */
  private function createHint(x:Float, y:Float, width:Int, height:Int, id:Int, color:FlxColor = 0xFFFFFFFF):FunkinHint
  {
    var hint:FunkinHint = new FunkinHint(x, y);
    hint.loadGraphic(createHintGraphic(width, height, color));
    hint.onDown.add(() -> onHintDown.dispatch(hint));
    hint.onUp.add(() -> onHintUp.dispatch(hint));
    hint.onOut.add(() -> onHintUp.dispatch(hint));
    hint.initAlphaTween();
    hint.ID = id;
    return hint;
  }

  /**
   * Creates a graphic for a hint button.
   *
   * @param width The width of the graphic.
   * @param height The height of the graphic.
   * @param baseColor The base color of the graphic.
   * @return A `FlxGraphic` object representing the button graphic.
   */
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
   * Cleans up memory used by the `FunkinHitbox`.
   */
  public override function destroy():Void
  {
    if (trackedInputs != null && trackedInputs.length > 0) ControlsHandler.removeCachedInput(PlayerSettings.player1.controls, trackedInputs);

    super.destroy();

    hints = FlxDestroyUtil.destroyArray(hints);
  }
}
