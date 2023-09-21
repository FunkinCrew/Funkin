package funkin.ui.haxeui.components;

import haxe.ui.components.DropDown;
import funkin.input.Cursor;
import haxe.ui.events.MouseEvent;

/**
 * A HaxeUI dropdown which:
 * - Changes the current cursor when hovered over.
 */
class FunkinDropDown extends DropDown
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
