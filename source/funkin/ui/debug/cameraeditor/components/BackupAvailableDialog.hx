package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import haxe.io.Bytes;
import funkin.util.FileUtil;
import funkin.ui.debug.charting.handlers.ChartEditorImportExportHandler;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorNotificationHandler;
import haxe.ui.events.MouseEvent;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorImportExportHandler;
import haxe.ui.components.Label;
import haxe.ui.components.Button;
import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.macros.ComponentMacros.build('assets/preload/data/ui/chart-editor/dialogs/backup-available.xml'))
class BackupAvailableDialog extends Dialog
{
  var backupTimeLabel:Label;
  var dialogCancel:Button;
  var buttonGoToFolder:Button;
  var buttonOpenBackup:Button;

  /**
   * The welcome dialog potentially behind this dialog.
   * Close it along with this dialog if we loaded the chart from backup.
   */
  var welcomeDialog:WelcomeDialog = null;

  var cameraEditorState:CameraEditorState = null;

  public function new(state:CameraEditorState, ?welcomeDialog:WelcomeDialog)
  {
    super();

    this.cameraEditorState = state;
    this.welcomeDialog = welcomeDialog;

    populateBackupTimeLabel();

    this.onDialogClosed = onBackupDialogClosed;
  }

  function populateBackupTimeLabel():Void
  {
    var backupTimeLabel:Null<Label> = this.findComponent('backupTimeLabel', Label);
    if (backupTimeLabel == null) throw 'Could not locate backupTimeLabel button in Backup Available dialog';

    var latestBackupInfo:Null<String> = CameraEditorImportExportHandler.getLatestBackupInfo();
    if (latestBackupInfo != null)
    {
      backupTimeLabel.text = latestBackupInfo;
    }
  }

  @:bind(buttonOpenBackup, MouseEvent.CLICK)
  function onClickOpenBackup(_:MouseEvent):Void
  {
    var targetPath = CameraEditorImportExportHandler.getLatestBackupPath();
    var selectedFileBytes:Null<Bytes> = FileUtil.readBytesFromPath(targetPath);
    if (selectedFileBytes == null)
    {
      trace('Failed to load bytes for FNFC from ${targetPath}');
      return;
    }

    var entries = ChartEditorImportExportHandler.genericLoadFNFC(selectedFileBytes, true);
    if (entries == null)
    {
      CameraEditorNotificationHandler.failure(cameraEditorState, 'Failed to Load Chart', 'Failed to load chart (${targetPath})');
      // Song failed to load, don't close the Welcome dialog so we aren't in a broken state.
      this.hideDialog(DialogButton.CANCEL);
      return;
    }

    CameraEditorNotificationHandler.success(cameraEditorState, 'Loaded Chart', 'Loaded chart (${targetPath})');
    // Close the welcome dialog behind this.
    this.hideDialog(DialogButton.APPLY);

    cameraEditorState.currentWorkingFilePath = targetPath;
    cameraEditorState.saved = true; // Just loaded file!

    cameraEditorState.songMetadatas = entries.songMetadatas;
    cameraEditorState.songDatas = entries.songChartDatas;
    cameraEditorState.songManifestData = entries.manifest;
    cameraEditorState.audioInstTrackData = entries.instrumentals;
    cameraEditorState.audioVocalTrackData = entries.vocals;
    cameraEditorState.onChartLoaded();
  }

  @:bind(buttonGoToFolder, MouseEvent.CLICK)
  function onClickGoToFolder(_:MouseEvent):Void
  {
    #if sys
    var absoluteBackupsPath:String = haxe.io.Path.join([Sys.getCwd(), CameraEditorState.BACKUPS_PATH]);
    FileUtil.openFolder(absoluteBackupsPath);
    #end

    // Don't hide the welcome dialog behind this.
    // Don't close this dialog.
  }

  @:bind(dialogCancel, MouseEvent.CLICK)
  function onClickCancel(_:MouseEvent):Void
  {
    // Don't hide the welcome dialog behind this.
    this.hideDialog(DialogButton.CANCEL);
  }

  function onBackupDialogClosed(event:DialogEvent):Void
  {
    if (event.button == DialogButton.APPLY)
    {
      // User loaded the backup! Close the welcome dialog behind this.
      if (welcomeDialog != null)
      {
        trace('Closing welcome dialog...');
        welcomeDialog.hideDialog(DialogButton.APPLY);
      }
      else
      {
        trace('No welcome dialog to close.');
      }
    }
    else
    {
      // User cancelled the dialog, don't close the welcome dialog so we aren't in a broken state.
    }
  }
}
#end
