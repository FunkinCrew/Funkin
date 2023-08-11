package funkin;

import flixel.util.FlxDirectionFlags;
import flixel.FlxObject;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionInputAnalog.FlxActionInputAnalogClickAndDragMouseMotion;
import flixel.input.actions.FlxActionInputDigital;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionSet;
import flixel.input.android.FlxAndroidKey;
import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseButton.FlxMouseButtonID;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.ui.Haptic;

/**
 * Since, in many cases multiple actions should use similar keys, we don't want the
 * rebinding UI to list every action. ActionBinders are what the user percieves as
 * an input so, for instance, they can't set jump-press and jump-release to different keys.
 */
enum Control
{
  // List notes in order from left to right on gameplay screen.
  NOTE_LEFT;
  NOTE_DOWN;
  NOTE_UP;
  NOTE_RIGHT;
  UI_UP;
  UI_LEFT;
  UI_RIGHT;
  UI_DOWN;
  RESET;
  ACCEPT;
  BACK;
  PAUSE;
  CUTSCENE_ADVANCE;
  CUTSCENE_SKIP;
  VOLUME_UP;
  VOLUME_DOWN;
  VOLUME_MUTE;
  #if CAN_CHEAT
  CHEAT;
  #end
}

@:enum
abstract Action(String) to String from String
{
  var UI_UP = "ui_up";
  var UI_LEFT = "ui_left";
  var UI_RIGHT = "ui_right";
  var UI_DOWN = "ui_down";
  var UI_UP_P = "ui_up-press";
  var UI_LEFT_P = "ui_left-press";
  var UI_RIGHT_P = "ui_right-press";
  var UI_DOWN_P = "ui_down-press";
  var UI_UP_R = "ui_up-release";
  var UI_LEFT_R = "ui_left-release";
  var UI_RIGHT_R = "ui_right-release";
  var UI_DOWN_R = "ui_down-release";
  var NOTE_UP = "note_up";
  var NOTE_LEFT = "note_left";
  var NOTE_RIGHT = "note_right";
  var NOTE_DOWN = "note_down";
  var NOTE_UP_P = "note_up-press";
  var NOTE_LEFT_P = "note_left-press";
  var NOTE_RIGHT_P = "note_right-press";
  var NOTE_DOWN_P = "note_down-press";
  var NOTE_UP_R = "note_up-release";
  var NOTE_LEFT_R = "note_left-release";
  var NOTE_RIGHT_R = "note_right-release";
  var NOTE_DOWN_R = "note_down-release";
  var ACCEPT = "accept";
  var BACK = "back";
  var PAUSE = "pause";
  var CUTSCENE_ADVANCE = "cutscene_advance";
  var CUTSCENE_SKIP = "cutscene_skip";
  var VOLUME_UP = "volume_up";
  var VOLUME_DOWN = "volume_down";
  var VOLUME_MUTE = "volume_mute";
  var RESET = "reset";
  #if CAN_CHEAT
  var CHEAT = "cheat";
  #end
}

enum Device
{
  Keys;
  Gamepad(id:Int);
}

enum KeyboardScheme
{
  Solo;
  Duo(first:Bool);
  None;
  Custom;
}

/**
 * A list of actions that a player would invoke via some input device.
 * Uses FlxActions to funnel various inputs to a single action.
 */
class Controls extends FlxActionSet
{
  var _ui_up = new FlxActionDigital(Action.UI_UP);
  var _ui_left = new FlxActionDigital(Action.UI_LEFT);
  var _ui_right = new FlxActionDigital(Action.UI_RIGHT);
  var _ui_down = new FlxActionDigital(Action.UI_DOWN);
  var _ui_upP = new FlxActionDigital(Action.UI_UP_P);
  var _ui_leftP = new FlxActionDigital(Action.UI_LEFT_P);
  var _ui_rightP = new FlxActionDigital(Action.UI_RIGHT_P);
  var _ui_downP = new FlxActionDigital(Action.UI_DOWN_P);
  var _ui_upR = new FlxActionDigital(Action.UI_UP_R);
  var _ui_leftR = new FlxActionDigital(Action.UI_LEFT_R);
  var _ui_rightR = new FlxActionDigital(Action.UI_RIGHT_R);
  var _ui_downR = new FlxActionDigital(Action.UI_DOWN_R);
  var _note_up = new FlxActionDigital(Action.NOTE_UP);
  var _note_left = new FlxActionDigital(Action.NOTE_LEFT);
  var _note_right = new FlxActionDigital(Action.NOTE_RIGHT);
  var _note_down = new FlxActionDigital(Action.NOTE_DOWN);
  var _note_upP = new FlxActionDigital(Action.NOTE_UP_P);
  var _note_leftP = new FlxActionDigital(Action.NOTE_LEFT_P);
  var _note_rightP = new FlxActionDigital(Action.NOTE_RIGHT_P);
  var _note_downP = new FlxActionDigital(Action.NOTE_DOWN_P);
  var _note_upR = new FlxActionDigital(Action.NOTE_UP_R);
  var _note_leftR = new FlxActionDigital(Action.NOTE_LEFT_R);
  var _note_rightR = new FlxActionDigital(Action.NOTE_RIGHT_R);
  var _note_downR = new FlxActionDigital(Action.NOTE_DOWN_R);
  var _accept = new FlxActionDigital(Action.ACCEPT);
  var _back = new FlxActionDigital(Action.BACK);
  var _pause = new FlxActionDigital(Action.PAUSE);
  var _reset = new FlxActionDigital(Action.RESET);
  var _cutscene_advance = new FlxActionDigital(Action.CUTSCENE_ADVANCE);
  var _cutscene_skip = new FlxActionDigital(Action.CUTSCENE_SKIP);
  var _volume_up = new FlxActionDigital(Action.VOLUME_UP);
  var _volume_down = new FlxActionDigital(Action.VOLUME_DOWN);
  var _volume_mute = new FlxActionDigital(Action.VOLUME_MUTE);
  #if CAN_CHEAT
  var _cheat = new FlxActionDigital(Action.CHEAT);
  #end

