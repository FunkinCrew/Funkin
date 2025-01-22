package funkin.mobile.ui.options.objects;

import flixel.group.FlxSpriteGroup;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.options.items.CheckboxPreferenceItem;
import funkin.ui.AtlasText.AtlasFont;

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
   * @param name Option's name.
   * @param xPos The x position of the object.
   * @param yPos The y position of the object.
   * @param defaultValue Option's default value.
   * @param onClick A callback function that will be triggered when the object is clicked.
   */
  public function new(name:String = "", ?xPos:Float = 0, ?yPos:Float = 0, defaultValue:Bool, onClick:Bool->Void):Void
  {
    super(xPos, yPos);

    checkbox = new CheckboxPreferenceItem(0, 0, defaultValue);
    add(checkbox);

    text = new TextMenuItem(checkbox.x + checkbox.width, checkbox.y + 30, name, AtlasFont.BOLD, function() {
      final value:Bool = !checkbox.currentValue;
      onClick(value);
      checkbox.currentValue = value;
    });
    add(text);

    setSize(500, 500);
  }
}
