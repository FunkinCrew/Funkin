package funkin.mobile.input;

import flixel.input.FlxInput;
import funkin.input.PreciseInputManager;
import funkin.mobile.ui.FunkinHitbox;
import funkin.play.notes.NoteDirection;
import haxe.ds.Map;
import haxe.Int64;

/**
 * Handles setting up and managing precise input controls for the game.
 */
@:access(funkin.input.PreciseInputManager)
class PreciseInputHandler
{
  /**
   * The list of hints that are bound to game inputs (up/down/left/right).
   */
  static var _hintList:Array<FunkinHint> = [];

  /**
   * The direction that a given hint is bound to.
   */
  static var _hintListDir:Map<FunkinHint, NoteDirection> = new Map<FunkinHint, NoteDirection>();

  /**
   * The map of the list of hints.
   */
  static var _hintListMap:Map<Int, FlxInput<Int>> = new Map<Int, FlxInput<Int>>();

  /**
   * Retrieves the hint for the specified direction from the given hitbox.
   *
   * @param noteDirection The direction to get the hint for.
   * @param hitbox The hitbox containing the hints.
   * @return The hint corresponding to the given direction.
   */
  public static function getHintForDirection(noteDirection:NoteDirection, hitbox:FunkinHitbox):FunkinHint
  {
    return switch (noteDirection)
    {
      case NoteDirection.LEFT: hitbox.hints[0];
      case NoteDirection.DOWN: hitbox.hints[1];
      case NoteDirection.UP: hitbox.hints[2];
      case NoteDirection.RIGHT: hitbox.hints[3];
    };
  }

  /**
   * Initializes the hitbox with the relevant hints and event handlers.
   *
   * @param hitbox The hitbox to initialize.
   */
  public static function initializeHitbox(hitbox:FunkinHitbox):Void
  {
    clearHints();

    hitbox.onHintDown.add(handleHintDown);
    hitbox.onHintUp.add(handleHintUp);

    for (noteDirection in PreciseInputManager.DIRECTIONS)
    {
      var hint:FunkinHint = getHintForDirection(noteDirection, hitbox);

      _hintList[hint.ID] = hint;
      _hintListMap.set(hint.ID, @:privateAccess hint.input);
      _hintListDir.set(hint, noteDirection);
    }
  }

  /**
   * Gets the input associated with a specific hint ID.
   *
   * @param hintID The ID of the hint.
   * @return The input corresponding to the hint ID.
   */
  public static function getInputByHintID(hintID:Int):FlxInput<Int>
  {
    return _hintListMap.get(hintID);
  }

  /**
   * Gets the direction associated with a specific hint.
   *
   * @param hint The hint to get the direction for.
   * @return The direction corresponding to the hint.
   */
  public static function getDirectionForHint(hint:FunkinHint):NoteDirection
  {
    return _hintListDir.get(hint);
  }

  /**
   * Handles the event when a hint is pressed.
   *
   * @param hint The hint that was pressed.
   */
  static function handleHintDown(hint:FunkinHint):Void
  {
    var timestamp:Int64 = PreciseInputManager.getCurrentTimestamp();

    if (_hintList == null || _hintList.indexOf(hint) == -1) return;

    // TODO: Remove this line with SDL3 when timestamps change meaning.
    // This is because SDL3's timestamps are measured in nanoseconds, not milliseconds.
    // timestamp *= Constants.NS_PER_MS;

    if (getInputByHintID(hint.ID)?.justPressed ?? false)
    {
      PreciseInputManager.instance.onInputPressed.dispatch(
        {
          noteDirection: getDirectionForHint(hint),
          timestamp: timestamp
        });
      PreciseInputManager.instance._dirPressTimestamps.set(getDirectionForHint(hint), timestamp);
    }
  }

  /**
   * Handles the event when a hint is released.
   *
   * @param hint The hint that was released.
   */
  static function handleHintUp(hint:FunkinHint):Void
  {
    var timestamp:Int64 = PreciseInputManager.getCurrentTimestamp();

    if (_hintList == null || _hintList.indexOf(hint) == -1) return;

    // TODO: Remove this line with SDL3 when timestamps change meaning.
    // This is because SDL3's timestamps are measured in nanoseconds, not milliseconds.
    // timestamp *= Constants.NS_PER_MS;

    if (getInputByHintID(hint.ID)?.justReleased ?? false)
    {
      PreciseInputManager.instance.onInputReleased.dispatch(
        {
          noteDirection: getDirectionForHint(hint),
          timestamp: timestamp
        });
      PreciseInputManager.instance._dirPressTimestamps.set(getDirectionForHint(hint), timestamp);
    }
  }

  // Needs to be somehow called here.

  /**
   * Clears the current list of hints and their associated data.
   */
  public static function clearHints():Void
  {
    _hintList = [];
    _hintListDir.clear();
    _hintListMap.clear();
  }
}
