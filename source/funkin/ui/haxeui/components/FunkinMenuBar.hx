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

  private function registerListeners():Void {}

  private function handleMouseOver(event:MouseEvent)
  {
    Cursor.cursorMode = Pointer;
  }

  private function handleMouseOut(event:MouseEvent)
  {
    Cursor.cursorMode = Default;
  }
}
