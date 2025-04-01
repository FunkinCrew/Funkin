package funkin.ui.debug.charting.handlers;

import haxe.ui.focus.FocusManager;
import flixel.input.gamepad.FlxGamepad;
import haxe.ui.actions.ActionManager;
import haxe.ui.actions.IActionInputSource;
import haxe.ui.actions.ActionType;

/**
 * Yes, we're that crazy. Gamepad support for the chart editor.
 */
// @:nullSafety

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorGamepadHandler
{
  public static function handleGamepadControls(chartEditorState:ChartEditorState)
  {
    if (FlxG.gamepads.firstActive != null) handleGamepad(chartEditorState, FlxG.gamepads.firstActive);
  }

  /**
   * Handle context-generic binds for the gamepad.
   * @param chartEditorState The chart editor state.
   * @param gamepad The gamepad to handle.
   */
  static function handleGamepad(chartEditorState:ChartEditorState, gamepad:FlxGamepad):Void
  {
    if (chartEditorState.isHaxeUIFocused)
    {
      ChartEditorGamepadActionInputSource.instance.handleGamepad(gamepad);
    }
    else
    {
      handleGamepadLiveInputs(chartEditorState, gamepad);

      if (gamepad.justPressed.RIGHT_SHOULDER)
      {
        trace('Gamepad: Right shoulder pressed, toggling audio playback.');
        chartEditorState.toggleAudioPlayback();
      }

      if (gamepad.justPressed.START)
      {
        var minimal = gamepad.pressed.LEFT_SHOULDER;
        chartEditorState.hideAllToolboxes();
        trace('Gamepad: Start pressed, opening playtest (minimal: ${minimal})');
        chartEditorState.testSongInPlayState(minimal);
      }

      if (gamepad.justPressed.BACK && !gamepad.pressed.LEFT_SHOULDER)
      {
        trace('Gamepad: Back pressed, focusing on HaxeUI menu.');
        // FocusManager.instance.focus = chartEditorState.menubarMenuFile;
      }
      else if (gamepad.justPressed.BACK && gamepad.pressed.LEFT_SHOULDER)
      {
        trace('Gamepad: Back pressed, unfocusing on HaxeUI menu.');
        FocusManager.instance.focus = null;
      }
    }

    if (gamepad.justPressed.GUIDE)
    {
      trace('Gamepad: Guide pressed, quitting chart editor.');
      chartEditorState.quitChartEditor();
    }
  }

  static function handleGamepadLiveInputs(chartEditorState:ChartEditorState, gamepad:FlxGamepad):Void
  {
    // Place notes at the playhead with the gamepad.
    // Disable when we are interacting with HaxeUI.
    if (!(chartEditorState.isHaxeUIFocused || chartEditorState.isHaxeUIDialogOpen))
    {
      if (gamepad.justPressed.DPAD_LEFT) chartEditorState.placeNoteAtPlayhead(4);
      if (gamepad.justReleased.DPAD_LEFT) chartEditorState.finishPlaceNoteAtPlayhead(4);
      if (gamepad.justPressed.DPAD_DOWN) chartEditorState.placeNoteAtPlayhead(5);
      if (gamepad.justReleased.DPAD_DOWN) chartEditorState.finishPlaceNoteAtPlayhead(5);
      if (gamepad.justPressed.DPAD_UP) chartEditorState.placeNoteAtPlayhead(6);
      if (gamepad.justReleased.DPAD_UP) chartEditorState.finishPlaceNoteAtPlayhead(6);
      if (gamepad.justPressed.DPAD_RIGHT) chartEditorState.placeNoteAtPlayhead(7);
      if (gamepad.justReleased.DPAD_RIGHT) chartEditorState.finishPlaceNoteAtPlayhead(7);

      if (gamepad.justPressed.X) chartEditorState.placeNoteAtPlayhead(0);
      if (gamepad.justReleased.X) chartEditorState.finishPlaceNoteAtPlayhead(0);
      if (gamepad.justPressed.A) chartEditorState.placeNoteAtPlayhead(1);
      if (gamepad.justReleased.A) chartEditorState.finishPlaceNoteAtPlayhead(1);
      if (gamepad.justPressed.Y) chartEditorState.placeNoteAtPlayhead(2);
      if (gamepad.justReleased.Y) chartEditorState.finishPlaceNoteAtPlayhead(2);
      if (gamepad.justPressed.B) chartEditorState.placeNoteAtPlayhead(3);
      if (gamepad.justReleased.B) chartEditorState.finishPlaceNoteAtPlayhead(3);
    }
  }
}

