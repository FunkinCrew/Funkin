package funkin.ui.options.items;

import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.AtlasText;
import funkin.input.Controls;
import funkin.util.TouchUtil;
import funkin.util.SwipeUtil;

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
  public var dragStepMultiplier:Float;

  // Variables
  var holdDelayTimer:Float = HOLD_DELAY; // seconds
  var changeRateTimer:Float = 0.0; // seconds

  /**
   * @param min Minimum value (example: 0)
   * @param max Maximum value (example: 100)
   * @param step The value to increment/decrement by (example: 10)
   * @param callback Will get called every time the user changes the setting; use this to apply/save the setting.
   * @param valueFormatter Will get called every time the game needs to display the float value; use this to change how the displayed string looks
   * @param dragStepMultiplier The multiplier for step value in case player does touch drag.
   */
  public function new(x:Float, y:Float, name:String, defaultValue:Float, min:Float, max:Float, step:Float, precision:Int, ?callback:Float->Void,
      ?valueFormatter:Float->String, dragStepMultiplier:Float = 1):Void
  {
    super(x, y, name, function() {
      callback(this.currentValue);
    });
    lefthandText = new AtlasText(x + 15, y, formatted(defaultValue), AtlasFont.DEFAULT);

    updateHitbox();

    this.currentValue = defaultValue;
    this.min = min;
    this.max = max;
    this.step = step;
    this.precision = precision;
    this.onChangeCallback = callback;
    this.valueFormatter = valueFormatter;
    this.dragStepMultiplier = dragStepMultiplier;

    this.fireInstantly = true;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    lefthandText.text = formatted(currentValue);

    if (!selected) return;

    holdDelayTimer -= elapsed;
    if (holdDelayTimer <= 0.0)
    {
      changeRateTimer -= elapsed;
    }

    var jpLeft:Bool = controls().UI_LEFT_P #if FEATURE_TOUCH_CONTROLS || SwipeUtil.justSwipedLeft #end;
    var jpRight:Bool = controls().UI_RIGHT_P #if FEATURE_TOUCH_CONTROLS || SwipeUtil.justSwipedRight #end;

    if (jpLeft || jpRight)
    {
      holdDelayTimer = HOLD_DELAY;
      changeRateTimer = 0.0;
    }

    var shouldDecrease:Bool = jpLeft;
    var shouldIncrease:Bool = jpRight;
    var valueChangeMultiplier:Float = 1;

    #if FEATURE_TOUCH_CONTROLS
    final dragThreshold:Float = 24 / elapsed / 100;

    if (TouchUtil.touch != null && (TouchUtil.touch.deltaViewX <= -dragThreshold || TouchUtil.touch.deltaViewX >= dragThreshold))
    {
      valueChangeMultiplier = dragStepMultiplier;
    }
    #end

    if (holdDelayTimer <= 0.0 && changeRateTimer <= 0.0)
    {
      if (controls().UI_LEFT #if FEATURE_TOUCH_CONTROLS || (TouchUtil.touch != null && TouchUtil.touch.deltaX <= -dragThreshold) #end)
      {
        shouldDecrease = true;
        changeRateTimer = CHANGE_RATE;
      }
      else if (controls().UI_RIGHT #if FEATURE_TOUCH_CONTROLS || (TouchUtil.touch != null && TouchUtil.touch.deltaX >= dragThreshold) #end)
      {
        shouldIncrease = true;
        changeRateTimer = CHANGE_RATE;
      }
    }

    // Actually increasing/decreasing the value
    if (shouldDecrease)
    {
      var isBelowMin:Bool = currentValue - step * valueChangeMultiplier < min;
      currentValue = (currentValue - step * valueChangeMultiplier).clamp(min, max);
      if (onChangeCallback != null && !isBelowMin) onChangeCallback(currentValue);
    }
    else if (shouldIncrease)
    {
      var isAboveMax:Bool = currentValue + step * valueChangeMultiplier > max;
      currentValue = (currentValue + step * valueChangeMultiplier).clamp(min, max);
      if (onChangeCallback != null && !isAboveMax) onChangeCallback(currentValue);
    }
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
