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
  public static function format(id:Int, device:Device):String
  {
    return switch (device)
    {
      case Keys: getKeyName(id);
      case Gamepad(gamepadID): getButtonName(id, FlxG.gamepads.getByID(gamepadID));
    }
  }

  public static function getKeyName(id:Int):String
  {
    return switch (id)
    {
      case ZERO: "0";
      case ONE: "1";
      case TWO: "2";
      case THREE: "3";
      case FOUR: "4";
      case FIVE: "5";
      case SIX: "6";
      case SEVEN: "7";
      case EIGHT: "8";
      case NINE: "9";
      case PAGEUP: "PgUp";
      case PAGEDOWN: "PgDown";
      // case HOME          : "Hm";
      // case END           : "End";
      // case INSERT        : "Ins";
      // case ESCAPE        : "Esc";
      // case MINUS         : "-";
      // case PLUS          : "+";
      // case DELETE        : "Del";
      case BACKSPACE: "BckSpc";
      case LBRACKET: "[";
      case RBRACKET: "]";
      case BACKSLASH: "\\";
      case CAPSLOCK: "Caps";
      case SEMICOLON: ";";
      case QUOTE: "'";
      // case ENTER         : "Ent";
      // case SHIFT         : "Shf";
      case COMMA: ",";
      case PERIOD: ".";
      case SLASH: "/";
      case GRAVEACCENT: "`";
      case CONTROL: "Ctrl";
      case ALT: "Alt";
      // case SPACE         : "Spc";
      // case UP            : "Up";
      // case DOWN          : "Dn";
      // case LEFT          : "Lf";
      // case RIGHT         : "Rt";
      // case TAB           : "Tab";
      case PRINTSCREEN: "PrtScrn";
      case NUMPADZERO: "#0";
      case NUMPADONE: "#1";
      case NUMPADTWO: "#2";
      case NUMPADTHREE: "#3";
      case NUMPADFOUR: "#4";
      case NUMPADFIVE: "#5";
      case NUMPADSIX: "#6";
      case NUMPADSEVEN: "#7";
      case NUMPADEIGHT: "#8";
      case NUMPADNINE: "#9";
      case NUMPADMINUS: "#-";
      case NUMPADPLUS: "#+";
      case NUMPADPERIOD: "#.";
      case NUMPADMULTIPLY: "#*";
      default: titleCase(FlxKey.toStringMap[id] ?? '?');
    }
  }

  static var dirReg = ~/^(l|r).?-(left|right|down|up)$/;

  inline static public function getButtonName(id:Int, gamepad:FlxGamepad):String
  {
    return switch (gamepad.getInputLabel(id))
    {
      case null, "": shortenButtonName(FlxGamepadInputID.toStringMap[id]);
      case label: shortenButtonName(label);
    }
  }

  static function shortenButtonName(name:Null<String>)
  {
    return switch (name == null ? "" : name.toLowerCase())
    {
      case "": "[?]";
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
        dirReg.matched(1).toUpperCase() + " " + titleCase(dirReg.matched(2));
      case label: titleCase(label);
    }
  }

  inline static function titleCaseTrim(str:String, length = 8)
  {
    return str.charAt(0).toUpperCase() + str.substr(1, length - 1).toLowerCase();
  }

  inline static function titleCase(str:String)
  {
    return str.charAt(0).toUpperCase() + str.substr(1).toLowerCase();
  }

  inline static public function parsePadName(name:String):ControllerName
  {
    return ControllerName.parseName(name);
  }

  inline static public function getPadName(gamepad:FlxGamepad):ControllerName
  {
    return ControllerName.getName(gamepad);
  }

  inline static public function getPadNameById(id:Int):ControllerName
  {
    return ControllerName.getNameById(id);
  }
}

@:nullSafety
@:forward
enum abstract ControllerName(String) from String to String
{
  var OUYA = "Ouya";
  var PS4 = "PS4";
  var LOGI = "Logi";
  var XBOX = "XBox";
  var XINPUT = "XInput";
  var WII = "Wii";
  var PRO_CON = "Pro_Con";
  var JOYCONS = "Joycons";
  var JOYCON_L = "Joycon_L";
  var JOYCON_R = "Joycon_R";
  var MFI = "MFI";
  var PAD = "Pad";

  static public function getAssetByDevice(device:Device):String
  {
    return switch (device)
    {
      case Keys: getAsset(null);
      case Gamepad(id): getAsset(FlxG.gamepads.getByID(id));
    }
  }

  static public function getAsset(gamepad:Null<FlxGamepad>):String
  {
    if (gamepad == null) return 'assets/images/ui/devices/Keys.png';

    final name = parseName(gamepad.name);
    var path = 'assets/images/ui/devices/$name.png';
    if (openfl.utils.Assets.exists(path)) return path;

    return 'assets/images/ui/devices/Pad.png';
  }

  inline static public function getNameById(id:Int):ControllerName
    return getName(FlxG.gamepads.getByID(id));

  inline static public function getName(gamepad:FlxGamepad):ControllerName
    return parseName(gamepad.name);

  static public function parseName(name:String):ControllerName
  {
    name = name.toLowerCase().remove("-").remove("_");
    return if (name.contains("ouya")) OUYA; else if (name.contains("wireless controller")
      || name.contains("ps4")) PS4; else if (name.contains("logitech")) LOGI; else if (name.contains("xbox")) XBOX else if (name.contains("xinput"))
      XINPUT; else if (name.contains("nintendo rvlcnt01tr")
      || name.contains("nintendo rvlcnt01")) WII; else if (name.contains("mayflash wiimote pc adapter")) WII; else if (name.contains("pro controller"))
      PRO_CON; else if (name.contains("joycon l+r")) JOYCONS; else if (name.contains("joycon (l)")) JOYCON_L; else if (name.contains("joycon (r)"))
      JOYCON_R; else if (name.contains("mfi")) MFI; else PAD;
  }
}
