package funkin.ui.debug.stageeditor.dialogs;

import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;

@:xml('
<dialog id="backupAvailableDialog" width="475" height="200" title="Hey! Listen!">
	<vbox width="100%" height="100%">
		<label text="There is a stage backup available, would you like to open it?\n" width="100%" textAlign="center" />
		<spacer height="6" />
		<label id="backupTimeLabel" text="Jan 1, 1970 0:00" width="100%" textAlign="center" />
		<spacer height="100%" />
		<hbox width="100%">
			<button text="No Thanks" id="dialogCancel" />
			<spacer width="100%" />
			<button text="Take Me There" id="buttonGoToFolder" />
			<spacer width="100%" />
			<button text="Open It" id="buttonOpenBackup" />
		</hbox>
	</vbox>
</dialog>
')
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorBackupDialog extends StageEditorBaseDialog
{
  public function new(state2:StageEditorState, welcomeDialog:Null<Dialog>, params2:DialogParams)
  {
    super(state2, params2);

    this.onDialogClosed = function(event) {
      stageEditorState.isHaxeUIDialogOpen = false;
      if (event.button == DialogButton.APPLY) if (event.button == DialogButton.APPLY)
      {
        // User loaded the backup! Close the welcome dialog behind this.
        if (welcomeDialog != null) welcomeDialog.hideDialog(DialogButton.APPLY);
      }
      else
      {
        // User cancelled the dialog, don't close the welcome dialog so we aren't in a broken state.
      }
    };

    stageEditorState.isHaxeUIDialogOpen = true;

    var latestBackupDate:Null<String> = StageEditorImportExportHandler.getLatestBackupDate();
    if (latestBackupDate != null)
    {
      this.backupTimeLabel.text = latestBackupDate;
    }

    this.dialogCancel.onClick = _ -> this.hideDialog(DialogButton.CANCEL);

    this.buttonGoToFolder.onClick = _ -> stageEditorState.openBackupsFolder();

    this.buttonOpenBackup.onClick = _ -> {
      var latestBackupPath:Null<String> = StageEditorImportExportHandler.getLatestBackupPath();

      var result:Null<Array<String>> = (latestBackupPath != null) ? stageEditorState.loadFromFNFSPath(latestBackupPath) : null;
      if (result != null)
      {
        if (result.length == 0)
        {
          // No warnings.
          stageEditorState.success('Loaded Stage', 'Loaded stage (${latestBackupPath})');
        }
        else
        {
          // One or more warnings.
          stageEditorState.warning('Loaded Stage', 'Loaded stage (${latestBackupPath})\n${result.join("\n")}');
        }

        // Close the welcome dialog behind this.
        this.hideDialog(DialogButton.APPLY);
      }
      else
      {
        stageEditorState.error('Failed to Load Stage', 'Failed to load stage (${latestBackupPath})');

        // Song failed to load, don't close the Welcome dialog so we aren't in a broken state.
        this.hideDialog(DialogButton.CANCEL);
      }
    }
  }

  public static function build(stageEditorState:StageEditorState, welcomeDialog:Null<Dialog>, ?closable:Bool, ?modal:Bool):StageEditorBackupDialog
  {
    var dialog = new StageEditorBackupDialog(stageEditorState, welcomeDialog,
      {
        closable: closable ?? false,
        modal: modal ?? true
      });

    dialog.showDialog(modal ?? true);

    return dialog;
  }
}
