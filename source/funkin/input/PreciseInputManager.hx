package funkin.input;

import openfl.ui.Keyboard;
import funkin.play.notes.NoteDirection;
import flixel.input.keyboard.FlxKeyboard.FlxKeyInput;
import openfl.events.KeyboardEvent;
import flixel.FlxG;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.FlxKeyManager;
import flixel.input.keyboard.FlxKey;
import flixel.input.keyboard.FlxKeyList;
import flixel.util.FlxSignal.FlxTypedSignal;
import haxe.Int64;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;

/**
 * A precise input manager that:
 * - Records the exact timestamp of when a key was pressed or released
 * - Only records key presses for keys bound to game inputs (up/down/left/right)
 */
class PreciseInputManager extends FlxKeyManager<FlxKey, PreciseInputList>
{
  public static var instance(get, null):PreciseInputManager;

  static function get_instance():PreciseInputManager
  {
    return instance ?? (instance = new PreciseInputManager());
  }

  static final DIRECTIONS:Array<NoteDirection> = [NoteDirection.LEFT, NoteDirection.DOWN, NoteDirection.UP, NoteDirection.RIGHT];

  public var onInputPressed:FlxTypedSignal<PreciseInputEvent->Void>;
  public var onInputReleased:FlxTypedSignal<PreciseInputEvent->Void>;

  /**
   * The list of keys that are bound to game inputs (up/down/left/right).
   */
  var _keyList:Array<FlxKey>;

  /**
   * The direction that a given key is bound to.
   */
  var _keyListDir:Map<FlxKey, NoteDirection>;

  /**
   * The timestamp at which a given note direction was last pressed.
   */
  var _dirPressTimestamps:Map<NoteDirection, Int64>;

  /**
   * The timestamp at which a given note direction was last released.
   */
  var _dirReleaseTimestamps:Map<NoteDirection, Int64>;

  public function new()
  {
    super(PreciseInputList.new);

    _keyList = [];
    _dirPressTimestamps = new Map<NoteDirection, Int64>();
    _dirReleaseTimestamps = new Map<NoteDirection, Int64>();
    _keyListDir = new Map<FlxKey, NoteDirection>();

    FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
    FlxG.stage.application.window.onKeyDownPrecise.add(handleKeyDown);
    FlxG.stage.application.window.onKeyUpPrecise.add(handleKeyUp);

    preventDefaultKeys = getPreventDefaultKeys();

    onInputPressed = new FlxTypedSignal<PreciseInputEvent->Void>();
    onInputReleased = new FlxTypedSignal<PreciseInputEvent->Void>();
  }

  public static function getKeysForDirection(controls:Controls, noteDirection:NoteDirection)
  {
    return switch (noteDirection)
    {
      case NoteDirection.LEFT: controls.getKeysForAction(NOTE_LEFT);
      case NoteDirection.DOWN: controls.getKeysForAction(NOTE_DOWN);
      case NoteDirection.UP: controls.getKeysForAction(NOTE_UP);
      case NoteDirection.RIGHT: controls.getKeysForAction(NOTE_RIGHT);
    };
  }

  /**
   * Convert from int to Int64.
   */
  static final NS_PER_MS:Int64 = Constants.NS_PER_MS;

  /**
   * Returns a precise timestamp, measured in nanoseconds.
   * Timestamp is only useful for comparing against other timestamps.
   *
   * @return Int64
   */
  @:access(lime._internal.backend.native.NativeCFFI)
  public static function getCurrentTimestamp():Int64
  {
    #if html5
    // NOTE: This timestamp isn't that precise on standard HTML5 builds.
    // This is because of browser safeguards against timing attacks.
    // See https://web.dev/coop-coep to enable headers which allow for more precise timestamps.
    return haxe.Int64.fromFloat(js.Browser.window.performance.now()) * NS_PER_MS;
    #elseif cpp
    // NOTE: If the game hard crashes on this line, rebuild Lime!
    // `lime rebuild windows -clean`
    return lime._internal.backend.native.NativeCFFI.lime_sdl_get_ticks() * NS_PER_MS;
    #else
    throw "Eric didn't implement precise timestamps on this platform!";
    #end
  }

  static function getPreventDefaultKeys():Array<FlxKey>
  {
    return [];
  }

  /**
   * Call this whenever the user's inputs change.
   */
  public function initializeKeys(controls:Controls):Void
  {
    clearKeys();

    for (noteDirection in DIRECTIONS)
    {
      var keys = getKeysForDirection(controls, noteDirection);
      for (key in keys)
      {
        var input = new FlxKeyInput(key);
        _keyList.push(key);
        _keyListArray.push(input);
        _keyListMap.set(key, input);
        _keyListDir.set(key, noteDirection);
      }
    }
  }

