package funkin.input;

import flixel.input.gamepad.FlxGamepad;
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
 * A core class which handles receiving player input and interpreting it into game actions.
 */
class Controls extends FlxActionSet
{
  /**
   * A list of actions that a player would invoke via some input device.
   * Uses FlxActions to funnel various inputs to a single action.
   */
  var _ui_up = new FunkinAction(Action.UI_UP);

  var _ui_left = new FunkinAction(Action.UI_LEFT);
  var _ui_right = new FunkinAction(Action.UI_RIGHT);
  var _ui_down = new FunkinAction(Action.UI_DOWN);
  var _ui_upP = new FunkinAction(Action.UI_UP_P);
  var _ui_leftP = new FunkinAction(Action.UI_LEFT_P);
  var _ui_rightP = new FunkinAction(Action.UI_RIGHT_P);
  var _ui_downP = new FunkinAction(Action.UI_DOWN_P);
  var _ui_upR = new FunkinAction(Action.UI_UP_R);
  var _ui_leftR = new FunkinAction(Action.UI_LEFT_R);
  var _ui_rightR = new FunkinAction(Action.UI_RIGHT_R);
  var _ui_downR = new FunkinAction(Action.UI_DOWN_R);
  var _note_up = new FunkinAction(Action.NOTE_UP);
  var _note_left = new FunkinAction(Action.NOTE_LEFT);
  var _note_right = new FunkinAction(Action.NOTE_RIGHT);
  var _note_down = new FunkinAction(Action.NOTE_DOWN);
  var _note_upP = new FunkinAction(Action.NOTE_UP_P);
  var _note_leftP = new FunkinAction(Action.NOTE_LEFT_P);
  var _note_rightP = new FunkinAction(Action.NOTE_RIGHT_P);
  var _note_downP = new FunkinAction(Action.NOTE_DOWN_P);
  var _note_upR = new FunkinAction(Action.NOTE_UP_R);
  var _note_leftR = new FunkinAction(Action.NOTE_LEFT_R);
  var _note_rightR = new FunkinAction(Action.NOTE_RIGHT_R);
  var _note_downR = new FunkinAction(Action.NOTE_DOWN_R);
  var _accept = new FunkinAction(Action.ACCEPT);
  var _back = new FunkinAction(Action.BACK);
  var _pause = new FunkinAction(Action.PAUSE);
  var _reset = new FunkinAction(Action.RESET);
  var _window_screenshot = new FunkinAction(Action.WINDOW_SCREENSHOT);
  var _window_fullscreen = new FunkinAction(Action.WINDOW_FULLSCREEN);
  var _freeplay_favorite = new FunkinAction(Action.FREEPLAY_FAVORITE);
  var _freeplay_left = new FunkinAction(Action.FREEPLAY_LEFT);
  var _freeplay_right = new FunkinAction(Action.FREEPLAY_RIGHT);
  var _freeplay_char_select = new FunkinAction(Action.FREEPLAY_CHAR_SELECT);
  var _cutscene_advance = new FunkinAction(Action.CUTSCENE_ADVANCE);
  var _debug_menu = new FunkinAction(Action.DEBUG_MENU);
  var _debug_chart = new FunkinAction(Action.DEBUG_CHART);
  var _debug_stage = new FunkinAction(Action.DEBUG_STAGE);
  var _volume_up = new FunkinAction(Action.VOLUME_UP);
  var _volume_down = new FunkinAction(Action.VOLUME_DOWN);
  var _volume_mute = new FunkinAction(Action.VOLUME_MUTE);

  var byName:Map<String, FunkinAction> = new Map<String, FunkinAction>();

  public var gamepadsAdded:Array<Int> = [];
  public var keyboardScheme = KeyboardScheme.None;

  public var UI_UP(get, never):Bool;

  inline function get_UI_UP()
    return _ui_up.checkPressed();

  public var UI_LEFT(get, never):Bool;

  inline function get_UI_LEFT()
    return _ui_left.checkPressed();

  public var UI_RIGHT(get, never):Bool;

  inline function get_UI_RIGHT()
    return _ui_right.checkPressed();

  public var UI_DOWN(get, never):Bool;

  inline function get_UI_DOWN()
    return _ui_down.checkPressed();

  public var UI_UP_P(get, never):Bool;

  inline function get_UI_UP_P()
    return _ui_up.checkJustPressed();

  public var UI_LEFT_P(get, never):Bool;

  inline function get_UI_LEFT_P()
    return _ui_left.checkJustPressed();

  public var UI_RIGHT_P(get, never):Bool;

  inline function get_UI_RIGHT_P()
    return _ui_right.checkJustPressed();

  public var UI_DOWN_P(get, never):Bool;

  inline function get_UI_DOWN_P()
    return _ui_down.checkJustPressed();

  public var UI_UP_R(get, never):Bool;

