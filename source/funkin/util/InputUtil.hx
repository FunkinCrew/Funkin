package funkin.util;

import funkin.input.Controls.Device;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

using flixel.util.FlxStringUtil;

/**
 * Utilities for working with inputs.
 */
@:nullSafety
class InputUtil
{
  /**
   * Format a key or button for the given device.
   *
   * @param id The key or button to format.
   * @param device The input device the key or button belongs to.
   * @return A human readable string representing the button.
   */
  public static function format(id:Int, device:Device):String
  {
    return switch (device)
    {
      case Keys:
        getKeyName(id);
      case Gamepad(gamepadID):
        FlxG.gamepads.getByID(gamepadID) != null ? getButtonName(id, FlxG.gamepads.getByID(gamepadID)) : 'N/A';
    }
  }

  /**
   * Returns true if all of the keys in keyArray are being pressed,
   * but also only fires once on the last key in the array being justPressed
   * @param keyArray An array of FlxKeys
   * @return Bool True if all of the keys in keyArray are being pressed, with at least one of them being in a JUST_PRESSED state
   */
  public static function allPressedWithDebounce(keyArray:Array<FlxKey>):Bool
  {
    return allPressed(keyArray) && FlxG.keys.anyJustPressed(keyArray);
  }

  /**
   * Returns true if all of the keys in keyArray are being pressed
   * @param keyArray An array of FlxKeys
   * @return Bool True if all keys in keyArray are being pressed
   */
  public static function allPressed(keyArray:Array<FlxKey>):Bool
  {
    return !anyNotPressed(keyArray);
  }

  /**
   * Returns if any key is not being pressed (or just pressed)
   * @param keyArray An array of FlxKeys
   * @return Bool True if there's any key in keyArray that isn't being pressed
   */
  public static function anyNotPressed(keyArray:Array<FlxKey>):Bool
  {
    var isKeyNotPressed:FlxKey->Bool = key -> return FlxG.keys.checkStatus(key, RELEASED) || FlxG.keys.checkStatus(key, JUST_RELEASED);
    return keyArray.exists(isKeyNotPressed);
  }

  /**
   * Get the key name for a given key code.
   * @param id The key code to get the name of
   * @return The name of the key
   */
  public static function getKeyName(id:Int):String
  {
    return switch (id)
    {
      case ZERO:
        '0';
      case ONE:
        '1';
      case TWO:
        '2';
      case THREE:
        '3';
      case FOUR:
        '4';
      case FIVE:
        '5';
      case SIX:
        '6';
      case SEVEN:
        '7';
      case EIGHT:
        '8';
      case NINE:
        '9';
      case PAGEUP:
        'PgUp';
      case PAGEDOWN:
        'PgDown';
      // case HOME          : "Hm";
      // case END           : "End";
      // case INSERT        : "Ins";
      // case ESCAPE        : "Esc";
      // case MINUS         : "-";
      // case PLUS          : "+";
      // case DELETE        : "Del";
      case BACKSPACE:
        'BckSpc';
      case LBRACKET:
        '[';
      case RBRACKET:
        ']';
      case BACKSLASH:
        '\\';
      case CAPSLOCK:
        'Caps';
      case SEMICOLON:
        ';';
      case QUOTE:
        "'";
      // case ENTER         : "Ent";
      // case SHIFT         : "Shf";
      case COMMA:
        ',';
      case PERIOD:
        '.';
      case SLASH:
        '/';
      case GRAVEACCENT:
        '`';
      case CONTROL:
        'Ctrl';
      case ALT:
        'Alt';
      // case SPACE         : "Spc";
      // case UP            : "Up";
      // case DOWN          : "Dn";
      // case LEFT          : "Lf";
      // case RIGHT         : "Rt";
      // case TAB           : "Tab";
      case PRINTSCREEN:
        'PrtScrn';
      case NUMPADZERO:
        '#0';
      case NUMPADONE:
        '#1';
      case NUMPADTWO:
        '#2';
      case NUMPADTHREE:
        '#3';
      case NUMPADFOUR:
        '#4';
      case NUMPADFIVE:
        '#5';
      case NUMPADSIX:
        '#6';
      case NUMPADSEVEN:
        '#7';
      case NUMPADEIGHT:
        '#8';
      case NUMPADNINE:
        '#9';
      case NUMPADMINUS:
        '#-';
      case NUMPADPLUS:
        '#+';
      case NUMPADPERIOD:
        '#.';
      case NUMPADMULTIPLY:
        '#*';
      default:
        titleCase(FlxKey.toStringMap[id] ?? '?');
    }
  }

  static var dirReg:EReg = ~/^(l|r).?-(left|right|down|up)$/;

  /**
   * Get the shortened name of a button for a gamepad.
   *
   * @param id The button code to get the name of
   * @param gamepad The gamepad to get the name from
   * @return The name of the button
   */
  public static inline function getButtonName(id:Int, gamepad:FlxGamepad):String
  {
    return switch (gamepad.getInputLabel(id))
    {
      case null, '':
        shortenButtonName(FlxGamepadInputID.toStringMap[id]);
      case label:
        shortenButtonName(label);
    }
  }

