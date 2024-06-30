package funkin.ui.options.items;

import funkin.ui.TextMenuList;
import funkin.ui.AtlasText;
import funkin.input.Controls;
import funkin.ui.options.MenuItemEnums;
import haxe.EnumTools;

/**
 * Preference item that allows the player to pick a value from an enum (list of values)
 */
class EnumPreferenceItem extends TextMenuItem
{
  function controls():Controls
  {
    return PlayerSettings.player1.controls;
  }

  public var lefthandText:AtlasText;

  public var currentValue:String;
  public var onChangeCallback:Null<String->Void>;
  public var map:Map<String, String>;
  public var keys:Array<String> = [];

  var index = 0;

  public function new(x:Float, y:Float, name:String, map:Map<String, String>, defaultValue:String, ?callback:String->Void)
  {
    super(x, y, name, function() {
      callback(this.currentValue);
    });

    updateHitbox();

    this.map = map;
    this.currentValue = defaultValue;
    this.onChangeCallback = callback;

    var i:Int = 0;
    for (key in map.keys())
    {
      this.keys.push(key);
      if (this.currentValue == key) index = i;
      i += 1;
    }

    lefthandText = new AtlasText(15, y, formatted(defaultValue), AtlasFont.DEFAULT);
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // var fancyTextFancyColor:Color;
    if (selected)
    {
      var shouldDecrease:Bool = controls().UI_LEFT_P;
      var shouldIncrease:Bool = controls().UI_RIGHT_P;

      if (shouldDecrease) index -= 1;
      if (shouldIncrease) index += 1;

      if (index > keys.length - 1) index = 0;
      if (index < 0) index = keys.length - 1;

      currentValue = keys[index];
      if (onChangeCallback != null && (shouldIncrease || shouldDecrease))
      {
        onChangeCallback(currentValue);
      }
    }

    lefthandText.text = formatted(currentValue);
  }

  function formatted(value:String):String
  {
    // FIXME: Can't add arrows around the text because the font doesn't support < >
    // var leftArrow:String = selected ? '<' : '';
    // var rightArrow:String = selected ? '>' : '';
    return '${map.get(value) ?? value}';
  }
}
