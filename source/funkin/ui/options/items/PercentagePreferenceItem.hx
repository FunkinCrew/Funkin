package funkin.ui.options.items;

import funkin.ui.TextMenuList;
import funkin.ui.AtlasText;
import funkin.input.Controls;

/**
 * Preference item that allows the player to pick a value between min and max
 */
class PercentagePreferenceItem extends TextMenuItem
{
  function controls():Controls
  {
    return PlayerSettings.player1.controls;
  }

  public var lefthandText:AtlasText;

  public var currentValue:Int;
  public var min:Int;
  public var max:Int;
  public var zeroIsDisabled:Bool;
  public var onChangeCallback:Null<Int->Void>;

  /**
   * @param zeroIsDisabled If true, 0 will be displayed as "OFF"
   */
  public function new(x:Float, y:Float, name:String, defaultValue:Int, min:Int = 0, max:Int = 100, zeroIsDisabled:Bool = false, ?callback:Int->Void):Void
  {
    super(x, y, name, function() {
      callback(this.currentValue);
    });
    lefthandText = new AtlasText(20, y, formatted(defaultValue), AtlasFont.DEFAULT);

    updateHitbox();

    this.currentValue = defaultValue;
    this.min = min;
    this.max = max;
    this.zeroIsDisabled = zeroIsDisabled;
    this.onChangeCallback = callback;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // var fancyTextFancyColor:Color;
    if (selected)
    {
      var increment:Int = 10;
      var shouldDecrease:Bool = controls().UI_LEFT_P;
      var shouldIncrease:Bool = controls().UI_RIGHT_P;

      if (FlxG.keys.pressed.SHIFT) increment = Std.int(increment / 2);
      if (FlxG.keys.pressed.CONTROL) increment = 1;

      if (shouldDecrease) currentValue -= increment;
      if (shouldIncrease) currentValue += increment;
      currentValue = currentValue.clamp(min, max);
      if (onChangeCallback != null && (shouldIncrease || shouldDecrease))
      {
        onChangeCallback(currentValue);
      }
    }

    lefthandText.text = formatted(currentValue);
  }

  function formatted(percent:Int):String
  {
    return if (zeroIsDisabled && percent == 0) "OFF"; else '${percent}%';
  }
}
