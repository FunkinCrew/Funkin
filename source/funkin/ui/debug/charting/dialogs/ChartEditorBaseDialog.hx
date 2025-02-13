package funkin.ui.debug.charting.dialogs;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.animation.AnimationBuilder;
import haxe.ui.core.Component;

// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorBaseDialog extends Dialog
{
  var chartEditorState:ChartEditorState;
  var params:DialogParams;

  var locked:Bool = false;

  public function new(chartEditorState:ChartEditorState, params:DialogParams)
  {
    super();

    this.chartEditorState = chartEditorState;
    this.params = params;

    this.destroyOnClose = true;
    this.closable = params.closable ?? false;

    this.onDialogClosed = event -> onClose(event);
  }

  public override function showDialog(modal:Bool = true):Void
  {
    super.showDialog(modal);
    fadeInComponent(this, 1);
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
    chartEditorState.isHaxeUIDialogOpen = false;
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

  static final OVERLAY_EASE_DURATION:Float = 0.2;
  static final OVERLAY_EASE_TYPE:String = "easeOut";

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

    fadeInComponent(_overlay, 0.5);
  }

  function fadeInComponent(component:Component, fadeTo:Float = 1):Void
  {
    var builder = new AnimationBuilder(component, OVERLAY_EASE_DURATION, OVERLAY_EASE_TYPE);
    builder.setPosition(0, "opacity", 0, true); // 0% absolute
    builder.setPosition(100, "opacity", fadeTo, true);

    trace('Fading in dialog component...');
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
