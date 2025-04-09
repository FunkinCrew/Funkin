package funkin.ui.options;

import flixel.FlxSprite;
import funkin.ui.options.items.CheckboxPreferenceItem;
import funkin.ui.options.items.NumberPreferenceItem;
import funkin.ui.options.items.EnumPreferenceItem;
import funkin.ui.MenuList.MenuTypedItem;
import funkin.ui.TextMenuList.TextMenuItem;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class PreferenceItem extends MenuTypedItem<FlxTypedSpriteGroup<FlxSprite>>
{
  /**
   * The type of the preference item.
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
  private var group:FlxTypedSpriteGroup<FlxSprite>;

  public static final SPACING_X:Int = 10;

  /**
   * Creates a new preference item.
   * @param type The type of the preference item (checkbox, number, percentage, enum).
   * @param name The name of the preference item.
   * @param description The description of the preference item.
   * @param onChange The function to call when the preference item changes.
   * @param defaultValue The default value of the preference item.
   * @param data
   */
  public function new(x:Float, y:Float, type:PreferenceType, name:String, description:String, onChange:Null<Dynamic->Void>, defaultValue:Dynamic, ?data:PreferenceItemData)
  {
    group = new FlxTypedSpriteGroup<FlxSprite>();

    switch (type)
    {
      case Checkbox:
        preferenceGraphic = new CheckboxPreferenceItem(x, y, defaultValue, onChange);
      case Number:
        preferenceGraphic = new NumberPreferenceItem(x, y, name, defaultValue, data?.min, data?.max, data?.step, data?.precision, onChange, data?.formatter);
      case Percentage:
        preferenceGraphic = new NumberPreferenceItem(x, y, name, defaultValue, data?.min ?? 0, data?.max ?? 100, 10, 0, function(value:Float) {
          onChange(Std.int(value));
        }, function(value:Float):String {
          return '${value}%';
        });
      case Enum:
        preferenceGraphic = new EnumPreferenceItem(x, y, name, data?.values, defaultValue, onChange);
    }

    if (preferenceGraphic != null) group.add(preferenceGraphic);

    text = new AtlasText(x, y, name, BOLD);
    if (text != null) group.add(text);

    super(x, y, group, name, function() {
      if (onChange != null)
      {
        switch (type)
        {
          case Checkbox:
            var checkbox = cast(preferenceGraphic, CheckboxPreferenceItem);
            var value = !checkbox.currentValue;
            onChange(value);
            checkbox.currentValue = value;
          default:
            onChange(defaultValue);
        }
      }
    });

    setEmptyBackground();

    this.type = type;
    this.description = description;
    this.onChange = onChange;
    this.defaultValue = defaultValue;
    if (type != Checkbox) this.fireInstantly = true;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }

  override public function idle()
  {
    if (text != null) text.alpha = 0.6;
    if (preferenceGraphic != null) preferenceGraphic.alpha = 0.6;
  }

  override public function select()
  {
    if (text != null) text.alpha = 1.0;
    if (preferenceGraphic != null) preferenceGraphic.alpha = 1.0;
  }
}

/**
 * The type of the preference item.
 * This is used to determine how the preference item should be displayed and how it should behave.
 * - Checkbox: A checkbox that can be checked or unchecked.
 * - Number: A preference item that allows the user to have a number value.
 * - Percentage: A preference item that allows the user to have a percentage value.
 * - Enum: A list that allows the user to select a value from a list of options.
 */
enum abstract PreferenceType(String) from String to String
{
  var Checkbox = 'checkbox';
  var Number = 'number';
  var Percentage = 'percentage';
  var Enum = 'enum';
}

/**
 * @param min Minimum value (example: 0, for a percentage the default value is 0).
 * @param max Maximum value (example: 10, for a percentage the default value is 100).
 * @param step The value to increment/decrement by (default = 0.1)
 * @param formatter Will get called every time the game needs to display the float value; use this to change how the displayed value looks.
 * @param precision Rounds decimals up to a `precision` amount of digits (ex: 4 -> 0.1234, 2 -> 0.12)
 * @param values Maps enum values to display strings _(ex: `NoteHitSoundType.PingPong => "Ping pong"`)_
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
