package funkin.ui.haxeui.components;

import funkin.input.Cursor;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.menus.MenuCheckBox;

/**
 * A HaxeUI menu checkbox which:
 * - Changes the current cursor when hovered over.
 */
class FunkinMenuCheckBox extends MenuCheckBox
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
