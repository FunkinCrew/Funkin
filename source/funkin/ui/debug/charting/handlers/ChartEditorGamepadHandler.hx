package funkin.ui.debug.charting.handlers;

/**
 * Yes, we're that crazy. Gamepad support for the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorGamepadHandler
{
  public static function handleGamepadControls(chartEditorState:ChartEditorState)
  {
    if (FlxG.gamepads.firstActive == null) return;

    if (FlxG.gamepads.firstActive.justPressed.A)
    {
      // trace('Gamepad: A pressed');
    }
    if (FlxG.gamepads.firstActive.justPressed.B)
    {
      // trace('Gamepad: B pressed');
    }
    if (FlxG.gamepads.firstActive.justPressed.X)
    {
      // trace('Gamepad: X pressed');
    }
    if (FlxG.gamepads.firstActive.justPressed.Y)
    {
      // trace('Gamepad: Y pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.LEFT_SHOULDER)
    {
      // trace('Gamepad: LEFT_SHOULDER pressed');
    }
    if (FlxG.gamepads.firstActive.justPressed.RIGHT_SHOULDER)
    {
      // trace('Gamepad: RIGHT_SHOULDER pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.LEFT_STICK_CLICK)
    {
      // trace('Gamepad: LEFT_STICK_CLICK pressed');
    }
    if (FlxG.gamepads.firstActive.justPressed.RIGHT_STICK_CLICK)
    {
      // trace('Gamepad: RIGHT_STICK_CLICK pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.LEFT_TRIGGER)
    {
      // trace('Gamepad: LEFT_TRIGGER pressed');
    }
    if (FlxG.gamepads.firstActive.justPressed.RIGHT_TRIGGER)
    {
      // trace('Gamepad: RIGHT_TRIGGER pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.START)
    {
      // trace('Gamepad: START pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.BACK)
    {
      // trace('Gamepad: BACK pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.GUIDE)
    {
      // trace('Gamepad: GUIDE pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.DPAD_UP)
    {
      // trace('Gamepad: DPAD_UP pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.DPAD_DOWN)
    {
      // trace('Gamepad: DPAD_DOWN pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.DPAD_LEFT)
    {
      // trace('Gamepad: DPAD_LEFT pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.DPAD_RIGHT)
    {
      // trace('Gamepad: DPAD_RIGHT pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.LEFT_STICK_DIGITAL_UP)
    {
      // trace('Gamepad: LEFT_STICK_DIGITAL_UP pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.LEFT_STICK_DIGITAL_DOWN)
    {
      // trace('Gamepad: LEFT_STICK_DIGITAL_DOWN pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.LEFT_STICK_DIGITAL_LEFT)
    {
      // trace('Gamepad: LEFT_STICK_DIGITAL_LEFT pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.LEFT_STICK_DIGITAL_RIGHT)
    {
      // trace('Gamepad: LEFT_STICK_DIGITAL_RIGHT pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.RIGHT_STICK_DIGITAL_UP)
    {
      // trace('Gamepad: RIGHT_STICK_DIGITAL_UP pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.RIGHT_STICK_DIGITAL_DOWN)
    {
      // trace('Gamepad: RIGHT_STICK_DIGITAL_DOWN pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.RIGHT_STICK_DIGITAL_LEFT)
    {
      // trace('Gamepad: RIGHT_STICK_DIGITAL_LEFT pressed');
    }

    if (FlxG.gamepads.firstActive.justPressed.RIGHT_STICK_DIGITAL_RIGHT)
    {
      // trace('Gamepad: RIGHT_STICK_DIGITAL_RIGHT pressed');
    }
  }
}
