package funkin.ui.debug.charting.dialogs;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.animation.AnimationBuilder;
import haxe.ui.styles.EasingFunction;
import haxe.ui.core.Component;
import haxe.ui.containers.menus.Menu;

// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorBaseMenu extends Menu
{
  var state:ChartEditorState;

  public function new(state:ChartEditorState)
  {
    super();

    this.state = state;

    // this.destroyOnClose = true;
  }
}
