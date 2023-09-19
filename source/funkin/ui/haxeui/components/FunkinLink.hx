package funkin.ui.haxeui.components;

import funkin.input.Cursor;
import haxe.ui.events.MouseEvent;
import haxe.ui.components.Link;

/**
 * A HaxeUI link which:
 * - Changes the current cursor when hovered over.
 */
class FunkinLink extends Link
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
