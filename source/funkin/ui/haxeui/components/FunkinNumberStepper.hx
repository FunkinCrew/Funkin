package funkin.ui.haxeui.components;

import haxe.ui.components.NumberStepper;
import funkin.input.Cursor;
import haxe.ui.events.MouseEvent;

/**
 * A HaxeUI number stepper which:
 * - Changes the current cursor when hovered over.
 */
class FunkinNumberStepper extends NumberStepper
{
  public function new()
  {
    super();

    this.onMouseOver = handleMouseOver;
    this.onMouseOut = handleMouseOut;
  }

  private function handleMouseOver(event:MouseEvent)
  {
    Cursor.cursorMode = Pointer;
  }

  private function handleMouseOut(event:MouseEvent)
  {
    Cursor.cursorMode = Default;
  }
}
