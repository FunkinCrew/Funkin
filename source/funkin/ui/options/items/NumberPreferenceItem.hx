package funkin.ui.options.items;

import funkin.ui.TextMenuList;
import funkin.ui.AtlasText;
import funkin.input.Controls;

/**
 * Preference item that allows the player to pick a value between min and max
 */
class NumberPreferenceItem extends TextMenuItem
{
  function controls():Controls
  {
    return PlayerSettings.player1.controls;
  }

  public var lefthandText:AtlasText;

  public var currentValue:Float;
  public var min:Float;
  public var max:Float;
  public var step:Float;
  public var precision:Int;
  public var onChangeCallback:Null<Float->Void>;

  public function new(x:Float, y:Float, name:String, defaultValue:Float, min:Float, max:Float, step:Float, precision:Int, ?callback:Float->Void):Void
  {
    super(x, y, name, function() {
      callback(this.currentValue);
    });
    lefthandText = new AtlasText(20, y, formatted(defaultValue), AtlasFont.DEFAULT);

    updateHitbox();

    this.currentValue = defaultValue;
    this.min = min;
    this.max = max;
    this.step = step;
    this.precision = precision;
    this.onChangeCallback = callback;
  }

  static final HOLD_DELAY:Float = 0.5; // seconds
  static final CHANGE_RATE:Float = 0.02; // seconds

  var holdDelayTimer:Float = HOLD_DELAY; // seconds
  var changeRateTimer:Float = 0.0; // seconds

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // var fancyTextFancyColor:Color;
    if (selected)
    {
      holdDelayTimer -= elapsed;
      if (holdDelayTimer <= 0.0)
      {
        changeRateTimer -= elapsed;
      }

      var jpLeft:Bool = controls().UI_LEFT_P;
      var jpRight:Bool = controls().UI_RIGHT_P;

      if (jpLeft || jpRight)
      {
        holdDelayTimer = HOLD_DELAY;
        changeRateTimer = 0.0;
      }

      var shouldDecrease:Bool = jpLeft;
      var shouldIncrease:Bool = jpRight;

      if (controls().UI_LEFT && holdDelayTimer <= 0.0 && changeRateTimer <= 0.0)
      {
        shouldDecrease = true;
        changeRateTimer = CHANGE_RATE;
      }
      else if (controls().UI_RIGHT && holdDelayTimer <= 0.0 && changeRateTimer <= 0.0)
      {
        shouldIncrease = true;
        changeRateTimer = CHANGE_RATE;
      }

      if (shouldDecrease) currentValue -= step;
      else if (shouldIncrease) currentValue += step;
      currentValue = currentValue.clamp(min, max);
      if (onChangeCallback != null && (shouldIncrease || shouldDecrease))
      {
        onChangeCallback(currentValue);
      }
    }

    lefthandText.text = formatted(currentValue);
  }

  function formatted(value:Float):String
  {
    return '${toFixed(value)}';
  }

  function toFixed(value:Float):Float
  {
    var multiplier:Float = Math.pow(10, precision);
    return Math.floor(value * multiplier) / multiplier;
  }
}