  static function shortenButtonName(name:Null<String>):String
  {
    return switch (name == null ? '' : name.toLowerCase())
    {
      case '':
        '[?]';
      // case "square"  : "[]";
      // case "circle"  : "()";
      // case "triangle": "/\\";
      // case "plus"    : "+";
      // case "minus"   : "-";
      // case "home"    : "Hm";
      // case "guide"   : "Gd";
      // case "back"    : "Bk";
      // case "select"  : "Bk";
      // case "start"   : "St";
      // case "left"    : "Lf";
      // case "right"   : "Rt";
      // case "down"    : "Dn";
      // case "up"      : "Up";
      case dir if (dirReg.match(dir)):
        dirReg.matched(1).toUpperCase() + ' ' + titleCase(dirReg.matched(2));
      case label:
        titleCase(label);
    }
  }

  static inline function titleCase(str:String):String
  {
    return str.charAt(0).toUpperCase() + str.substr(1).toLowerCase();
  }

  /**
   * Get the name of a gamepad's controller type by parsing a name string.
   * @param name The controller name string to parse
   * @return The controller name
   */
  public static inline function parsePadName(name:String):ControllerName
  {
    return ControllerName.parseName(name);
  }

  /**
   * Get the name of a gamepad's controller type.
   * @param gamepad The gamepad to get the name from
   * @return The controller name.
   */
  public static inline function getPadName(gamepad:FlxGamepad):ControllerName
  {
    return ControllerName.getName(gamepad);
  }

  /**
   * Get the name of a gamepad's controller type.
   * @param id The integer ID of the gamepad device to access.
   * @return The controller name.
   */
  public static inline function getPadNameById(id:Int):ControllerName
  {
    return ControllerName.getNameById(id);
  }
}

/**
 * Represents a list of controller names, determined based on driver data.
 * Used for displaying names and button prompts in the UI.
 */
@:nullSafety @:forward
enum abstract ControllerName(String) from String to String
{
  /**
   * Ouya controller
   */
  public var OUYA = 'Ouya';

  /**
   * PlayStation 4 controller
   */
  public var PS4 = 'PS4';

  /**
   * Logitech controller
   */
  public var LOGI = 'Logi';

  /**
   * XBox controller
   */
  public var XBOX = 'XBox';

  /**
   * XInput controller
   */
  public var XINPUT = 'XInput';

  /**
   * Wii controller
   */
  public var WII = 'Wii';

  /**
   * Nintendo Switch Pro Controller
   */
  public var PRO_CON = 'Pro_Con';

  /**
   * Nintendo Switch JoyCons
   */
  public var JOYCONS = 'Joycons';

  /**
   * Nintendo Switch JoyCon (Left Only)
   */
  public var JOYCON_L = 'Joycon_L';

  /**
   * Nintendo Switch JoyCon (Right Only)
   */
  public var JOYCON_R = 'Joycon_R';

  /**
   * MFi controller
   */
  public var MFI = 'MFI';

  /**
   * A generic gamepad.
   */
  public var PAD = 'Pad';

  /**
   * Get the asset path for a device.
   * @param device The input device
   * @return The path to the device asset image
   */
  public static function getAssetByDevice(device:Device):String
  {
    return switch (device)
    {
      case Keys:
        getAsset(null);
      case Gamepad(id):
        getAsset(FlxG.gamepads.getByID(id));
    }
  }

  /**
   * Get the asset path for a gamepad.
   * @param gamepad The gamepad to get the asset for, or null for keyboard
   * @return The path to the device asset image
   */
  public static function getAsset(gamepad:Null<FlxGamepad>):String
  {
    if (gamepad == null) return 'assets/images/ui/devices/Keys.png';

    var name = parseName(gamepad.name);
    var path = 'assets/images/ui/devices/$name.png';
    if (openfl.utils.Assets.exists(path)) return path;

    return 'assets/images/ui/devices/Pad.png';
  }

  /**
   * Get the controller name for a gamepad by its ID.
   * @param id The gamepad ID
   * @return The controller name
   */
  public static inline function getNameById(id:Int):ControllerName
  {
    return getName(FlxG.gamepads.getByID(id));
  }

  /**
   * Get the controller name for a gamepad.
   * @param gamepad The gamepad to get the name from
   * @return The controller name
   */
  public static inline function getName(gamepad:FlxGamepad):ControllerName
  {
    return parseName(gamepad.name);
  }

  /**
   * Parse a controller name string and return the corresponding ControllerName.
   * @param name The controller name string to parse
   * @return The corresponding ControllerName enum value
   */
  public static function parseName(name:String):ControllerName
  {
    name = name.toLowerCase().remove('-').remove('_');

    if (name.contains('ouya'))
    {
      return OUYA;
    }
    else if (name.contains('wireless controller') || name.contains('ps4'))
    {
      return PS4;
    }
    else if (name.contains('logitech'))
    {
      return LOGI;
    }
    else if (name.contains('xbox'))
    {
      return XBOX;
    }
    else if (name.contains('xinput'))
    {
      return XINPUT;
    }
    else if (name.contains('nintendo rvlcnt01tr') || name.contains('nintendo rvlcnt01'))
    {
      return WII;
    }
    else if (name.contains('mayflash wiimote pc adapter'))
    {
      return WII;
    }
    else if (name.contains('pro controller'))
    {
      return PRO_CON;
    }
    else if (name.contains('joycon l+r'))
    {
      return JOYCONS;
    }
    else if (name.contains('joycon (l)'))
    {
      return JOYCON_L;
    }
    else if (name.contains('joycon (r)'))
    {
      return JOYCON_R;
    }
    else if (name.contains('mfi'))
    {
      return MFI;
    }
    else
    {
      return PAD;
    }
  }
}
