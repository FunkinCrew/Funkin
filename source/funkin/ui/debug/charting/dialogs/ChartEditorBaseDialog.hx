package funkin.ui.debug.charting.dialogs;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.animation.AnimationBuilder;
import haxe.ui.styles.EasingFunction;
import haxe.ui.core.Component;

// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.

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

  private override function onReady():Void
  {
    _overlay.opacity = 0;
    fadeInDialogOverlay();
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

  static final OVERLAY_EASE_DURATION:Float = 5.0;
  static final OVERLAY_EASE_TYPE:String = "linear";

  function fadeInDialogOverlay():Void
  {
    if (!modal)
    {
      trace('Dialog is not modal, skipping overlay fade...');
      return;
    }

    if (_overlay == null)
    {
      trace('[WARN] Dialog overlay is null, skipping overlay fade...');
      return;
    }

    var builder = new AnimationBuilder(_overlay, OVERLAY_EASE_DURATION, "linear");
    builder.setPosition(0, "opacity", 0, true); // 0% absolute
    builder.setPosition(100, "opacity", 1, true);

    trace('Fading in dialog overlay...');
    builder.play();
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
