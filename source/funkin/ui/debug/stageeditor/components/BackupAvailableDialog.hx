package funkin.ui.debug.stageeditor.components;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import funkin.util.FileUtil;
import haxe.io.Path;
import funkin.util.DateUtil;

using StringTools;

@:xml('
<dialog id="backupAvailableDialog" width="475" height="150" title="Hey! Listen!">
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
class BackupAvailableDialog extends Dialog
{
  override public function new(state:StageEditorState, filePath:String)
  {
    super();

    if (!FileUtil.fileExists(filePath)) return;

    // time text
    var fileDate = Path.withoutExtension(Path.withoutDirectory(filePath));
    var dateParts = fileDate.split("-");

    while (dateParts.length < 8)
      dateParts.push("0");

    var year:Int = Std.parseInt(dateParts[2]) ?? 0; // copied parts from ChartEditorImportExportHandler.hx
    var month:Int = Std.parseInt(dateParts[3]) ?? 1;
    var day:Int = Std.parseInt(dateParts[4]) ?? 0;
    var hour:Int = Std.parseInt(dateParts[5]) ?? 0;
    var minute:Int = Std.parseInt(dateParts[6]) ?? 0;
    var second:Int = Std.parseInt(dateParts[7]) ?? 0;

    backupTimeLabel.text = DateUtil.generateCleanTimestamp(new Date(year, month - 1, day, hour, minute, second));

    // button callbacks
    dialogCancel.onClick = function(_) hideDialog(DialogButton.CANCEL);

    buttonGoToFolder.onClick = function(_) {
      // :[
      #if sys
      var absoluteBackupsPath:String = Path.join([Sys.getCwd(), StageEditorState.BACKUPS_PATH]);
      FileUtil.openFolder(absoluteBackupsPath);
      #end
    }

    buttonOpenBackup.onClick = function(_) {
      if (FileUtil.fileExists(filePath) && state.welcomeDialog != null) // doing a check in case a sleezy FUCK decides to delete the backup file AFTER dialog opens
      {
        state.welcomeDialog.loadFromFilePath(filePath);
      }
      hideDialog(DialogButton.APPLY);
    }

    // uhhh
    onDialogClosed = function(event) {
      if (event.button == DialogButton.APPLY)
      {
        if (state.welcomeDialog != null) state.welcomeDialog.hideDialog(DialogButton.APPLY);
      }
    };
  }
}
