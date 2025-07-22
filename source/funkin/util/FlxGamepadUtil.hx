package funkin.util;

import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import lime.ui.Gamepad as LimeGamepad;
import lime.ui.GamepadButton as LimeGamepadButton;

/**
 * Utilities for working with Flixel gamepads.
 */
@:nullSafety
class FlxGamepadUtil
{
  public static function getInputID(gamepad:FlxGamepad, button:LimeGamepadButton):FlxGamepadInputID
  {
    #if FLX_GAMEINPUT_API
    // FLX_GAMEINPUT_API internally assigns 6 axes to IDs 0-5, which LimeGamepadButton doesn't account for, so we need to offset the ID by 6.
    final OFFSET:Int = 6;
    #else
    final OFFSET:Int = 0;
    #end

    var result:FlxGamepadInputID = gamepad.mapping.getID(button + OFFSET);
    if (result == NONE) return NONE;
    return result;
  }

  public static function getLimeGamepad(input:FlxGamepad):Null<LimeGamepad>
  {
    #if FLX_GAMEINPUT_API @:privateAccess
    return input._device.getLimeGamepad();
    #else
    return null;
    #end
  }

  public static function getFlxGamepadByLimeGamepad(gamepad:LimeGamepad):FlxGamepad
  {
    // Why is this so elaborate?
    @:privateAccess
    {
      var gameInputDevice:openfl.ui.GameInputDevice = openfl.ui.GameInput.__getDevice(gamepad);
      var gamepadIndex:Int = FlxG.gamepads.findGamepadIndex(gameInputDevice);
      return FlxG.gamepads.getByID(gamepadIndex);
    }
  }
}
