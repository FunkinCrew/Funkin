package funkin.ui.debug.charting.dialogs;

import funkin.ui.debug.charting.ChartEditorState;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/dialogs/preferences.xml"))
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorPreferencesDialog extends ChartEditorBaseDialog
{
  /**
   * @param closable Whether the dialog can be closed by the user.
   * @param modal Whether the dialog is locked to the center of the screen (with a dark overlay behind it).
   */
  public function new(state2:ChartEditorState, params2:DialogParams)
  {
    super(state2, params2);
  }

  /**
   * @param state The current state of the chart editor.
   * @return A newly created `ChartEditorPreferencesDialog`.
   */
  public static function build(chartEditorState:ChartEditorState, ?closable:Bool, ?modal:Bool):ChartEditorPreferencesDialog
  {
    var dialog = new ChartEditorPreferencesDialog(chartEditorState,
      {
        closable: closable ?? false,
        modal: modal ?? true
      });

    dialog.showDialog(modal ?? true);

    return dialog;
  }
}
