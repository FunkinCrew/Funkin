package funkin.ui.debug.stageeditor.dialogs;

import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/dialogs/about.xml"))
class StageEditorAboutDialog extends StageEditorBaseDialog
{
  public function new(state2:StageEditorState, params2:DialogParams)
  {
    super(state2, params2);
  }

  public static function build(stageEditorState:StageEditorState, ?closable:Bool, ?modal:Bool):StageEditorAboutDialog
  {
    var dialog = new StageEditorAboutDialog(stageEditorState,
      {
        closable: closable ?? false,
        modal: modal ?? true
      });

    dialog.showDialog(modal ?? true);

    return dialog;
  }
}