  var byName:Map<String, FlxActionDigital> = new Map<String, FlxActionDigital>();

  public var gamepadsAdded:Array<Int> = [];
  public var keyboardScheme = KeyboardScheme.None;

  public var UI_UP(get, never):Bool;

  inline function get_UI_UP()
    return _ui_up.check();

  public var UI_LEFT(get, never):Bool;

  inline function get_UI_LEFT()
    return _ui_left.check();

  public var UI_RIGHT(get, never):Bool;

  inline function get_UI_RIGHT()
    return _ui_right.check();

  public var UI_DOWN(get, never):Bool;

  inline function get_UI_DOWN()
    return _ui_down.check();

  public var UI_UP_P(get, never):Bool;

  inline function get_UI_UP_P()
    return _ui_upP.check();

  public var UI_LEFT_P(get, never):Bool;

  inline function get_UI_LEFT_P()
    return _ui_leftP.check();

  public var UI_RIGHT_P(get, never):Bool;

  inline function get_UI_RIGHT_P()
    return _ui_rightP.check();

  public var UI_DOWN_P(get, never):Bool;

  inline function get_UI_DOWN_P()
    return _ui_downP.check();

  public var UI_UP_R(get, never):Bool;

  inline function get_UI_UP_R()
    return _ui_upR.check();

  public var UI_LEFT_R(get, never):Bool;

  inline function get_UI_LEFT_R()
    return _ui_leftR.check();

  public var UI_RIGHT_R(get, never):Bool;

  inline function get_UI_RIGHT_R()
    return _ui_rightR.check();

  public var UI_DOWN_R(get, never):Bool;

  inline function get_UI_DOWN_R()
    return _ui_downR.check();

  public var NOTE_UP(get, never):Bool;

  inline function get_NOTE_UP()
    return _note_up.check();

  public var NOTE_LEFT(get, never):Bool;

  inline function get_NOTE_LEFT()
    return _note_left.check();

  public var NOTE_RIGHT(get, never):Bool;

  inline function get_NOTE_RIGHT()
    return _note_right.check();

  public var NOTE_DOWN(get, never):Bool;

  inline function get_NOTE_DOWN()
    return _note_down.check();

  public var NOTE_UP_P(get, never):Bool;

  inline function get_NOTE_UP_P()
    return _note_upP.check();

  public var NOTE_LEFT_P(get, never):Bool;

  inline function get_NOTE_LEFT_P()
    return _note_leftP.check();

  public var NOTE_RIGHT_P(get, never):Bool;

  inline function get_NOTE_RIGHT_P()
    return _note_rightP.check();

  public var NOTE_DOWN_P(get, never):Bool;

  inline function get_NOTE_DOWN_P()
    return _note_downP.check();

  public var NOTE_UP_R(get, never):Bool;

  inline function get_NOTE_UP_R()
    return _note_upR.check();

  public var NOTE_LEFT_R(get, never):Bool;

  inline function get_NOTE_LEFT_R()
    return _note_leftR.check();

  public var NOTE_RIGHT_R(get, never):Bool;

  inline function get_NOTE_RIGHT_R()
    return _note_rightR.check();

  public var NOTE_DOWN_R(get, never):Bool;

  inline function get_NOTE_DOWN_R()
    return _note_downR.check();

  public var ACCEPT(get, never):Bool;

  inline function get_ACCEPT()
    return _accept.check();

  public var BACK(get, never):Bool;

  inline function get_BACK()
    return _back.check();

  public var PAUSE(get, never):Bool;

  inline function get_PAUSE()
    return _pause.check();

  public var CUTSCENE_ADVANCE(get, never):Bool;

  inline function get_CUTSCENE_ADVANCE()
    return _cutscene_advance.check();

  public var CUTSCENE_SKIP(get, never):Bool;

  inline function get_CUTSCENE_SKIP()
    return _cutscene_skip.check();

  public var VOLUME_UP(get, never):Bool;

  inline function get_VOLUME_UP()
    return _volume_up.check();

  public var VOLUME_DOWN(get, never):Bool;

  inline function get_VOLUME_DOWN()
    return _volume_down.check();

  public var VOLUME_MUTE(get, never):Bool;

  inline function get_VOLUME_MUTE()
    return _volume_mute.check();

