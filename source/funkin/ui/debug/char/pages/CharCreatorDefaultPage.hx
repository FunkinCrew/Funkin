package funkin.ui.debug.char.pages;

import haxe.ui.containers.Box;
import haxe.ui.containers.menus.Menu;
import flixel.group.FlxSpriteGroup;

class CharCreatorDefaultPage extends FlxSpriteGroup
{
  var daState:CharCreatorState;

  override public function new(state:CharCreatorState)
  {
    super();
    daState = state;
  }

  // override these bad boys for functionality
  public function performCleanup() {}

  public function fillUpBottomBar(left:Box, middle:Box, right:Box) {}

  public function fillUpPageSettings(item:Menu) {}

  public function onDialogUpdate(dialog:funkin.ui.debug.char.components.dialogs.DefaultPageDialog) {}
}
