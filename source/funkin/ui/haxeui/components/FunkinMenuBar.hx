package funkin.ui.haxeui.components;

import funkin.input.Cursor;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.core.CompositeBuilder;

/**
 * A HaxeUI menu bar which:
 * - Changes the current cursor when each button is hovered over.
 */
class FunkinMenuBar extends MenuBar
{
  public function new()
  {
    super();

    registerListeners();
  }

  private function registerListeners():Void
  {
    var builder = cast(this._compositeBuilder, MenuBar.Builder);
    for (button in builder._buttons)
    {
      button.onMouseOver = handleMouseOver;
      button.onMouseOut = handleMouseOut;
    }
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