  public var RESET(get, never):Bool;

  inline function get_RESET()
    return _reset.check();

  #if CAN_CHEAT
  public var CHEAT(get, never):Bool;

  inline function get_CHEAT()
    return _cheat.check();
  #end

  public function new(name, scheme:KeyboardScheme = null)
  {
    super(name);

    add(_ui_up);
    add(_ui_left);
    add(_ui_right);
    add(_ui_down);
    add(_ui_upP);
    add(_ui_leftP);
    add(_ui_rightP);
    add(_ui_downP);
    add(_ui_upR);
    add(_ui_leftR);
    add(_ui_rightR);
    add(_ui_downR);
    add(_note_up);
    add(_note_left);
    add(_note_right);
    add(_note_down);
    add(_note_upP);
    add(_note_leftP);
    add(_note_rightP);
    add(_note_downP);
    add(_note_upR);
    add(_note_leftR);
    add(_note_rightR);
    add(_note_downR);
    add(_accept);
    add(_back);
    add(_pause);
    add(_cutscene_advance);
    add(_cutscene_skip);
    add(_volume_up);
    add(_volume_down);
    add(_volume_mute);
    add(_reset);
    #if CAN_CHEAT
    add(_cheat);
    #end

    for (action in digitalActions)
      byName[action.name] = action;

    if (scheme == null)
      scheme = None;

    setKeyboardScheme(scheme, false);
  }

  override function update()
  {
    super.update();
  }

  // inline
  public function checkByName(name:Action):Bool
  {
    #if debug
    if (!byName.exists(name))
      throw 'Invalid name: $name';
    #end
    return byName[name].check();
  }

  public function getKeysForAction(name:Action):Array<FlxKey> {
    #if debug
    if (!byName.exists(name))
      throw 'Invalid name: $name';
    #end

    return byName[name].inputs.map(function(input) return (input.device == KEYBOARD) ? input.inputID : null)
      .filter(function(key) return key != null);
  }

  public function getButtonsForAction(name:Action):Array<FlxGamepadInputID> {
    #if debug
    if (!byName.exists(name))
      throw 'Invalid name: $name';
    #end

    return byName[name].inputs.map(function(input) return (input.device == GAMEPAD) ? input.inputID : null)
      .filter(function(key) return key != null);
  }

  public function getDialogueName(action:FlxActionDigital):String
  {
    var input = action.inputs[0];
    return switch (input.device)
    {
      case KEYBOARD: return '[${(input.inputID : FlxKey)}]';
      case GAMEPAD: return '(${(input.inputID : FlxGamepadInputID)})';
      case device: throw 'unhandled device: $device';
    }
  }

  public function getDialogueNameFromToken(token:String):String
  {
    return getDialogueName(getActionFromControl(Control.createByName(token.toUpperCase())));
  }

  function getActionFromControl(control:Control):FlxActionDigital
  {
    return switch(control)
    {
      case UI_UP: _ui_up;
      case UI_DOWN: _ui_down;
      case UI_LEFT: _ui_left;
      case UI_RIGHT: _ui_right;
      case NOTE_UP: _note_up;
      case NOTE_DOWN: _note_down;
      case NOTE_LEFT: _note_left;
      case NOTE_RIGHT: _note_right;
      case ACCEPT: _accept;
      case BACK: _back;
      case PAUSE: _pause;
      case RESET: _reset;
      case CUTSCENE_ADVANCE: _cutscene_advance;
      case CUTSCENE_SKIP: _cutscene_skip;
      case VOLUME_UP: _volume_up;
      case VOLUME_DOWN: _volume_down;
      case VOLUME_MUTE: _volume_mute;
      #if CAN_CHEAT
      case CHEAT: _cheat;
      #end
    }
  }

  static function init():Void
  {
    var actions = new FlxActionManager();
    FlxG.inputs.add(actions);
  }

  /**
   * Calls a function passing each action bound by the specified control
   * @param control
   * @param func
   * @return ->Void)
   */
  function forEachBound(control:Control, func:FlxActionDigital->FlxInputState->Void)
  {
    switch(control)
    {
      case UI_UP:
        func(_ui_up, PRESSED);
        func(_ui_upP, JUST_PRESSED);
        func(_ui_upR, JUST_RELEASED);
      case UI_LEFT:
        func(_ui_left, PRESSED);
        func(_ui_leftP, JUST_PRESSED);
        func(_ui_leftR, JUST_RELEASED);
      case UI_RIGHT:
        func(_ui_right, PRESSED);
        func(_ui_rightP, JUST_PRESSED);
        func(_ui_rightR, JUST_RELEASED);
      case UI_DOWN:
        func(_ui_down, PRESSED);
        func(_ui_downP, JUST_PRESSED);
        func(_ui_downR, JUST_RELEASED);
      case NOTE_UP:
        func(_note_up, PRESSED);
        func(_note_upP, JUST_PRESSED);
        func(_note_upR, JUST_RELEASED);
      case NOTE_LEFT:
        func(_note_left, PRESSED);
        func(_note_leftP, JUST_PRESSED);
        func(_note_leftR, JUST_RELEASED);
      case NOTE_RIGHT:
        func(_note_right, PRESSED);
        func(_note_rightP, JUST_PRESSED);
        func(_note_rightR, JUST_RELEASED);
      case NOTE_DOWN:
        func(_note_down, PRESSED);
        func(_note_downP, JUST_PRESSED);
        func(_note_downR, JUST_RELEASED);
      case ACCEPT:
        func(_accept, JUST_PRESSED);
      case BACK:
        func(_back, JUST_PRESSED);
      case PAUSE:
        func(_pause, JUST_PRESSED);
      case CUTSCENE_ADVANCE:
        func(_cutscene_advance, JUST_PRESSED);
      case CUTSCENE_SKIP:
        func(_cutscene_skip, PRESSED);
      case VOLUME_UP:
        func(_volume_up, JUST_PRESSED);
      case VOLUME_DOWN:
        func(_volume_down, JUST_PRESSED);
      case VOLUME_MUTE:
        func(_volume_mute, JUST_PRESSED);
      case RESET:
        func(_reset, JUST_PRESSED);
      #if CAN_CHEAT
      case CHEAT:
        func(_cheat, JUST_PRESSED);
      #end
    }
  }

