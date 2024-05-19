package funkin.mobile;

import funkin.input.PreciseInputManager;
import funkin.play.notes.NoteDirection;
import flixel.input.FlxInput;
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
  static var _hintList:Array<FunkinButton> = [];

  /**
   * The direction that a given hint is bound to.
   */
  static var _hintListDir:Map<FunkinButton, NoteDirection> = new Map<FunkinButton, NoteDirection>();

  static var _hintListMap:Map<Int, FlxInput<Int>> = new Map<Int, FlxInput<Int>>();

  public static function getHintForDirection(noteDirection:NoteDirection, hitbox:FunkinHitbox)
  {
    return switch (noteDirection)
    {
      case NoteDirection.LEFT: hitbox.hints[0];
      case NoteDirection.DOWN: hitbox.hints[1];
      case NoteDirection.UP: hitbox.hints[2];
      case NoteDirection.RIGHT: hitbox.hints[3];
    };
  }

  public static function initializeHitbox(hitbox:FunkinHitbox):Void
  {
    clearHints();

    hitbox.onHintDown.add(handleHintnDown);
    hitbox.onHintUp.add(handleHintUp);

    for (noteDirection in PreciseInputManager.DIRECTIONS)
    {
      var hint:FunkinButton = getHintForDirection(noteDirection, hitbox);

      _hintList[hint.ID] = hint;
      _hintListMap.set(hint.ID, @:privateAccess hint.input);
      _hintListDir.set(hint, noteDirection);
    }
  }

  public static function getInputByHintID(hintID:Int):FlxInput<Int>
  {
    return _hintListMap.get(hintID);
  }

  public static function getDirectionForHint(hint:FunkinButton):NoteDirection
  {
    return _hintListDir.get(hint);
  }

  static function handleHintnDown(hint:FunkinButton):Void
  {
    var timestamp:Int64 = PreciseInputManager.getCurrentTimestamp();

    if (_hintList == null || _hintList.indexOf(hint) == -1) return;

    // TODO: Remove this line with SDL3 when timestamps change meaning.
    // This is because SDL3's timestamps ar e measured in nanoseconds, not milliseconds.
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

  static function handleHintUp(hint:FunkinButton):Void
  {
    var timestamp:Int64 = PreciseInputManager.getCurrentTimestamp();

    if (_hintList == null || _hintList.indexOf(hint) == -1) return;

    // TODO: Remove this line with SDL3 when timestamps change meaning.
    // This is because SDL3's timestamps ar e measured in nanoseconds, not milliseconds.
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

  // Needs to somehow get called in PreciseInputManager
  public static function clearHints():Void
  {
    _hintList = [];
    _hintListDir.clear();
    _hintListMap.clear();
  }
}
