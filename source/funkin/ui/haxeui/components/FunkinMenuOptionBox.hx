package funkin.ui.haxeui.components;

import haxe.ui.containers.menus.MenuOptionBox;
import funkin.input.Cursor;
import haxe.ui.events.MouseEvent;

/**
 * A HaxeUI menu option box which:
 * - Changes the current cursor when hovered over.
 */
class FunkinMenuOptionBox extends MenuOptionBox
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
