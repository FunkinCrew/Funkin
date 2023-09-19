package funkin.ui.haxeui.components;

import haxe.ui.components.HorizontalSlider;
import funkin.input.Cursor;
import haxe.ui.events.MouseEvent;

/**
 * A HaxeUI horizontal slider which:
 * - Changes the current cursor when hovered over.
 */
class FunkinHorizontalSlider extends HorizontalSlider
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