  inline function get_UI_UP_R()
    return _ui_up.checkJustReleased();

  public var UI_LEFT_R(get, never):Bool;

  inline function get_UI_LEFT_R()
    return _ui_left.checkJustReleased();

  public var UI_RIGHT_R(get, never):Bool;

  inline function get_UI_RIGHT_R()
    return _ui_right.checkJustReleased();

  public var UI_DOWN_R(get, never):Bool;

  inline function get_UI_DOWN_R()
    return _ui_down.checkJustReleased();

  public var UI_UP_GAMEPAD(get, never):Bool;

  inline function get_UI_UP_GAMEPAD()
    return _ui_up.checkPressedGamepad();

  public var UI_LEFT_GAMEPAD(get, never):Bool;

  inline function get_UI_LEFT_GAMEPAD()
    return _ui_left.checkPressedGamepad();

  public var UI_RIGHT_GAMEPAD(get, never):Bool;

  inline function get_UI_RIGHT_GAMEPAD()
    return _ui_right.checkPressedGamepad();

  public var UI_DOWN_GAMEPAD(get, never):Bool;

  inline function get_UI_DOWN_GAMEPAD()
    return _ui_down.checkPressedGamepad();

  public var NOTE_UP(get, never):Bool;

  inline function get_NOTE_UP()
    return _note_up.checkPressed();

  public var NOTE_LEFT(get, never):Bool;

  inline function get_NOTE_LEFT()
    return _note_left.checkPressed();

  public var NOTE_RIGHT(get, never):Bool;

  inline function get_NOTE_RIGHT()
    return _note_right.checkPressed();

  public var NOTE_DOWN(get, never):Bool;

  inline function get_NOTE_DOWN()
    return _note_down.checkPressed();

  public var NOTE_UP_P(get, never):Bool;

  inline function get_NOTE_UP_P()
    return _note_up.checkJustPressed();

  public var NOTE_LEFT_P(get, never):Bool;

  inline function get_NOTE_LEFT_P()
    return _note_left.checkJustPressed();

  public var NOTE_RIGHT_P(get, never):Bool;

  inline function get_NOTE_RIGHT_P()
    return _note_right.checkJustPressed();

  public var NOTE_DOWN_P(get, never):Bool;

  inline function get_NOTE_DOWN_P()
    return _note_down.checkJustPressed();

  public var NOTE_UP_R(get, never):Bool;

  inline function get_NOTE_UP_R()
    return _note_up.checkJustReleased();

  public var NOTE_LEFT_R(get, never):Bool;

  inline function get_NOTE_LEFT_R()
    return _note_left.checkJustReleased();

  public var NOTE_RIGHT_R(get, never):Bool;

  inline function get_NOTE_RIGHT_R()
    return _note_right.checkJustReleased();

  public var NOTE_DOWN_R(get, never):Bool;

  inline function get_NOTE_DOWN_R()
    return _note_down.checkJustReleased();

  public var ACCEPT(get, never):Bool;

  inline function get_ACCEPT()
    return _accept.check();

  public var BACK(get, never):Bool;

  inline function get_BACK()
    return _back.check();

  public var PAUSE(get, never):Bool;

  inline function get_PAUSE()
    return _pause.check();

  public var RESET(get, never):Bool;

  inline function get_RESET()
    return _reset.check();

  public var WINDOW_FULLSCREEN(get, never):Bool;

  inline function get_WINDOW_FULLSCREEN()
    return _window_fullscreen.check();

  public var WINDOW_SCREENSHOT(get, never):Bool;

  inline function get_WINDOW_SCREENSHOT()
    return _window_screenshot.check();

  public var FREEPLAY_FAVORITE(get, never):Bool;

  inline function get_FREEPLAY_FAVORITE()
    return _freeplay_favorite.check();

  public var FREEPLAY_LEFT(get, never):Bool;

  inline function get_FREEPLAY_LEFT()
    return _freeplay_left.check();

  public var FREEPLAY_RIGHT(get, never):Bool;

  inline function get_FREEPLAY_RIGHT()
    return _freeplay_right.check();

  public var FREEPLAY_CHAR_SELECT(get, never):Bool;

  inline function get_FREEPLAY_CHAR_SELECT()
    return _freeplay_char_select.check();

  public var CUTSCENE_ADVANCE(get, never):Bool;

  inline function get_CUTSCENE_ADVANCE()
    return _cutscene_advance.check();

  public var DEBUG_MENU(get, never):Bool;

  inline function get_DEBUG_MENU()
    return _debug_menu.check();

  public var DEBUG_CHART(get, never):Bool;

  inline function get_DEBUG_CHART()
    return _debug_chart.check();

  public var DEBUG_STAGE(get, never):Bool;

  inline function get_DEBUG_STAGE()
    return _debug_stage.check();

