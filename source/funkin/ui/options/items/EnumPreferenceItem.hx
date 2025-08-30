package funkin.ui.options.items;

import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.AtlasText;
import funkin.input.Controls;
#if mobile
import funkin.util.SwipeUtil;
#end

/**
 * Preference item that allows the player to pick a value from an enum (list of values)
 */
class EnumPreferenceItem<T> extends TextMenuItem
{
  function controls():Controls
  {
    return PlayerSettings.player1.controls;
  }

  public var lefthandText:AtlasText;

  public var currentKey:String;
  public var onChangeCallback:Null<String->T->Void>;
  public var map:Map<String, T>;
  public var keys:Array<String> = [];

  var index = 0;

  public function new(x:Float, y:Float, name:String, map:Map<String, T>, defaultKey:String, ?callback:String->T->Void)
  {
    super(x, y, name, function() {
      var value = map.get(this.currentKey);
      callback(this.currentKey, value);
    });

    updateHitbox();

    this.map = map;
    this.currentKey = defaultKey;
    this.onChangeCallback = callback;

    var i:Int = 0;
    for (key in map.keys())
    {
      var value:T = map[key];

      this.keys.push(key);
      if (this.currentKey == key) index = i;
      i += 1;
    }

    lefthandText = new AtlasText(x + 15, y, formatted(defaultKey), AtlasFont.DEFAULT);

    this.fireInstantly = true;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // var fancyTextFancyColor:Color;
    if (selected)
    {
      var shouldDecrease:Bool = controls().UI_LEFT_P #if mobile || SwipeUtil.justSwipedLeft #end;
      var shouldIncrease:Bool = controls().UI_RIGHT_P #if mobile || SwipeUtil.justSwipedRight #end;

      if (shouldDecrease) index -= 1;
      if (shouldIncrease) index += 1;

      if (index > keys.length - 1) index = 0;
      if (index < 0) index = keys.length - 1;

      currentKey = keys[index];
      if (onChangeCallback != null && (shouldIncrease || shouldDecrease))
      {
        var value = map.get(currentKey);
        onChangeCallback(currentKey, value);
      }
    }

    lefthandText.text = formatted(currentKey);
  }

  function formatted(key:String):String
  {
    // FIXME: Can't add arrows around the text because the font doesn't support < >
    // var leftArrow:String = selected ? '<' : '';
    // var rightArrow:String = selected ? '>' : '';
    return '${key}';
  }
}
