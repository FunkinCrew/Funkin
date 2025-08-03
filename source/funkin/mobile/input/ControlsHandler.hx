package funkin.mobile.input;

import funkin.input.Controls;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionInputDigital;
import funkin.mobile.ui.FunkinButton;
import funkin.mobile.ui.FunkinHitbox;
import funkin.play.notes.NoteDirection;
import openfl.events.KeyboardEvent;
import openfl.events.TouchEvent;

/**
 * Handles setting up and managing input controls for the game.
 */
class ControlsHandler
{
  /**
   * Returns wether the last input was sent through touch.
   */
  public static var lastInputTouch(default, null):Bool = true;

  /**
   * Returns wether there's a gamepad or keyboard devices connected and active.
   */
  public static var hasExternalInputDevice(get, never):Bool;

  /**
   * Returns wether an external input device is currently used as the main input.
   */
  public static var usingExternalInputDevice(get, never):Bool;

  /**
   * Initialize input trackers used to get the current status of the `lastInputTouch` field.
   */
  public static function initInputTrackers():Void
  {
    FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, (_) -> lastInputTouch = false);
    FlxG.stage.addEventListener(TouchEvent.TOUCH_BEGIN, (_) -> lastInputTouch = true);
  }

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

    for (hint in hitbox.members)
    {
      @:privateAccess
      switch (hint.noteDirection)
      {
        case NoteDirection.LEFT:
          controls.forEachBound(Control.NOTE_LEFT, function(action:FlxActionDigital, state:FlxInputState):Void {
            addButton(action, hint, state, cachedInput);
          });
        case NoteDirection.DOWN:
          controls.forEachBound(Control.NOTE_DOWN, function(action:FlxActionDigital, state:FlxInputState):Void {
            addButton(action, hint, state, cachedInput);
          });
        case NoteDirection.UP:
          controls.forEachBound(Control.NOTE_UP, function(action:FlxActionDigital, state:FlxInputState):Void {
            addButton(action, hint, state, cachedInput);
          });
        case NoteDirection.RIGHT:
          controls.forEachBound(Control.NOTE_RIGHT, function(action:FlxActionDigital, state:FlxInputState):Void {
            addButton(action, hint, state, cachedInput);
          });
      }
    }
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

  @:noCompletion
  private static function get_hasExternalInputDevice():Bool
  {
    return FlxG.gamepads.numActiveGamepads > 0;
  }

  @:noCompletion
  private static function get_usingExternalInputDevice():Bool
  {
    return ControlsHandler.hasExternalInputDevice && !ControlsHandler.lastInputTouch;
  }
}
