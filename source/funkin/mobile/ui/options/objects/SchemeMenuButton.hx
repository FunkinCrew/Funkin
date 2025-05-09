package funkin.mobile.ui.options.objects;

import flixel.addons.display.shapes.FlxShapeBox;
import flixel.effects.FlxFlicker;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSignal;
import flixel.util.FlxColor;
import funkin.util.TouchUtil;
import funkin.util.SwipeUtil;
import funkin.audio.FunkinSound;
import funkin.ui.AtlasText;

/**
 * Represents a button in the scheme menu, specifically designed for mobile touch input.
 * The button displays text and allows selection through touch or an external callback.
 */
class SchemeMenuButton extends FlxSpriteGroup
{
  /**
   * The visual body of the button.
   */
  public var body:Null<FlxShapeBox>;

  /**
   * The text displayed on the button.
   */
  public var text:Null<AtlasText>;

  /**
   * Signal dispatched when the button is selected. Additional behavior can be added by subscribing to this signal.
   */
  public var onSelect(default, null):FlxSignal = new FlxSignal();

  /**
   * Indicates if the button is currently processing a selection (to avoid multiple triggers).
   */
  public var busy:Bool = false;

  /**
   * Creates a new SchemeMenuButton instance.
   *
   * @param xPos The x position of the button.
   * @param yPos The y position of the button.
   * @param labelText The text displayed on the button.
   * @param onClick An optional callback function that will be triggered when the button is clicked.
   */
  public function new(?xPos:Float = 0, ?yPos:Float = 0, labelText:String, ?onClick:Void->Void):Void
  {
    super(xPos, yPos);

    body = new FlxShapeBox(0, 0, 200, 100, {thickness: 4, color: FlxColor.BLACK}, FlxColor.WHITE);
    add(body);

    text = new AtlasText(-150, -75, labelText, AtlasFont.DEFAULT);
    add(text);

    updateHitbox();

    if (onClick != null) onSelect.add(onClick);
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (!busy && (TouchUtil.pressAction(this) && !SwipeUtil.swipeAny))
    {
      busy = true;

      FunkinSound.playOnce(Paths.sound('confirmMenu'));

      FlxFlicker.flicker(this, 1, 0.06, true, false, function(_) {
        busy = false;
        onSelect.dispatch();
      });
    }
  }
}
