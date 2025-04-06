package funkin.ui.options;

import flixel.FlxSprite;
import funkin.ui.options.items.CheckboxPreferenceItem;
import funkin.ui.options.items.NumberPreferenceItem;
import funkin.ui.options.items.EnumPreferenceItem;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.MenuList.MenuTypedItem;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class PreferenceItem extends MenuTypedItem<FlxTypedSpriteGroup<FlxSprite>>
{
  /**
   * The type of the preference item.
   * - Checkbox: A checkbox that can be checked or unchecked.
   * - Number: A number input that can be adjusted with a slider.
   * - Percentage: A percentage input that can be adjusted with a slider.
   * - Enum: A dropdown list that allows the user to select from a list of options.
   */
  public var type:PreferenceType;

  /**
   * The description of the preference item.
   * This is used to display the description of the preference item in the options menu.
   */
  public var description:String;

  /**
   * The function to call when the preference item changes.
   * This is used to update the preference item when the user interacts with it.
   */
  public var onChange:Null<Dynamic->Void>;

  /**
   * The default value of the preference item.
   * This is used to set the initial value of the preference item when it is created.
   */
  public var defaultValue:Dynamic;

  public var text:AtlasText;
  public var preferenceGraphic:FlxSprite;

  static final SPACING_X:Float = 100;

  public function new(x:Float, y:Float, type:PreferenceType, name:String, description:String, onChange:Null<Dynamic->Void>, defaultValue:Dynamic,
      ?extraData:PreferenceItemData)
  {
    var group = new FlxTypedSpriteGroup<FlxSprite>();

    switch (type)
    {
      case PreferenceType.Checkbox:
        preferenceGraphic = new CheckboxPreferenceItem(x, y, defaultValue, onChange);
      case PreferenceType.Number:
        preferenceGraphic = new NumberPreferenceItem(x, y, name, defaultValue, extraData?.min, extraData?.max, extraData?.step, extraData?.precision,
          onChange, extraData?.formatter);
      case PreferenceType.Percentage:
        preferenceGraphic = new NumberPreferenceItem(x, y, name, defaultValue, extraData?.min ?? 0, extraData?.max ?? 100, 10, 0, function(value:Float) {
          onChange(Std.int(value));
        }, function(value:Float):String {
          return '${value}%';
        });
      case PreferenceType.Enum:
        preferenceGraphic = new EnumPreferenceItem(x, y, name, extraData.values, defaultValue, onChange);
      default:
        trace('Unsupported PreferenceType: $type');
        preferenceGraphic = null; // Explicitly set to null to avoid uninitialized variable issues
    }

    text = new AtlasText(x + (preferenceGraphic != null ? preferenceGraphic.frameWidth : 0), y, name, BOLD);
    group.add(text);

    if (preferenceGraphic != null) group.add(preferenceGraphic);

    super(x, y, group, name, function() {
      if (onChange != null)
      {
        switch (type)
        {
          case PreferenceType.Checkbox:
            var checkbox = cast(preferenceGraphic, CheckboxPreferenceItem);
            var value = !checkbox.currentValue;
            onChange(value);
            checkbox.currentValue = value;
          default:
            onChange(defaultValue);
        }
      }
    });

    this.type = type;
    this.description = description;
    this.onChange = onChange;
    this.defaultValue = defaultValue;
    if (type != PreferenceType.Checkbox) this.fireInstantly = true;
  }

  override function update(elapsed:Float):Void
  {
    // if (Std.isOfType(this, EnumPreferenceItem)) cast(this, EnumPreferenceItem).update(elapsed);
    // else if (Std.isOfType(this, NumberPreferenceItem)) cast(this, NumberPreferenceItem).update(elapsed);
    // else if (Std.isOfType(this, CheckboxPreferenceItem)) cast(this, CheckboxPreferenceItem).update(elapsed);

    super.update(elapsed);
  }
}

enum PreferenceType
{
  Checkbox;
  Number;
  Percentage;
  Enum;
}

/**
 * @param type The type of the preference item.
 * @param name The name of the preference item.
 * @param description The description of the preference item.
 * @param onChange The function to call when the preference item changes.
 * @param defaultValue The default value of the preference item.
 * @param min The minimum value of the number preference item.
 * @param max The maximum value of the number preference item.
 * @param step The step value of the number preference item.
 * @param formatter The function to call to format the value of the number preference item.
 * @param precision The precision of the value of the number preference item.
 * @param values The values of the enumpreference item.
 */
typedef PreferenceItemData =
{
  var ?min:Int;
  var ?max:Int;
  var ?step:Float;
  var ?formatter:Float->String;
  var ?precision:Int;

  var ?values:Map<String, String>;
}