  /**
   * Get the time, in nanoseconds, since the given note direction was last pressed.
   * @param noteDirection The note direction to check.
   * @return An Int64 representing the time since the given note direction was last pressed.
   */
  public function getTimeSincePressed(noteDirection:NoteDirection):Int64
  {
    return getCurrentTimestamp() - _dirPressTimestamps.get(noteDirection);
  }

  /**
   * Get the time, in nanoseconds, since the given note direction was last released.
   * @param noteDirection The note direction to check.
   * @return An Int64 representing the time since the given note direction was last released.
   */
  public function getTimeSinceReleased(noteDirection:NoteDirection):Int64
  {
    return getCurrentTimestamp() - _dirReleaseTimestamps.get(noteDirection);
  }

  // TODO: Why doesn't this work?
  // @:allow(funkin.input.PreciseInputManager.PreciseInputList)
  public function getInputByKey(key:FlxKey):FlxKeyInput
  {
    return _keyListMap.get(key);
  }

  public function getDirectionForKey(key:FlxKey):NoteDirection
  {
    return _keyListDir.get(key);
  }

  function handleKeyDown(keyCode:KeyCode, _:KeyModifier, timestamp:Int64):Void
  {
    var key:FlxKey = convertKeyCode(keyCode);
    if (_keyList.indexOf(key) == -1) return;

    // TODO: Remove this line with SDL3 when timestamps change meaning.
    // This is because SDL3's timestamps are measured in nanoseconds, not milliseconds.
    timestamp *= Constants.NS_PER_MS;

    updateKeyStates(key, true);

    if (getInputByKey(key)?.justPressed ?? false)
    {
      onInputPressed.dispatch(
        {
          noteDirection: getDirectionForKey(key),
          timestamp: timestamp
        });
      _dirPressTimestamps.set(getDirectionForKey(key), timestamp);
    }
  }

  function handleKeyUp(keyCode:KeyCode, _:KeyModifier, timestamp:Int64):Void
  {
    var key:FlxKey = convertKeyCode(keyCode);
    if (_keyList.indexOf(key) == -1) return;

    // TODO: Remove this line with SDL3 when timestamps change meaning.
    // This is because SDL3's timestamps are measured in nanoseconds, not milliseconds.
    timestamp *= Constants.NS_PER_MS;

    updateKeyStates(key, false);

    if (getInputByKey(key)?.justReleased ?? false)
    {
      onInputReleased.dispatch(
        {
          noteDirection: getDirectionForKey(key),
          timestamp: timestamp
        });
      _dirReleaseTimestamps.set(getDirectionForKey(key), timestamp);
    }
  }

  static function convertKeyCode(input:KeyCode):FlxKey
  {
    @:privateAccess
    {
      return Keyboard.__convertKeyCode(input);
    }
  }

  function clearKeys():Void
  {
    _keyListArray = [];
    _keyListMap.clear();
    _keyListDir.clear();
  }
}

class PreciseInputList extends FlxKeyList
{
  var _preciseInputManager:PreciseInputManager;

  public function new(state:FlxInputState, preciseInputManager:FlxKeyManager<Dynamic, Dynamic>)
  {
    super(state, preciseInputManager);

    _preciseInputManager = cast preciseInputManager;
  }

  static function getKeysForDir(noteDir:NoteDirection):Array<FlxKey>
  {
    return PreciseInputManager.getKeysForDirection(PlayerSettings.player1.controls, noteDir);
  }

  function isKeyValid(key:FlxKey):Bool
  {
    @:privateAccess
    {
      return _preciseInputManager._keyListMap.exists(key);
    }
  }

  public function checkFlxKey(key:FlxKey):Bool
  {
    if (isKeyValid(key)) return check(cast key);
    return false;
  }

  public function checkDir(noteDir:NoteDirection):Bool
  {
    for (key in getKeysForDir(noteDir))
    {
      if (check(_preciseInputManager.getInputByKey(key)?.ID)) return true;
    }
    return false;
  }

  public var NOTE_LEFT(get, never):Bool;

  function get_NOTE_LEFT():Bool
    return checkDir(NoteDirection.LEFT);

  public var NOTE_DOWN(get, never):Bool;

  function get_NOTE_DOWN():Bool
    return checkDir(NoteDirection.DOWN);

  public var NOTE_UP(get, never):Bool;

  function get_NOTE_UP():Bool
    return checkDir(NoteDirection.UP);

  public var NOTE_RIGHT(get, never):Bool;

  function get_NOTE_RIGHT():Bool
    return checkDir(NoteDirection.RIGHT);
}

typedef PreciseInputEvent =
{
  /**
   * The direction of the input.
   */
  noteDirection:NoteDirection,

  /**
   * The timestamp of the input. Measured in nanoseconds.
   */
  timestamp:Int64,
};
