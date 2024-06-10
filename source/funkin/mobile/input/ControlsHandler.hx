package funkin.mobile.input;

import funkin.input.Controls;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionInputDigital;
import funkin.mobile.ui.FunkinButton;
import funkin.mobile.ui.FunkinHitbox;

/**
 * Handles setting up and managing input controls for the game.
 */
class ControlsHandler
{
  /**
   * Adds a button input to a given FlxActionDigital and caches it.
   *
   * @param action The FlxActionDigital to add the button input to.
   * @param button The FunkinButton associated with the action.
   * @param state The input state to associate with the action.
   * @param cachedInput The array of FlxActionInput objects to cache the input.
   */
  public static function addButton(action:FlxActionDigital, button:FunkinButton, state:FlxInputState, cachedInput:Array<FlxActionInput>):Void
  {
    if (action == null || button == null || cachedInput == null) return;

    final input:FlxActionInputDigitalIFlxInput = new FlxActionInputDigitalIFlxInput(button, state);
    cachedInput.push(input);
    action.add(input);
  }

  /**
   * Sets up hitbox controls based on game controls and hitbox hints.
   *
   * @param controls The controls instance defining game controls.
   * @param hitbox The hitbox to associate with the controls.
   * @param cachedInput The array of action input objects to cache the input.
   */
  @:access(funkin.input.Controls)
  public static function setupHitbox(controls:Controls, hitbox:FunkinHitbox, cachedInput:Array<FlxActionInput>):Void
  {
    if (controls == null || hitbox == null) return;

    controls.forEachBound(Control.NOTE_LEFT, function(action:FlxActionDigital, state:FlxInputState):Void {
      addButton(action, hitbox.hints[0], state, cachedInput);
    });
    controls.forEachBound(Control.NOTE_DOWN, function(action:FlxActionDigital, state:FlxInputState):Void {
      addButton(action, hitbox.hints[1], state, cachedInput);
    });
    controls.forEachBound(Control.NOTE_UP, function(action:FlxActionDigital, state:FlxInputState):Void {
      addButton(action, hitbox.hints[2], state, cachedInput);
    });
    controls.forEachBound(Control.NOTE_RIGHT, function(action:FlxActionDigital, state:FlxInputState):Void {
      addButton(action, hitbox.hints[3], state, cachedInput);
    });
  }

  /**
   * Removes cached input associated with game controls.
   *
   * @param controls The Controls instance defining game controls.
   * @param cachedInput The array of action input objects to clear cached input from.
   */
  public static function removeCachedInput(controls:Controls, cachedInput:Array<FlxActionInput>):Void
  {
    for (action in controls.digitalActions)
    {
      var i:Int = action.inputs.length;

      while (i-- > 0)
      {
        var j:Int = cachedInput.length;

        while (j-- > 0)
        {
          if (cachedInput[j] == action.inputs[i])
          {
            action.remove(action.inputs[i]);
            cachedInput.remove(cachedInput[j]);
          }
        }
      }
    }
  }
}
