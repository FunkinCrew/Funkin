package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.macros.ComponentMacros.build('assets/preload/data/ui/chart-editor/dialogs/backup-available.xml'))
class BackupAvailableDialog extends Dialog
{
  var cameraEditorState:CameraEditorState = null;

  /**
   * The welcome dialog potentially behind this dialog.
   * Close it along with this dialog if we loaded the chart from backup.
   */
  var welcomeDialog:WelcomeDialog = null;

  public function new(state:CameraEditorState, ?welcomeDialog:WelcomeDialog)
  {
    super();

    this.cameraEditorState = state;
  }
}
#end
