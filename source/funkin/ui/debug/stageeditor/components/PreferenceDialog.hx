package funkin.ui.debug.stageeditor.components;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.events.UIEvent;
import funkin.ui.debug.stageeditor.components.StageEditorBaseDialog;

@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/stage-editor/dialogs/preferences.xml"))
class PreferenceDialog extends StageEditorBaseDialog {
  /**
   * @param closable Whether the dialog can be closed by the user.
   * @param modal Whether the dialog is locked to the center of the screen (with a dark overlay behind it).
   */
  public function new(state2:StageEditorState, params2:DialogParams)
  {
    super(state2, params2);


  }

  /**
   * @param state The current state of the chart editor.
   * @return A newly created `ChartEditorPreferencesDialog`.
   */
  public static function build(stageEditorState:StageEditorState, ?closable:Bool, ?modal:Bool):PreferenceDialog
  {
    var dialog = new PreferenceDialog(stageEditorState,
      {
        closable: closable ?? false,
        modal: modal ?? true
      });

    dialog.showDialog(modal ?? true);

    return dialog;
  }
}
