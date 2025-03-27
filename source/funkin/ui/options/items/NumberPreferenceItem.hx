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

  // Widgets
  public var lefthandText:AtlasText;

  // Constants
  static final HOLD_DELAY:Float = 0.3; // seconds
  static final CHANGE_RATE:Float = 0.08; // seconds

  // Constructor-initialized variables
  public var currentValue:Float;
  public var min:Float;
  public var max:Float;
  public var step:Float;
  public var precision:Int;
  public var onChangeCallback:Null<Float->Void>;
  public var valueFormatter:Null<Float->String>;

  // Variables
  var holdDelayTimer:Float = HOLD_DELAY; // seconds
  var changeRateTimer:Float = 0.0; // seconds

  /**
   * @param min Minimum value (example: 0)
   * @param max Maximum value (example: 100)
   * @param step The value to increment/decrement by (example: 10)
   * @param callback Will get called every time the user changes the setting; use this to apply/save the setting.
   * @param valueFormatter Will get called every time the game needs to display the float value; use this to change how the displayed string looks
   */
  public function new(x:Float, y:Float, name:String, defaultValue:Float, min:Float, max:Float, step:Float, precision:Int, ?callback:Float->Void,
      ?valueFormatter:Float->String):Void
  {
    super(x, y, name, function() {
      callback(this.currentValue);
    });
    lefthandText = new AtlasText(15, y, formatted(defaultValue), AtlasFont.DEFAULT);

    updateHitbox();

    this.currentValue = defaultValue;
    this.min = min;
    this.max = max;
    this.step = step;
    this.precision = precision;
    this.onChangeCallback = callback;
    this.valueFormatter = valueFormatter;

    this.fireInstantly = true;
  }

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

      // Actually increasing/decreasing the value
      if (shouldDecrease)
      {
        var isBelowMin:Bool = currentValue - step < min;
        currentValue = (currentValue - step).clamp(min, max);
        if (onChangeCallback != null && !isBelowMin) onChangeCallback(currentValue);
      }
      else if (shouldIncrease)
      {
        var isAboveMax:Bool = currentValue + step > max;
        currentValue = (currentValue + step).clamp(min, max);
        if (onChangeCallback != null && !isAboveMax) onChangeCallback(currentValue);
      }
    }

    lefthandText.text = formatted(currentValue);
  }

  /** Turns the float into a string */
  function formatted(value:Float):String
  {
    var float:Float = toFixed(value);
    if (valueFormatter != null)
    {
      return valueFormatter(float);
    }
    else
    {
      return '${float}';
    }
  }

  function toFixed(value:Float):Float
  {
    var multiplier:Float = Math.pow(10, precision);
    return Math.floor(value * multiplier) / multiplier;
  }
}
