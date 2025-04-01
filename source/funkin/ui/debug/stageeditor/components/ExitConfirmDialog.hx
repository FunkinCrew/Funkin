package funkin.ui.debug.stageeditor.components;

import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/dialogs/exit-confirm.xml"))
class ExitConfirmDialog extends Dialog
{
  var onComplete:Void->Void = null;

  override public function new(onComp:Void->Void)
  {
    super();

    onComplete = onComp;

    buttons = DialogButton.CANCEL | "{{Proceed}}";
    defaultButton = "{{Proceed}}";

    destroyOnClose = true;
  }

  public override function validateDialog(button:DialogButton, fn:Bool->Void)
  {
    if (button == "{{Proceed}}" && onComplete != null)
    {
      onComplete();
    }

    fn(true);
  }
}
