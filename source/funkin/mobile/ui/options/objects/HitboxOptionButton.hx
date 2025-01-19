package funkin.mobile.ui.options.objects;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.options.items.CheckboxPreferenceItem;
import funkin.ui.AtlasText.AtlasFont;
import funkin.graphics.FunkinCamera;

/**
 * Represents an option button for the hitbox showcase.
 */
class HitboxOptionButton extends FlxSpriteGroup
{
  /**
   * The button's checkbox member.
   * Indicates the current value of the option.
   */
  var checkbox:CheckboxPreferenceItem;

  /**
   * The button's text.
   */
  public var text:TextMenuItem;

  /**
   * Creates a new HitboxShowcase instance.
   *
   * @param xPos The x position of the object.
   * @param yPos The y position of the object.
   * @param defaultValue Option's default value.
   * @param onClick A callback function that will be triggered when the object is clicked.
   */
  public function new(?xPos:Float = 0, ?yPos:Float = 0, defaultValue:Bool, onClick:Bool->Void):Void
  {
    super(xPos, yPos);

    checkbox = new CheckboxPreferenceItem(0, 0, defaultValue);
    add(checkbox);

    text = new TextMenuItem(checkbox.x + checkbox.width, checkbox.y + 30, "Downscroll", AtlasFont.BOLD, function() {
      final value:Bool = !checkbox.currentValue;
      onClick(value);
      checkbox.currentValue = value;
    });
    add(text);

    setSize(500, 500);

    final optionCamera:FunkinCamera = new FunkinCamera('optionCamera');
    FlxG.cameras.add(optionCamera, false);
    optionCamera.bgColor = 0x0;

    cameras = [optionCamera];
  }
}
