package funkin.ui.debug.charting.dialogs;

import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/dialogs/about.xml"))
class ChartEditorAboutDialog extends ChartEditorBaseDialog
{
  public function new(chartEditorState2:ChartEditorState, params2:DialogParams)
  {
    super(chartEditorState2, params2);
  }

  public static function build(chartEditorState:ChartEditorState, ?closable:Bool, ?modal:Bool):ChartEditorAboutDialog
  {
    var dialog = new ChartEditorAboutDialog(chartEditorState,
      {
        closable: closable ?? true,
        modal: modal ?? true
      });

    dialog.showDialog(modal ?? true);

    return dialog;
  }
}