  public var VOLUME_UP(get, never):Bool;

  inline function get_VOLUME_UP()
    return _volume_up.check();

  public var VOLUME_DOWN(get, never):Bool;

  inline function get_VOLUME_DOWN()
    return _volume_down.check();

  public var VOLUME_MUTE(get, never):Bool;

  inline function get_VOLUME_MUTE()
    return _volume_mute.check();

  public function new(name, scheme:KeyboardScheme = null)
  {
    super(name);

    add(_ui_up);
    add(_ui_left);
    add(_ui_right);
    add(_ui_down);
    add(_note_up);
    add(_note_left);
    add(_note_right);
    add(_note_down);
    add(_accept);
    add(_back);
    add(_pause);
    add(_reset);
    add(_window_screenshot);
    add(_window_fullscreen);
    add(_freeplay_favorite);
    add(_freeplay_left);
    add(_freeplay_right);
    add(_freeplay_char_select);
    add(_cutscene_advance);
    add(_debug_menu);
    add(_debug_chart);
    add(_debug_stage);
    add(_volume_up);
    add(_volume_down);
    add(_volume_mute);

    for (action in digitalActions)
    {
      if (Std.isOfType(action, FunkinAction))
      {
        var funkinAction:FunkinAction = cast action;
        byName[funkinAction.name] = funkinAction;
        if (funkinAction.namePressed != null) byName[funkinAction.namePressed] = funkinAction;
        if (funkinAction.nameReleased != null) byName[funkinAction.nameReleased] = funkinAction;
      }
    }

    if (scheme == null) scheme = None;

    setKeyboardScheme(scheme, false);
  }

  override function update()
  {
    super.update();
  }

  public function check(name:Action, trigger:FlxInputState = JUST_PRESSED, gamepadOnly:Bool = false):Bool
  {
    #if FEATURE_DEBUG_FUNCTIONS
    if (!byName.exists(name)) throw 'Invalid name: $name';
    #end

    var action = byName[name];
    if (gamepadOnly) return action.checkFiltered(trigger, GAMEPAD);
    else
      return action.checkFiltered(trigger);
  }

  public function getKeysForAction(name:Action):Array<FlxKey>
  {
    #if FEATURE_DEBUG_FUNCTIONS
    if (!byName.exists(name)) throw 'Invalid name: $name';
    #end

    // TODO: Revert to `.map().filter()` once HashLink doesn't complain anymore.
    var result:Array<FlxKey> = [];
    for (input in byName[name].inputs)
    {
      if (input.device == KEYBOARD) result.push(input.inputID);
    }
    return result;
  }

  public function getButtonsForAction(name:Action):Array<FlxGamepadInputID>
  {
    #if FEATURE_DEBUG_FUNCTIONS
    if (!byName.exists(name)) throw 'Invalid name: $name';
    #end

    var result:Array<FlxGamepadInputID> = [];
    for (input in byName[name].inputs)
    {
      if (input.device == GAMEPAD) result.push(input.inputID);
    }
    return result;
  }

  public function getDialogueName(action:FlxActionDigital, ?ignoreSurrounding:Bool = false):String
  {
    var input = action.inputs[0];
    if (ignoreSurrounding == false)
    {
      return switch (input.device)
      {
        case KEYBOARD: return '[${(input.inputID : FlxKey)}]';
        case GAMEPAD: return '(${(input.inputID : FlxGamepadInputID)})';
        case device: throw 'unhandled device: $device';
      }
    }
    else
    {
      return switch (input.device)
      {
        case KEYBOARD: return '${(input.inputID : FlxKey)}';
        case GAMEPAD: return '${(input.inputID : FlxGamepadInputID)}';
        case device: throw 'unhandled device: $device';
      }
    }
  }

  public function getDialogueNameFromToken(token:String, ?ignoreSurrounding:Bool = false):String
  {
    return getDialogueName(getActionFromControl(Control.createByName(token.toUpperCase())), ignoreSurrounding);
  }

  public function getDialogueNameFromControl(control:Control, ?ignoreSurrounding:Bool = false):String
  {
    return getDialogueName(getActionFromControl(control), ignoreSurrounding);
  }

