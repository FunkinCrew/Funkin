package funkin.ui.charSelect;

import flixel.math.FlxMath;
import flixel.util.FlxDirectionFlags;

/**
 * Data for a directional input.
 */
typedef DirectionData =
{
  inputs:Array<Bool>,
  vertical:Bool,
  invert:Bool
}

/**
 * We would normally handle inputs in a state directly, but this has more
 * moving pieces than typical control checks!! So it's in a separate class to prevent bloating the state.
 *
 * This class handles DIRECTIONAL inputs, the state handles ACCEPT/BACK inputs.
 *
 * It seems weird having this in a separate class, but trust the process! - Abnormal
 */
@:nullSafety
class CharSelectInputHandler
{
  /**
   * The amount of time in seconds that a direction must be held to spam on step.
   */
  public static final STEP_SPAM_THRESHOLD:Float = 0.5;

  /**
   * A list of timers for each direction.
   * Used to track the amount of time a direction has been held.
   */
  var directionSpamTimers:Map<FlxDirectionFlags, Float> = [UP => 0, DOWN => 0, LEFT => 0, RIGHT => 0];

  /**
   * The current direction that is being spammed.
   */
  var currentSpamDirection:FlxDirectionFlags = NONE;

  /**
   * The current selection in the Character Select screen.
   */
  var currentSelection(get, set):Int;

  function get_currentSelection():Int
  {
    if (CharacterSelectState.instance == null) return 0;

    return CharacterSelectState.instance.currentSelection;
  }

  function set_currentSelection(value:Int):Int
  {
    if (CharacterSelectState.instance == null) return 0;

    CharacterSelectState.instance.currentSelection = value;

    return value;
  }

  /**
   * The total number of slots in the Character Select screen.
   */
  var totalSlots(get, never):Int;

  function get_totalSlots():Int
  {
    if (CharacterSelectState.instance == null) return 0;

    @:privateAccess
    return CharacterSelectState.instance.totalSlots;
  }

  /**
   * The amount of slots per row.
   */
  var SLOTS_PER_ROW(get, never):Int;

  function get_SLOTS_PER_ROW():Int
  {
    return CharacterSelectState.SLOTS_PER_ROW;
  }

  public function new()
  {
    Conductor.instance.onStepHit.add(spamOnStep);
  }

  /**
   * Resets the spam direction and timers.
   */
  public function reset():Void
  {
    for (direction in [UP, DOWN, LEFT, RIGHT])
    {
      directionSpamTimers[direction] = 0;
    }

    currentSpamDirection = NONE;
  }

  /**
   * Automatically handles directional input.
   * @param elapsed The elapsed time since the last frame.
   */
  public function handleDirectionInput(elapsed:Float):Void
  {
    @:privateAccess
    var controls:funkin.input.Controls = CharacterSelectState.instance.controls;
    var directions:Map<FlxDirectionFlags, DirectionData> = [
      UP => {
        inputs: [controls.UI_UP, controls.UI_UP_P, controls.UI_UP_R],
        vertical: true,
        invert: true
      },
      DOWN => {
        inputs: [controls.UI_DOWN, controls.UI_DOWN_P, controls.UI_DOWN_R],
        vertical: true,
        invert: false
      },
      LEFT => {
        inputs: [controls.UI_LEFT, controls.UI_LEFT_P, controls.UI_LEFT_R],
        vertical: false,
        invert: true
      },
      RIGHT => {
        inputs: [controls.UI_RIGHT, controls.UI_RIGHT_P, controls.UI_RIGHT_R],
        vertical: false,
        invert: false
      }
    ];

    for (direction => data in directions)
    {
      var timer:Float = directionSpamTimers[direction] ?? 0;

      if (data.inputs[1] || data.inputs[2])
      {
        timer = 0;
        if (data.inputs[2])
        {
          currentSpamDirection = currentSpamDirection.without(direction);
        }
        else
        {
          if (data.vertical)
          {
            var column:Int = currentSelection % SLOTS_PER_ROW;
            currentSelection = FlxMath.wrap(currentSelection + SLOTS_PER_ROW * (data.invert ? -1 : 1), column, totalSlots + column - 1);
          }
          else
          {
            var row:Int = Math.floor(currentSelection / SLOTS_PER_ROW);
            currentSelection = FlxMath.wrap(currentSelection + (data.invert ? -1 : 1), row * SLOTS_PER_ROW, (row + 1) * SLOTS_PER_ROW - 1);
          }
        }
      }
      else if (data.inputs[0])
      {
        timer += elapsed;
      }

      if (timer >= STEP_SPAM_THRESHOLD) currentSpamDirection = currentSpamDirection.with(direction);
      directionSpamTimers[direction] = timer;
    }
  }

  function spamOnStep():Void
  {
    @:privateAccess
    var controls:funkin.input.Controls = CharacterSelectState.instance.controls;

    for (direction in [UP, DOWN, LEFT, RIGHT])
    {
      if (!currentSpamDirection.has(direction)) continue;
      if (oppositeInputs(direction, controls)) continue;

      var isVertical:Bool = direction == UP || direction == DOWN;
      var movement:Float = (direction == UP || direction == LEFT ? -1 : 1) * (isVertical ? SLOTS_PER_ROW : 1);
      var axis:Float = isVertical ? currentSelection % SLOTS_PER_ROW : Math.floor(currentSelection / SLOTS_PER_ROW);
      var min:Float = isVertical ? axis : axis * SLOTS_PER_ROW;
      var max:Float = isVertical ? totalSlots + axis - 1 : (axis + 1) * SLOTS_PER_ROW - 1;

      currentSelection = FlxMath.wrap(Std.int(currentSelection + movement), Std.int(min), Std.int(max));

      directionSpamTimers[direction] = 0;
    }
  }

  function oppositeInputs(direction:FlxDirectionFlags, controls:funkin.input.Controls):Bool
  {
    if (direction == UP || direction == DOWN)
    {
      return controls.UI_UP && controls.UI_DOWN;
    }

    return controls.UI_LEFT && controls.UI_RIGHT;
  }
}
