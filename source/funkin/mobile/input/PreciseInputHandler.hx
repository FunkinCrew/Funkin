package funkin.mobile.input;

import flixel.input.FlxInput;
import funkin.input.PreciseInputManager;
import funkin.mobile.ui.FunkinHitbox;
import funkin.play.notes.NoteDirection;
import haxe.Int64;

/**
 * Handles setting up and managing precise input controls for the game.
 */
@:access(funkin.input.PreciseInputManager)
class PreciseInputHandler
{
  /**
   * Initializes the hitbox with the relevant hints and event handlers.
   *
   * @param hitbox The hitbox to initialize.
   */
  public static function initializeHitbox(hitbox:FunkinHitbox):Void
  {
    hitbox.onHintDown.add(handleHintDown);
    hitbox.onHintUp.add(handleHintUp);
  }

  /**
   * Handles the event when a hint is pressed.
   *
   * @param hint The hint that was pressed.
   */
  static function handleHintDown(hint:FunkinHint):Void
  {
    final timestamp:Int64 = PreciseInputManager.getCurrentTimestamp();
    @:privateAccess
    if (hint.input?.justPressed ?? false)
    {
      PreciseInputManager.instance.onInputPressed.dispatch({noteDirection: hint.noteDirection, timestamp: timestamp});
      PreciseInputManager.instance._dirPressTimestamps.set(hint.noteDirection, timestamp);
    }
  }

  /**
   * Handles the event when a hint is released.
   *
   * @param hint The hint that was released.
   */
  static function handleHintUp(hint:FunkinHint):Void
  {
    final timestamp:Int64 = PreciseInputManager.getCurrentTimestamp();
    @:privateAccess
    if (hint.input?.justReleased ?? false)
    {
      PreciseInputManager.instance.onInputReleased.dispatch({noteDirection: hint.noteDirection, timestamp: timestamp});
      PreciseInputManager.instance._dirPressTimestamps.set(hint.noteDirection, timestamp);
    }
  }
}