  function getActionFromControl(control:Control):FlxActionDigital
  {
    return switch (control)
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
      case WINDOW_SCREENSHOT: _window_screenshot;
      case WINDOW_FULLSCREEN: _window_fullscreen;
      case FREEPLAY_FAVORITE: _freeplay_favorite;
      case FREEPLAY_LEFT: _freeplay_left;
      case FREEPLAY_RIGHT: _freeplay_right;
      case FREEPLAY_CHAR_SELECT: _freeplay_char_select;
      case CUTSCENE_ADVANCE: _cutscene_advance;
      case DEBUG_MENU: _debug_menu;
      case DEBUG_CHART: _debug_chart;
      case DEBUG_STAGE: _debug_stage;
      case VOLUME_UP: _volume_up;
      case VOLUME_DOWN: _volume_down;
      case VOLUME_MUTE: _volume_mute;
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
    switch (control)
    {
      case UI_UP:
        func(_ui_up, PRESSED);
        func(_ui_up, JUST_PRESSED);
        func(_ui_up, JUST_RELEASED);
      case UI_LEFT:
        func(_ui_left, PRESSED);
        func(_ui_left, JUST_PRESSED);
        func(_ui_left, JUST_RELEASED);
      case UI_RIGHT:
        func(_ui_right, PRESSED);
        func(_ui_right, JUST_PRESSED);
        func(_ui_right, JUST_RELEASED);
      case UI_DOWN:
        func(_ui_down, PRESSED);
        func(_ui_down, JUST_PRESSED);
        func(_ui_down, JUST_RELEASED);
      case NOTE_UP:
        func(_note_up, PRESSED);
        func(_note_up, JUST_PRESSED);
        func(_note_up, JUST_RELEASED);
      case NOTE_LEFT:
        func(_note_left, PRESSED);
        func(_note_left, JUST_PRESSED);
        func(_note_left, JUST_RELEASED);
      case NOTE_RIGHT:
        func(_note_right, PRESSED);
        func(_note_right, JUST_PRESSED);
        func(_note_right, JUST_RELEASED);
      case NOTE_DOWN:
        func(_note_down, PRESSED);
        func(_note_down, JUST_PRESSED);
        func(_note_down, JUST_RELEASED);
      case ACCEPT:
        func(_accept, JUST_PRESSED);
      case BACK:
        func(_back, JUST_PRESSED);
      case PAUSE:
        func(_pause, JUST_PRESSED);
      case RESET:
        func(_reset, JUST_PRESSED);
      case WINDOW_SCREENSHOT:
        func(_window_screenshot, JUST_PRESSED);
      case WINDOW_FULLSCREEN:
        func(_window_fullscreen, JUST_PRESSED);
      case FREEPLAY_FAVORITE:
        func(_freeplay_favorite, JUST_PRESSED);
      case FREEPLAY_LEFT:
        func(_freeplay_left, JUST_PRESSED);
      case FREEPLAY_RIGHT:
        func(_freeplay_right, JUST_PRESSED);
      case FREEPLAY_CHAR_SELECT:
        func(_freeplay_char_select, JUST_PRESSED);
      case CUTSCENE_ADVANCE:
        func(_cutscene_advance, JUST_PRESSED);
      case DEBUG_MENU:
        func(_debug_menu, JUST_PRESSED);
      case DEBUG_CHART:
        func(_debug_chart, JUST_PRESSED);
      case DEBUG_STAGE:
        func(_debug_stage, JUST_PRESSED);
      case VOLUME_UP:
        func(_volume_up, JUST_PRESSED);
      case VOLUME_DOWN:
        func(_volume_down, JUST_PRESSED);
      case VOLUME_MUTE:
        func(_volume_mute, JUST_PRESSED);
    }
  }

  public function replaceBinding(control:Control, device:Device, toAdd:Int, toRemove:Int)
  {
    if (toAdd == toRemove) return;

    switch (device)
    {
      case Keys:
        forEachBound(control, function(action, state) replaceKey(action, toAdd, toRemove, state));

      case Gamepad(id):
        forEachBound(control, function(action, state) replaceButton(action, id, toAdd, toRemove, state));
    }
  }

  function replaceKey(action:FlxActionDigital, toAdd:FlxKey, toRemove:FlxKey, state:FlxInputState)
  {
    if (action.inputs.length == 0)
    {
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
        if (toAdd == FlxKey.NONE)
        {
          // Remove the keybind, don't replace.
          action.inputs.remove(input);
        }
        else
        {
          // Replace the keybind.
          @:privateAccess
          action.inputs[i].inputID = toAdd;
        }
        hasReplaced = true;
      }
      else if (input.device == KEYBOARD && input.inputID == toAdd)
      {
        // This key is already bound!
        if (hasReplaced)
        {
          // Remove the duplicate keybind, don't replace.
          action.inputs.remove(input);
        }
        else
        {
          hasReplaced = true;
        }
      }
    }

