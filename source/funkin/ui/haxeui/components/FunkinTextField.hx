package funkin.ui.haxeui.components;

import haxe.ui.components.TextField;
import funkin.input.Cursor;
import haxe.ui.events.MouseEvent;

/**
 * A HaxeUI text field which:
 * - Changes the current cursor when hovered over.
 */
class FunkinTextField extends TextField
{
  public function new()
  {
    super();

    this.onMouseOver = handleMouseOver;
    this.onMouseOut = handleMouseOut;
  }

  private function handleMouseOver(event:MouseEvent)
  {
    Cursor.cursorMode = Text;
  }

  private function handleMouseOut(event:MouseEvent)
  {
    Cursor.cursorMode = Default;
  }
}