class ChartEditorGamepadActionInputSource implements IActionInputSource
{
  public static var instance:ChartEditorGamepadActionInputSource = new ChartEditorGamepadActionInputSource();

  public function new() {}

  public function start():Void {}

  /**
   * Handle HaxeUI-specific binds for the gamepad.
   * Only called when the HaxeUI menu is focused.
   * @param chartEditorState The chart editor state.
   * @param gamepad The gamepad to handle.
   */
  public function handleGamepad(gamepad:FlxGamepad):Void
  {
    if (gamepad.justPressed.DPAD_LEFT)
    {
      trace('Gamepad: DPAD_LEFT pressed, moving left.');
      ActionManager.instance.actionStart(ActionType.LEFT, this);
    }
    else if (gamepad.justReleased.DPAD_LEFT)
    {
      ActionManager.instance.actionEnd(ActionType.LEFT, this);
    }

    if (gamepad.justPressed.DPAD_RIGHT)
    {
      trace('Gamepad: DPAD_RIGHT pressed, moving right.');
      ActionManager.instance.actionStart(ActionType.RIGHT, this);
    }
    else if (gamepad.justReleased.DPAD_RIGHT)
    {
      ActionManager.instance.actionEnd(ActionType.RIGHT, this);
    }

    if (gamepad.justPressed.DPAD_UP)
    {
      trace('Gamepad: DPAD_UP pressed, moving up.');
      ActionManager.instance.actionStart(ActionType.UP, this);
    }
    else if (gamepad.justReleased.DPAD_UP)
    {
      ActionManager.instance.actionEnd(ActionType.UP, this);
    }

    if (gamepad.justPressed.DPAD_DOWN)
    {
      trace('Gamepad: DPAD_DOWN pressed, moving down.');
      ActionManager.instance.actionStart(ActionType.DOWN, this);
    }
    else if (gamepad.justReleased.DPAD_DOWN)
    {
      ActionManager.instance.actionEnd(ActionType.DOWN, this);
    }

    if (gamepad.justPressed.A)
    {
      trace('Gamepad: A pressed, confirmingg.');
      ActionManager.instance.actionStart(ActionType.CONFIRM, this);
    }
    else if (gamepad.justReleased.A)
    {
      ActionManager.instance.actionEnd(ActionType.CONFIRM, this);
    }

    if (gamepad.justPressed.B)
    {
      trace('Gamepad: B pressed, cancelling.');
      ActionManager.instance.actionStart(ActionType.CANCEL, this);
    }
    else if (gamepad.justReleased.B)
    {
      ActionManager.instance.actionEnd(ActionType.CANCEL, this);
    }

    if (gamepad.justPressed.LEFT_TRIGGER)
    {
      trace('Gamepad: LEFT_TRIGGER pressed, moving to previous item.');
      ActionManager.instance.actionStart(ActionType.PREVIOUS, this);
    }
    else if (gamepad.justReleased.LEFT_TRIGGER)
    {
      ActionManager.instance.actionEnd(ActionType.PREVIOUS, this);
    }

    if (gamepad.justPressed.RIGHT_TRIGGER)
    {
      trace('Gamepad: RIGHT_TRIGGER pressed, moving to next item.');
      ActionManager.instance.actionStart(ActionType.NEXT, this);
    }
    else if (gamepad.justReleased.RIGHT_TRIGGER)
    {
      ActionManager.instance.actionEnd(ActionType.NEXT, this);
    }
  }
}