    if (!hasReplaced)
    {
      addKeys(action, [toAdd], state);
    }
  }

  function replaceButton(action:FlxActionDigital, deviceID:Int, toAdd:FlxGamepadInputID, toRemove:FlxGamepadInputID, state:FlxInputState)
  {
    if (action.inputs.length == 0)
    {
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

    if (!hasReplaced)
    {
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
        if (device == null || isDevice(input, device)) byName[name].add(cast input);
      }
    }

    switch (device)
    {
      case null:
        // add all
        for (gamepad in controls.gamepadsAdded)
          if (gamepadsAdded.indexOf(gamepad) == -1) gamepadsAdded.push(gamepad);

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
      switch (keyboardScheme)
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
    for (key in keys)
    {
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
      if (input.device == KEYBOARD && keys.indexOf(cast input.inputID) != -1) action.remove(input);
    }
  }

  public function setKeyboardScheme(scheme:KeyboardScheme, reset = true)
  {
    if (reset) removeKeyboard();

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
    bindKeys(Control.RESET, getDefaultKeybinds(scheme, Control.RESET));
    bindKeys(Control.WINDOW_SCREENSHOT, getDefaultKeybinds(scheme, Control.WINDOW_SCREENSHOT));
    bindKeys(Control.WINDOW_FULLSCREEN, getDefaultKeybinds(scheme, Control.WINDOW_FULLSCREEN));
    bindKeys(Control.FREEPLAY_FAVORITE, getDefaultKeybinds(scheme, Control.FREEPLAY_FAVORITE));
    bindKeys(Control.FREEPLAY_LEFT, getDefaultKeybinds(scheme, Control.FREEPLAY_LEFT));
    bindKeys(Control.FREEPLAY_RIGHT, getDefaultKeybinds(scheme, Control.FREEPLAY_RIGHT));
    bindKeys(Control.FREEPLAY_CHAR_SELECT, getDefaultKeybinds(scheme, Control.FREEPLAY_CHAR_SELECT));
    bindKeys(Control.CUTSCENE_ADVANCE, getDefaultKeybinds(scheme, Control.CUTSCENE_ADVANCE));
    bindKeys(Control.DEBUG_MENU, getDefaultKeybinds(scheme, Control.DEBUG_MENU));
    bindKeys(Control.DEBUG_CHART, getDefaultKeybinds(scheme, Control.DEBUG_CHART));
    bindKeys(Control.DEBUG_STAGE, getDefaultKeybinds(scheme, Control.DEBUG_STAGE));
    bindKeys(Control.VOLUME_UP, getDefaultKeybinds(scheme, Control.VOLUME_UP));
    bindKeys(Control.VOLUME_DOWN, getDefaultKeybinds(scheme, Control.VOLUME_DOWN));
    bindKeys(Control.VOLUME_MUTE, getDefaultKeybinds(scheme, Control.VOLUME_MUTE));

    bindMobileLol();
  }

  function getDefaultKeybinds(scheme:KeyboardScheme, control:Control):Array<FlxKey>
  {
    switch (scheme)
    {
      case Solo:
        switch (control)
        {
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
          case Control.RESET: return [R];
          case Control.WINDOW_FULLSCREEN: return [F11]; // We use F for other things LOL.
          case Control.WINDOW_SCREENSHOT: return [F3];
          case Control.FREEPLAY_FAVORITE: return [F]; // Favorite a song on the menu
          case Control.FREEPLAY_LEFT: return [Q]; // Switch tabs on the menu
          case Control.FREEPLAY_RIGHT: return [E]; // Switch tabs on the menu
          case Control.FREEPLAY_CHAR_SELECT: return [TAB];
          case Control.CUTSCENE_ADVANCE: return [Z, ENTER];
          case Control.DEBUG_MENU: return [GRAVEACCENT];
          case Control.DEBUG_CHART: return [];
          case Control.DEBUG_STAGE: return [];
          case Control.VOLUME_UP: return [PLUS, NUMPADPLUS];
          case Control.VOLUME_DOWN: return [MINUS, NUMPADMINUS];
          case Control.VOLUME_MUTE: return [ZERO, NUMPADZERO];
        }
      case Duo(true):
        switch (control)
        {
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
          case Control.RESET: return [R];
          case Control.WINDOW_SCREENSHOT: return [F3];
          case Control.WINDOW_FULLSCREEN: return [F11];
          case Control.FREEPLAY_FAVORITE: return [F]; // Favorite a song on the menu
          case Control.FREEPLAY_LEFT: return [Q]; // Switch tabs on the menu
          case Control.FREEPLAY_RIGHT: return [E]; // Switch tabs on the menu
          case Control.FREEPLAY_CHAR_SELECT: return [TAB];
          case Control.CUTSCENE_ADVANCE: return [G, Z];
          case Control.DEBUG_MENU: return [GRAVEACCENT];
          case Control.DEBUG_CHART: return [];
          case Control.DEBUG_STAGE: return [];
          case Control.VOLUME_UP: return [PLUS];
          case Control.VOLUME_DOWN: return [MINUS];
          case Control.VOLUME_MUTE: return [ZERO];
        }
      case Duo(false):
        switch (control)
        {
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
          case Control.RESET: return [R];
          case Control.WINDOW_SCREENSHOT: return [];
          case Control.WINDOW_FULLSCREEN: return [];
          case Control.FREEPLAY_FAVORITE: return [];
          case Control.FREEPLAY_LEFT: return [];
          case Control.FREEPLAY_RIGHT: return [];
          case Control.FREEPLAY_CHAR_SELECT: return [];
          case Control.CUTSCENE_ADVANCE: return [ENTER];
          case Control.DEBUG_MENU: return [];
          case Control.DEBUG_CHART: return [];
          case Control.DEBUG_STAGE: return [];
          case Control.VOLUME_UP: return [NUMPADPLUS];
          case Control.VOLUME_DOWN: return [NUMPADMINUS];
          case Control.VOLUME_MUTE: return [NUMPADZERO];
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
    forEachBound(Control.BACK, function(action, pres) {
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
        if (input.device == KEYBOARD) action.remove(input);
      }
    }
  }

  public function addGamepadWithSaveData(id:Int, ?padData:Dynamic):Void
  {
    gamepadsAdded.push(id);

    fromSaveData(padData, Gamepad(id));
  }

  public function getGamepadIds():Array<Int>
  {
    return gamepadsAdded;
  }

  public function getGamepads():Array<FlxGamepad>
  {
    return [for (id in gamepadsAdded) FlxG.gamepads.getByID(id)];
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
        if (isGamepad(input, deviceID)) action.remove(input);
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
      Control.NOTE_UP => getDefaultGamepadBinds(Control.NOTE_UP),
      Control.NOTE_DOWN => getDefaultGamepadBinds(Control.NOTE_DOWN),
      Control.NOTE_LEFT => getDefaultGamepadBinds(Control.NOTE_LEFT),
      Control.NOTE_RIGHT => getDefaultGamepadBinds(Control.NOTE_RIGHT),
      Control.PAUSE => getDefaultGamepadBinds(Control.PAUSE),
      Control.RESET => getDefaultGamepadBinds(Control.RESET),
      Control.WINDOW_FULLSCREEN => getDefaultGamepadBinds(Control.WINDOW_FULLSCREEN),
      Control.WINDOW_SCREENSHOT => getDefaultGamepadBinds(Control.WINDOW_SCREENSHOT),
      Control.CUTSCENE_ADVANCE => getDefaultGamepadBinds(Control.CUTSCENE_ADVANCE),
      Control.FREEPLAY_FAVORITE => getDefaultGamepadBinds(Control.FREEPLAY_FAVORITE),
      Control.FREEPLAY_LEFT => getDefaultGamepadBinds(Control.FREEPLAY_LEFT),
      Control.FREEPLAY_RIGHT => getDefaultGamepadBinds(Control.FREEPLAY_RIGHT),
      Control.VOLUME_UP => getDefaultGamepadBinds(Control.VOLUME_UP),
      Control.VOLUME_DOWN => getDefaultGamepadBinds(Control.VOLUME_DOWN),
      Control.VOLUME_MUTE => getDefaultGamepadBinds(Control.VOLUME_MUTE),
      Control.DEBUG_MENU => getDefaultGamepadBinds(Control.DEBUG_MENU),
      Control.DEBUG_CHART => getDefaultGamepadBinds(Control.DEBUG_CHART),
      Control.DEBUG_STAGE => getDefaultGamepadBinds(Control.DEBUG_STAGE),
    ]);
  }

  function getDefaultGamepadBinds(control:Control):Array<FlxGamepadInputID>
  {
    switch (control)
    {
      case Control.ACCEPT:
        return [#if switch B #else A #end];
      case Control.BACK:
        return [#if switch A #else B #end];
      case Control.UI_UP:
        return [DPAD_UP, LEFT_STICK_DIGITAL_UP];
      case Control.UI_DOWN:
        return [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN];
      case Control.UI_LEFT:
        return [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT];
      case Control.UI_RIGHT:
        return [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT];
      case Control.NOTE_UP:
        return [DPAD_UP, Y, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP];
      case Control.NOTE_DOWN:
        return [DPAD_DOWN, A, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN];
      case Control.NOTE_LEFT:
        return [DPAD_LEFT, X, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT];
      case Control.NOTE_RIGHT:
        return [DPAD_RIGHT, B, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT];
      case Control.PAUSE:
        return [START];
      case Control.RESET:
        return [FlxGamepadInputID.BACK]; // Back (i.e. Select)
      case Control.WINDOW_FULLSCREEN:
        [];
      case Control.WINDOW_SCREENSHOT:
        [];
      case Control.CUTSCENE_ADVANCE:
        return [A];
      case Control.FREEPLAY_FAVORITE:
        [FlxGamepadInputID.BACK]; // Back (i.e. Select)
      case Control.FREEPLAY_LEFT:
        [LEFT_SHOULDER];
      case Control.FREEPLAY_RIGHT:
        [RIGHT_SHOULDER];
      case Control.VOLUME_UP:
        [];
      case Control.VOLUME_DOWN:
        [];
      case Control.VOLUME_MUTE:
        [];
      case Control.DEBUG_MENU:
        [];
      case Control.DEBUG_CHART:
        [];
      case Control.DEBUG_STAGE:
        [];
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
    forEachBound(control, function(action, state) {
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
    for (button in buttons)
    {
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
      if (isGamepad(input, gamepadID) && buttons.indexOf(cast input.inputID) != -1) action.remove(input);
    }
  }

  public function getInputsFor(control:Control, device:Device, ?list:Array<Int>):Array<Int>
  {
    if (list == null) list = [];

    switch (device)
    {
      case Keys:
        for (input in getActionFromControl(control).inputs)
        {
          if (input.device == KEYBOARD) list.push(input.inputID);
        }
      case Gamepad(id):
        for (input in getActionFromControl(control).inputs)
        {
          if (isGamepad(input, id)) list.push(input.inputID);
        }
    }
    return list;
  }

  public function removeDevice(device:Device)
  {
    switch (device)
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
  public function fromSaveData(data:Dynamic, device:Device):Void
  {
    for (control in Control.createAll())
    {
      var inputs:Array<Int> = Reflect.field(data, control.getName());
      inputs = inputs?.distinct();
      if (inputs != null)
      {
        if (inputs.length == 0)
        {
          trace('Control ${control} is missing bindings, resetting to default.');
          switch (device)
          {
            case Keys:
              bindKeys(control, getDefaultKeybinds(Solo, control));
            case Gamepad(id):
              bindButtons(control, id, getDefaultGamepadBinds(control));
          }
        }
        else if (inputs == [FlxKey.NONE])
        {
          trace('Control ${control} is unbound, leaving it be.');
        }
        else
        {
          switch (device)
          {
            case Keys:
              bindKeys(control, inputs.copy());
            case Gamepad(id):
              bindButtons(control, id, inputs.copy());
          }
        }
      }
      else
      {
        trace('Control ${control} is missing bindings, resetting to default.');
        switch (device)
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

      if (inputs.length == 0)
      {
        inputs = [FlxKey.NONE];
      }
      else
      {
        inputs = inputs.distinct();
      }

      Reflect.setField(data, control.getName(), inputs);
    }

    return isEmpty ? null : data;
  }

  static function isDevice(input:FlxActionInput, device:Device)
  {
    return switch (device)
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

/**
 * An FlxActionDigital with additional functionality, including:
 * - Combining `pressed` and `released` inputs into one action.
 * - Filtering by input method (`KEYBOARD`, `MOUSE`, `GAMEPAD`, etc).
 */
class FunkinAction extends FlxActionDigital
{
  public var namePressed(default, null):Null<String>;
  public var nameReleased(default, null):Null<String>;

  var cache:Map<String, {timestamp:Int, value:Bool}> = [];

  public function new(?name:String = "", ?namePressed:String, ?nameReleased:String)
  {
    super(name);

    this.namePressed = namePressed;
    this.nameReleased = nameReleased;
  }

  /**
   * Input checks default to whether the input was just pressed, on any input device.
   */
  public override function check():Bool
  {
    return checkFiltered(JUST_PRESSED);
  }

  /**
   * Check whether the input is currently being held.
   */
  public function checkPressed():Bool
  {
    return checkFiltered(PRESSED);
  }

  /**
   * Check whether the input is currently being held, and was not held last frame.
   */
  public function checkJustPressed():Bool
  {
    return checkFiltered(JUST_PRESSED);
  }

  /**
   * Check whether the input is not currently being held.
   */
  public function checkReleased():Bool
  {
    return checkFiltered(RELEASED);
  }

  /**
   * Check whether the input is not currently being held, and was held last frame.
   */
  public function checkJustReleased():Bool
  {
    return checkFiltered(JUST_RELEASED);
  }

  /**
   * Check whether the input is currently being held by a gamepad device.
   */
  public function checkPressedGamepad():Bool
  {
    return checkFiltered(PRESSED, GAMEPAD);
  }

  /**
   * Check whether the input is currently being held by a gamepad device, and was not held last frame.
   */
  public function checkJustPressedGamepad():Bool
  {
    return checkFiltered(JUST_PRESSED, GAMEPAD);
  }

  /**
   * Check whether the input is not currently being held by a gamepad device.
   */
  public function checkReleasedGamepad():Bool
  {
    return checkFiltered(RELEASED, GAMEPAD);
  }

  /**
   * Check whether the input is not currently being held by a gamepad device, and was held last frame.
   */
  public function checkJustReleasedGamepad():Bool
  {
    return checkFiltered(JUST_RELEASED, GAMEPAD);
  }

  public function checkMultiFiltered(?filterTriggers:Array<FlxInputState>, ?filterDevices:Array<FlxInputDevice>):Bool
  {
    if (filterTriggers == null)
    {
      filterTriggers = [PRESSED, JUST_PRESSED];
    }
    if (filterDevices == null)
    {
      filterDevices = [];
    }

    // Perform checkFiltered for each combination.
    for (i in filterTriggers)
    {
      if (filterDevices.length == 0)
      {
        if (checkFiltered(i))
        {
          return true;
        }
      }
      else
      {
        for (j in filterDevices)
        {
          if (checkFiltered(i, j))
          {
            return true;
          }
        }
      }
    }
    return false;
  }

  /**
   * Performs the functionality of `FlxActionDigital.check()`, but with optional filters.
   * @param action The action to check for.
   * @param filterTrigger Optionally filter by trigger condition (`JUST_PRESSED`, `PRESSED`, `JUST_RELEASED`, `RELEASED`).
   * @param filterDevice Optionally filter by device (`KEYBOARD`, `MOUSE`, `GAMEPAD`, `OTHER`).
   */
  public function checkFiltered(?filterTrigger:FlxInputState, ?filterDevice:FlxInputDevice):Bool
  {
    // The normal

    // Make sure we only update the inputs once per frame.
    var key = '${filterTrigger}:${filterDevice}';
    var cacheEntry = cache.get(key);

    if (cacheEntry != null && cacheEntry.timestamp == FlxG.game.ticks)
    {
      return cacheEntry.value;
    }
    // Use a for loop instead so we can remove inputs while iterating.

    // We don't return early because we need to call check() on ALL inputs.
    var result = false;
    var len = inputs != null ? inputs.length : 0;
    for (i in 0...len)
    {
      var j = len - i - 1;
      var input = inputs[j];

      // Filter out dead inputs.
      if (input.destroyed)
      {
        inputs.splice(j, 1);
        continue;
      }

      // Update the input.
      input.update();

      // Check whether the input is the right trigger.
      if (filterTrigger != null && input.trigger != filterTrigger)
      {
        continue;
      }

      // Check whether the input is the right device.
      if (filterDevice != null && input.device != filterDevice)
      {
        continue;
      }

      // Check whether the input has triggered.
      if (input.check(this))
      {
        result = true;
      }
    }

    // We need to cache this result.
    cache.set(key, {timestamp: FlxG.game.ticks, value: result});

    return result;
  }
}

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

      switch (trigger)
      {
        case JUST_PRESSED:
          if (swp.touchLength >= activateLength)
          {
            switch (inputID)
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
    return switch (trigger)
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

/**
 * Since, in many cases multiple actions should use similar keys, we don't want the
 * rebinding UI to list every action. ActionBinders are what the user percieves as
 * an input so, for instance, they can't set jump-press and jump-release to different keys.
 */
enum Control
{
  // NOTE
  NOTE_LEFT;
  NOTE_DOWN;
  NOTE_UP;
  NOTE_RIGHT;
  // UI
  UI_UP;
  UI_LEFT;
  UI_RIGHT;
  UI_DOWN;
  RESET;
  ACCEPT;
  BACK;
  PAUSE;
  // CUTSCENE
  CUTSCENE_ADVANCE;
  // FREEPLAY
  FREEPLAY_FAVORITE;
  FREEPLAY_LEFT;
  FREEPLAY_RIGHT;
  FREEPLAY_CHAR_SELECT;
  // WINDOW
  WINDOW_SCREENSHOT;
  WINDOW_FULLSCREEN;
  // VOLUME
  VOLUME_UP;
  VOLUME_DOWN;
  VOLUME_MUTE;
  // DEBUG
  DEBUG_MENU;
  DEBUG_CHART;
  DEBUG_STAGE;
}

enum abstract Action(String) to String from String
{
  // NOTE
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
  // UI
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
  var ACCEPT = "accept";
  var BACK = "back";
  var PAUSE = "pause";
  var RESET = "reset";
  // WINDOW
  var WINDOW_FULLSCREEN = "window_fullscreen";
  var WINDOW_SCREENSHOT = "window_screenshot";
  // CUTSCENE
  var CUTSCENE_ADVANCE = "cutscene_advance";
  // FREEPLAY
  var FREEPLAY_FAVORITE = "freeplay_favorite";
  var FREEPLAY_LEFT = "freeplay_left";
  var FREEPLAY_RIGHT = "freeplay_right";
  var FREEPLAY_CHAR_SELECT = "freeplay_char_select";
  // VOLUME
  var VOLUME_UP = "volume_up";
  var VOLUME_DOWN = "volume_down";
  var VOLUME_MUTE = "volume_mute";
  // DEBUG
  var DEBUG_MENU = "debug_menu";
  var DEBUG_CHART = "debug_chart";
  var DEBUG_STAGE = "debug_stage";
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
