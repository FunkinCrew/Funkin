package funkin.ui.debug.stageeditor.components;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import funkin.util.FileUtil;
import haxe.io.Path;
import funkin.util.DateUtil;
import funkin.util.WindowUtil;

using StringTools;

@:xml('
<dialog id="backupAvailableDialog" width="475" height="200" title="Hey! Listen!">
	<vbox width="100%" height="100%">
		<label text="There is a chart backup available, would you like to open it?\n" width="100%" textAlign="center" />
		<spacer height="6" />
		<label id="backupTimeLabel" text="no sys? sus" width="100%" textAlign="center" />
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

    if (!FileUtil.doesFileExist(filePath)) return; // whats the point of loading something that doesnt exist

    // time text
    var file = Path.withoutExtension(Path.withoutDirectory(filePath));

    #if sys
    var stat = sys.FileSystem.stat(filePath);
    var sizeInMB = (stat.size / 1000000).round(3);

    backupTimeLabel.text = "Full Name: " + file + "\nLast Modified: " + stat.mtime.toString() + "\nSize: " + sizeInMB + " MB";
    #end

    // button callbacks
    dialogCancel.onClick = function(_) hideDialog(DialogButton.CANCEL);

    buttonGoToFolder.onClick = function(_) {
      // :[
      #if sys
      var absoluteBackupsPath:String = Path.join([Sys.getCwd(), StageEditorState.BACKUPS_PATH]);
      WindowUtil.openFolder(absoluteBackupsPath);
      #end
    }

    buttonOpenBackup.onClick = function(_) {
      if (FileUtil.doesFileExist(filePath) && state.welcomeDialog != null) // doing a check in case a sleezy FUCK decides to delete the backup file AFTER dialog opens
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
