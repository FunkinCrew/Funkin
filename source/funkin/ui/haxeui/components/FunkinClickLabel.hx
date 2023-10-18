package funkin.ui.haxeui.components;

import haxe.ui.components.Label;
import funkin.input.Cursor;
import haxe.ui.events.MouseEvent;

/**
 * A HaxeUI label which:
 * - Changes the current cursor when hovered over (assume an onClick handler will be added!).
 */
class FunkinClickLabel extends Label
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