  public function replaceBinding(control:Control, device:Device, toAdd:Int, toRemove:Int)
  {
    if (toAdd == toRemove)
      return;

    switch(device)
    {
      case Keys:
        forEachBound(control, function(action, state) replaceKey(action, toAdd, toRemove, state));

      case Gamepad(id):
        forEachBound(control, function(action, state) replaceButton(action, id, toAdd, toRemove, state));
    }
  }

  function replaceKey(action:FlxActionDigital, toAdd:FlxKey, toRemove:FlxKey, state:FlxInputState)
  {
    if (action.inputs.length == 0) {
      // Add the keybind, don't replace.
      addKeys(action, [toAdd], state);
      return;
    }

    var hasReplaced:Bool = false;
    for (i in 0...action.inputs.length)
    {
      var input = action.inputs[i];
      if (input == null) continue;

      if (input.device == KEYBOARD && input.inputID == toRemove)
      {
        if (toAdd == FlxKey.NONE) {
          // Remove the keybind, don't replace.
          action.inputs.remove(input);
        } else {
          // Replace the keybind.
          @:privateAccess
          action.inputs[i].inputID = toAdd;
        }
        hasReplaced = true;
      }
    }

    if (!hasReplaced) {
      addKeys(action, [toAdd], state);
    }
  }

  function replaceButton(action:FlxActionDigital, deviceID:Int, toAdd:FlxGamepadInputID, toRemove:FlxGamepadInputID, state:FlxInputState)
  {
    if (action.inputs.length == 0) {
      addButtons(action, [toAdd], state, deviceID);
      return;
    }

    var hasReplaced:Bool = false;
    for (i in 0...action.inputs.length)
    {
      var input = action.inputs[i];
      if (input == null) continue;

      if (isGamepad(input, deviceID) && input.inputID == toRemove)
      {
        @:privateAccess
        action.inputs[i].inputID = toAdd;
        hasReplaced = true;
      }
    }

    if (!hasReplaced) {
      addButtons(action, [toAdd], state, deviceID);
    }
  }

  public function copyFrom(controls:Controls, ?device:Device)
  {
    for (name in controls.byName.keys())
    {
      var action = controls.byName[name];
      for (input in action.inputs)
      {
        if (device == null || isDevice(input, device))
          byName[name].add(cast input);
      }
    }

    switch(device)
    {
      case null:
        // add all
        for (gamepad in controls.gamepadsAdded)
          if (gamepadsAdded.indexOf(gamepad) == -1)
            gamepadsAdded.push(gamepad);

        mergeKeyboardScheme(controls.keyboardScheme);

      case Gamepad(id):
        gamepadsAdded.push(id);
      case Keys:
        mergeKeyboardScheme(controls.keyboardScheme);
    }
  }

  inline public function copyTo(controls:Controls, ?device:Device)
  {
    controls.copyFrom(this, device);
  }

  function mergeKeyboardScheme(scheme:KeyboardScheme):Void
  {
    if (scheme != None)
    {
      switch(keyboardScheme)
      {
        case None:
          keyboardScheme = scheme;
        default:
          keyboardScheme = Custom;
      }
    }
  }

  /**
   * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
   * If binder is a literal you can inline this
   */
  public function bindKeys(control:Control, keys:Array<FlxKey>)
  {
    forEachBound(control, function(action, state) addKeys(action, keys, state));
  }

  public function bindSwipe(control:Control, swipeDir:Int = FlxDirectionFlags.UP, ?swpLength:Float = 90)
  {
    forEachBound(control, function(action, press) action.add(new FlxActionInputDigitalMobileSwipeGameplay(swipeDir, press, swpLength)));
  }

  /**
   * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
   * If binder is a literal you can inline this
   */
  public function unbindKeys(control:Control, keys:Array<FlxKey>)
  {
    forEachBound(control, function(action, _) removeKeys(action, keys));
  }

