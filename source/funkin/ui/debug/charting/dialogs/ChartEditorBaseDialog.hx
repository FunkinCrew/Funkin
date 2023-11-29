package funkin.ui.debug.charting.dialogs;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.core.Component;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorBaseDialog extends Dialog
{
  var state:ChartEditorState;
  var params:DialogParams;

  var locked:Bool = false;

  public function new(state:ChartEditorState, params:DialogParams)
  {
    super();

    this.state = state;
    this.params = params;

    this.destroyOnClose = true;
    this.closable = params.closable ?? false;

    this.onDialogClosed = event -> onClose(event);
  }

  /**
   * Called when the dialog is closed.
   * Override this to add custom behavior.
   */
  public function onClose(event:DialogEvent):Void
  {
    state.isHaxeUIDialogOpen = false;
  }

  /**
   * Locks this dialog from interaction.
   * Use this when you want to prevent dialog interaction while another dialog is open.
   */
  public function lock():Void
  {
    this.locked = true;

    this.closable = false;
  }

  /**
   * Unlocks the dialog for interaction.
   */
  public function unlock():Void
  {
    this.locked = false;

    this.closable = params.closable ?? false;
  }
}

typedef DialogParams =
{
  ?closable:Bool,
  ?modal:Bool
};

typedef DialogDropTarget =
{
  component:Component,
  handler:String->Void
}