  static function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState)
  {
    for (key in keys) {
      if (key == FlxKey.NONE) continue; // Ignore unbound keys.
      action.addKey(key, state);
    }
  }

  static function removeKeys(action:FlxActionDigital, keys:Array<FlxKey>)
  {
    var i = action.inputs.length;
    while (i-- > 0)
    {
      var input = action.inputs[i];
      if (input.device == KEYBOARD && keys.indexOf(cast input.inputID) != -1)
        action.remove(input);
    }
  }

  public function setKeyboardScheme(scheme:KeyboardScheme, reset = true)
  {
    if (reset)
      removeKeyboard();

    keyboardScheme = scheme;

    bindKeys(Control.UI_UP, getDefaultKeybinds(scheme, Control.UI_UP));
    bindKeys(Control.UI_DOWN, getDefaultKeybinds(scheme, Control.UI_DOWN));
    bindKeys(Control.UI_LEFT, getDefaultKeybinds(scheme, Control.UI_LEFT));
    bindKeys(Control.UI_RIGHT, getDefaultKeybinds(scheme, Control.UI_RIGHT));
    bindKeys(Control.NOTE_UP, getDefaultKeybinds(scheme, Control.NOTE_UP));
    bindKeys(Control.NOTE_DOWN, getDefaultKeybinds(scheme, Control.NOTE_DOWN));
    bindKeys(Control.NOTE_LEFT, getDefaultKeybinds(scheme, Control.NOTE_LEFT));
    bindKeys(Control.NOTE_RIGHT, getDefaultKeybinds(scheme, Control.NOTE_RIGHT));
    bindKeys(Control.ACCEPT, getDefaultKeybinds(scheme, Control.ACCEPT));
    bindKeys(Control.BACK, getDefaultKeybinds(scheme, Control.BACK));
    bindKeys(Control.PAUSE, getDefaultKeybinds(scheme, Control.PAUSE));
    bindKeys(Control.CUTSCENE_ADVANCE, getDefaultKeybinds(scheme, Control.CUTSCENE_ADVANCE));
    bindKeys(Control.CUTSCENE_SKIP, getDefaultKeybinds(scheme, Control.CUTSCENE_SKIP));
    bindKeys(Control.VOLUME_UP, getDefaultKeybinds(scheme, Control.VOLUME_UP));
    bindKeys(Control.VOLUME_DOWN, getDefaultKeybinds(scheme, Control.VOLUME_DOWN));
    bindKeys(Control.VOLUME_MUTE, getDefaultKeybinds(scheme, Control.VOLUME_MUTE));

    bindMobileLol();
  }

  function getDefaultKeybinds(scheme:KeyboardScheme, control:Control):Array<FlxKey> {
    switch (scheme) {
      case Solo:
        switch (control) {
          case Control.UI_UP: return [W, FlxKey.UP];
          case Control.UI_DOWN: return [S, FlxKey.DOWN];
          case Control.UI_LEFT: return [A, FlxKey.LEFT];
          case Control.UI_RIGHT: return [D, FlxKey.RIGHT];
          case Control.NOTE_UP: return [W, FlxKey.UP];
          case Control.NOTE_DOWN: return [S, FlxKey.DOWN];
          case Control.NOTE_LEFT: return [A, FlxKey.LEFT];
          case Control.NOTE_RIGHT: return [D, FlxKey.RIGHT];
          case Control.ACCEPT: return [Z, SPACE, ENTER];
          case Control.BACK: return [X, BACKSPACE, ESCAPE];
          case Control.PAUSE: return [P, ENTER, ESCAPE];
          case Control.CUTSCENE_ADVANCE: return [Z, ENTER];
          case Control.CUTSCENE_SKIP: return [P, ESCAPE];
          case Control.VOLUME_UP: return [PLUS, NUMPADPLUS];
          case Control.VOLUME_DOWN: return [MINUS, NUMPADMINUS];
          case Control.VOLUME_MUTE: return [ZERO, NUMPADZERO];
          case Control.RESET: return [R];
        }
      case Duo(true):
        switch (control) {
          case Control.UI_UP: return [W];
          case Control.UI_DOWN: return [S];
          case Control.UI_LEFT: return [A];
          case Control.UI_RIGHT: return [D];
          case Control.NOTE_UP: return [W];
          case Control.NOTE_DOWN: return [S];
          case Control.NOTE_LEFT: return [A];
          case Control.NOTE_RIGHT: return [D];
          case Control.ACCEPT: return [G, Z];
          case Control.BACK: return [H, X];
          case Control.PAUSE: return [ONE];
          case Control.CUTSCENE_ADVANCE: return [G, Z];
          case Control.CUTSCENE_SKIP: return [ONE];
          case Control.VOLUME_UP: return [PLUS];
          case Control.VOLUME_DOWN: return [MINUS];
          case Control.VOLUME_MUTE: return [ZERO];
          case Control.RESET: return [R];
        }
      case Duo(false):
        switch (control) {
          case Control.UI_UP: return [FlxKey.UP];
          case Control.UI_DOWN: return [FlxKey.DOWN];
          case Control.UI_LEFT: return [FlxKey.LEFT];
          case Control.UI_RIGHT: return [FlxKey.RIGHT];
          case Control.NOTE_UP: return [FlxKey.UP];
          case Control.NOTE_DOWN: return [FlxKey.DOWN];
          case Control.NOTE_LEFT: return [FlxKey.LEFT];
          case Control.NOTE_RIGHT: return [FlxKey.RIGHT];
          case Control.ACCEPT: return [ENTER];
          case Control.BACK: return [ESCAPE];
          case Control.PAUSE: return [ONE];
          case Control.CUTSCENE_ADVANCE: return [ENTER];
          case Control.CUTSCENE_SKIP: return [ONE];
          case Control.VOLUME_UP: return [NUMPADPLUS];
          case Control.VOLUME_DOWN: return [NUMPADMINUS];
          case Control.VOLUME_MUTE: return [NUMPADZERO];
          case Control.RESET: return [R];
        }
      default:
        // Fallthrough.
    }

    return [];
  }

  function bindMobileLol()
  {
    #if FLX_TOUCH
    // MAKE BETTER TOUCH BIND CODE

    bindSwipe(Control.NOTE_UP, FlxDirectionFlags.UP, 40);
    bindSwipe(Control.NOTE_DOWN, FlxDirectionFlags.DOWN, 40);
    bindSwipe(Control.NOTE_LEFT, FlxDirectionFlags.LEFT, 40);
    bindSwipe(Control.NOTE_RIGHT, FlxDirectionFlags.RIGHT, 40);

    // feels more like drag when up/down are inversed
    bindSwipe(Control.UI_UP, FlxDirectionFlags.DOWN);
    bindSwipe(Control.UI_DOWN, FlxDirectionFlags.UP);
    bindSwipe(Control.UI_LEFT, FlxDirectionFlags.LEFT);
    bindSwipe(Control.UI_RIGHT, FlxDirectionFlags.RIGHT);
    #end

    #if android
    forEachBound(Control.BACK, function(action, pres)
    {
      action.add(new FlxActionInputDigitalAndroid(FlxAndroidKey.BACK, JUST_PRESSED));
    });
    #end
  }

  function removeKeyboard()
  {
    for (action in this.digitalActions)
    {
      var i = action.inputs.length;
      while (i-- > 0)
      {
        var input = action.inputs[i];
        if (input.device == KEYBOARD)
          action.remove(input);
      }
    }
  }

  public function addGamepadWithSaveData(id:Int, ?padData:Dynamic):Void
  {
    gamepadsAdded.push(id);

    fromSaveData(padData, Gamepad(id));
  }

  inline function addGamepadLiteral(id:Int, ?buttonMap:Map<Control, Array<FlxGamepadInputID>>):Void
  {
    gamepadsAdded.push(id);

    for (control in buttonMap.keys())
      bindButtons(control, id, buttonMap[control]);
  }

  public function removeGamepad(deviceID:Int = FlxInputDeviceID.ALL):Void
  {
    for (action in this.digitalActions)
    {
      var i = action.inputs.length;
      while (i-- > 0)
      {
        var input = action.inputs[i];
        if (isGamepad(input, deviceID))
          action.remove(input);
      }
    }

    gamepadsAdded.remove(deviceID);
  }

  public function addDefaultGamepad(id):Void
  {
    addGamepadLiteral(id, [

      Control.ACCEPT => getDefaultGamepadBinds(Control.ACCEPT),
      Control.BACK => getDefaultGamepadBinds(Control.BACK),
      Control.UI_UP => getDefaultGamepadBinds(Control.UI_UP),
      Control.UI_DOWN => getDefaultGamepadBinds(Control.UI_DOWN),
      Control.UI_LEFT => getDefaultGamepadBinds(Control.UI_LEFT),
      Control.UI_RIGHT => getDefaultGamepadBinds(Control.UI_RIGHT),
      // don't swap A/B or X/Y for switch on these. A is always the bottom face button
      Control.NOTE_UP => getDefaultGamepadBinds(Control.NOTE_UP),
      Control.NOTE_DOWN => getDefaultGamepadBinds(Control.NOTE_DOWN),
      Control.NOTE_LEFT => getDefaultGamepadBinds(Control.NOTE_LEFT),
      Control.NOTE_RIGHT => getDefaultGamepadBinds(Control.NOTE_RIGHT),
      Control.PAUSE => getDefaultGamepadBinds(Control.PAUSE),
      // Control.VOLUME_UP => [RIGHT_SHOULDER],
      // Control.VOLUME_DOWN => [LEFT_SHOULDER],
      // Control.VOLUME_MUTE => [RIGHT_TRIGGER],
      Control.CUTSCENE_ADVANCE => getDefaultGamepadBinds(Control.CUTSCENE_ADVANCE),
      Control.CUTSCENE_SKIP => getDefaultGamepadBinds(Control.CUTSCENE_SKIP),
      Control.RESET => getDefaultGamepadBinds(Control.RESET),
      #if CAN_CHEAT, Control.CHEAT => getDefaultGamepadBinds(Control.CHEAT) #end
    ]);
  }

  function getDefaultGamepadBinds(control:Control):Array<FlxGamepadInputID> {
    switch(control) {
      case Control.ACCEPT: return [#if switch B #else A #end];
      case Control.BACK: return [#if switch A #else B #end, FlxGamepadInputID.BACK];
      case Control.UI_UP: return [DPAD_UP, LEFT_STICK_DIGITAL_UP];
      case Control.UI_DOWN: return [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN];
      case Control.UI_LEFT: return [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT];
      case Control.UI_RIGHT: return [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT];
      case Control.NOTE_UP: return [DPAD_UP, Y, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP];
      case Control.NOTE_DOWN: return [DPAD_DOWN, A, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN];
      case Control.NOTE_LEFT: return [DPAD_LEFT, X, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT];
      case Control.NOTE_RIGHT: return [DPAD_RIGHT, B, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT];
      case Control.PAUSE: return [START];
      case Control.CUTSCENE_ADVANCE: return [A];
      case Control.CUTSCENE_SKIP: return [START];
      case Control.RESET: return [RIGHT_SHOULDER];
      #if CAN_CHEAT, Control.CHEAT: return [X]; #end
      default:
        // Fallthrough.
    }
    return [];
  }

  /**
   * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
   * If binder is a literal you can inline this
   */
  public function bindButtons(control:Control, id, buttons)
  {
    forEachBound(control, function(action, state) addButtons(action, buttons, state, id));
  }

  public function touchShit(control:Control, id)
  {
    forEachBound(control, function(action, state)
    {
      // action
    });
  }

  /**
   * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
   * If binder is a literal you can inline this
   */
  public function unbindButtons(control:Control, gamepadID:Int, buttons)
  {
    forEachBound(control, function(action, _) removeButtons(action, gamepadID, buttons));
  }

  inline static function addButtons(action:FlxActionDigital, buttons:Array<FlxGamepadInputID>, state, id)
  {
    for (button in buttons) {
      if (button == FlxGamepadInputID.NONE) continue; // Ignore unbound keys.
      action.addGamepad(button, state, id);
    }
  }

  static function removeButtons(action:FlxActionDigital, gamepadID:Int, buttons:Array<FlxGamepadInputID>)
  {
    var i = action.inputs.length;
    while (i-- > 0)
    {
      var input = action.inputs[i];
      if (isGamepad(input, gamepadID) && buttons.indexOf(cast input.inputID) != -1)
        action.remove(input);
    }
  }

  public function getInputsFor(control:Control, device:Device, ?list:Array<Int>):Array<Int>
  {
    if (list == null)
      list = [];

    switch(device)
    {
      case Keys:
        for (input in getActionFromControl(control).inputs)
        {
          if (input.device == KEYBOARD)
            list.push(input.inputID);
        }
      case Gamepad(id):
        for (input in getActionFromControl(control).inputs)
        {
          if (isGamepad(input, id))
            list.push(input.inputID);
        }
    }
    return list;
  }

  public function removeDevice(device:Device)
  {
    switch(device)
    {
      case Keys:
        setKeyboardScheme(None);
      case Gamepad(id):
        removeGamepad(id);
    }
  }

  /**
   * NOTE: When loading controls:
   * An EMPTY array means the control is uninitialized and needs to be reset to default.
   * An array with a single FlxKey.NONE means the control was intentionally unbound by the user.
   */
  public function fromSaveData(data:Dynamic, device:Device)
  {
    for (control in Control.createAll())
    {
      var inputs:Array<Int> = Reflect.field(data, control.getName());
      if (inputs != null)
      {
        if (inputs.length == 0) {
          trace('Control ${control} is missing bindings, resetting to default.');
          switch(device)
          {
            case Keys:
              bindKeys(control, getDefaultKeybinds(Solo, control));
            case Gamepad(id):
              bindButtons(control, id, getDefaultGamepadBinds(control));
          }
        } else if (inputs == [FlxKey.NONE]) {
          trace('Control ${control} is unbound, leaving it be.');
        } else {
          switch(device)
          {
            case Keys:
              bindKeys(control, inputs.copy());
            case Gamepad(id):
              bindButtons(control, id, inputs.copy());
          }
        }
      } else {
        trace('Control ${control} is missing bindings, resetting to default.');
        switch(device)
        {
          case Keys:
            bindKeys(control, getDefaultKeybinds(Solo, control));
          case Gamepad(id):
            bindButtons(control, id, getDefaultGamepadBinds(control));
        }
      }
    }
  }

  /**
   * NOTE: When saving controls:
   * An EMPTY array means the control is uninitialized and needs to be reset to default.
   * An array with a single FlxKey.NONE means the control was intentionally unbound by the user.
   */
  public function createSaveData(device:Device):Dynamic
  {
    var isEmpty = true;
    var data = {};
    for (control in Control.createAll())
    {
      var inputs = getInputsFor(control, device);
      isEmpty = isEmpty && inputs.length == 0;

      if (inputs.length == 0) inputs = [FlxKey.NONE];

      Reflect.setField(data, control.getName(), inputs);
    }

    return isEmpty ? null : data;
  }

  static function isDevice(input:FlxActionInput, device:Device)
  {
    return switch(device)
    {
      case Keys: input.device == KEYBOARD;
      case Gamepad(id): isGamepad(input, id);
    }
  }

  inline static function isGamepad(input:FlxActionInput, deviceID:Int)
  {
    return input.device == GAMEPAD && (deviceID == FlxInputDeviceID.ALL || input.deviceID == deviceID);
  }
}

typedef SaveInputLists =
{
  ?keys:Array<Int>,
  ?pad:Array<Int>
};

typedef Swipes =
{
  ?initTouchPos:FlxPoint,
  ?touchAngle:Float,
  ?touchLength:Float,
  ?curTouchPos:FlxPoint
};

class FlxActionInputDigitalMobileSwipeGameplay extends FlxActionInputDigital
{
  var touchMap:Map<Int, Swipes> = new Map();

  var vibrationSteps:Int = 5;
  var curStep:Int = 5;
  var activateLength:Float = 90;
  var hapticPressure:Int = 100;

  public function new(swipeDir:Int = FlxDirectionFlags.ANY, Trigger:FlxInputState, ?swipeLength:Float = 90)
  {
    super(OTHER, swipeDir, Trigger);

    activateLength = swipeLength;
  }

  // fix right swipe
  // make so cant double swipe during gameplay
  // hold notes?

  override function update():Void
  {
    super.update();

    #if FLX_TOUCH
    for (touch in FlxG.touches.list)
    {
      if (touch.justPressed)
      {
        var pos:FlxPoint = new FlxPoint(touch.screenX, touch.screenY);
        var pos2:FlxPoint = new FlxPoint(touch.screenX, touch.screenY);

        var swp:Swipes =
          {
            initTouchPos: pos,
            curTouchPos: pos2,
            touchAngle: 0,
            touchLength: 0
          };
        touchMap[touch.touchPointID] = swp;

        curStep = 1;
        Haptic.vibrate(40, 70);
      }
      if (touch.pressed)
      {
        var daSwipe = touchMap[touch.touchPointID];

        daSwipe.curTouchPos.set(touch.screenX, touch.screenY);

        var dx = daSwipe.initTouchPos.x - touch.screenX;
        var dy = daSwipe.initTouchPos.y - touch.screenY;

        daSwipe.touchAngle = Math.atan2(dy, dx);
        daSwipe.touchLength = Math.sqrt(dx * dx + dy * dy);

        FlxG.watch.addQuick("LENGTH", daSwipe.touchLength);
        FlxG.watch.addQuick("ANGLE", FlxAngle.asDegrees(daSwipe.touchAngle));

        if (daSwipe.touchLength >= (activateLength / vibrationSteps) * curStep)
        {
          curStep += 1;
          // Haptic.vibrate(Std.int(hapticPressure / (curStep * 1.5)), 50);
        }
      }

      if (touch.justReleased)
      {
        touchMap.remove(touch.touchPointID);
      }

      /* switch (inputID)
        {
          case FlxDirectionFlags.UP:
            return
          case FlxDirectionFlags.DOWN:
        }
       */
    }
    #end
  }

  override public function check(Action:FlxAction):Bool
  {
    for (swp in touchMap)
    {
      var degAngle = FlxAngle.asDegrees(swp.touchAngle);

      switch(trigger)
      {
        case JUST_PRESSED:
          if (swp.touchLength >= activateLength)
          {
            switch(inputID)
            {
              case FlxDirectionFlags.UP:
                if (degAngle >= 45 && degAngle <= 90 + 45) return properTouch(swp);
              case FlxDirectionFlags.DOWN:
                if (-degAngle >= 45 && -degAngle <= 90 + 45) return properTouch(swp);
              case FlxDirectionFlags.LEFT:
                if (degAngle <= 45 && -degAngle <= 45) return properTouch(swp);
              case FlxDirectionFlags.RIGHT:
                if (degAngle >= 90 + 45 && degAngle <= -90 + -45) return properTouch(swp);
            }
          }
        default:
      }
    }

    return false;
  }

  function properTouch(swipe:Swipes):Bool
  {
    curStep = 1;
    Haptic.vibrate(100, 30);
    swipe.initTouchPos.set(swipe.curTouchPos.x, swipe.curTouchPos.y);
    return true;
  }
}

// Maybe this can be committed to main HaxeFlixel repo?
#if android
class FlxActionInputDigitalAndroid extends FlxActionInputDigital
{
  /**
   * Android buttons action input
   * @param	androidKeyID Key identifier (FlxAndroidKey.BACK, FlxAndroidKey.MENU... those are the only 2 android specific ones)
   * @param	Trigger What state triggers this action (PRESSED, JUST_PRESSED, RELEASED, JUST_RELEASED)
   */
  public function new(androidKeyID:FlxAndroidKey, Trigger:FlxInputState)
  {
    super(FlxInputDevice.OTHER, androidKeyID, Trigger);
  }

  override public function check(Action:FlxAction):Bool
  {
    returnswitch(trigger)
    {
      #if android
      case PRESSED: FlxG.android.checkStatus(inputID, PRESSED) || FlxG.android.checkStatus(inputID, PRESSED);
      case RELEASED: FlxG.android.checkStatus(inputID, RELEASED) || FlxG.android.checkStatus(inputID, JUST_RELEASED);
      case JUST_PRESSED: FlxG.android.checkStatus(inputID, JUST_PRESSED);
      case JUST_RELEASED: FlxG.android.checkStatus(inputID, JUST_RELEASED);
      #end

      default: false;
    }
  }
}
#end
