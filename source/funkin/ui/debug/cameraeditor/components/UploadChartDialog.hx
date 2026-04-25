package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import haxe.io.Bytes;
import funkin.Conductor;
import funkin.input.Cursor;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorFileDropHandler;
import funkin.ui.debug.cameraeditor.CameraEditorState;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorImportExportHandler;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorNotificationHandler;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogDropTarget;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import funkin.ui.debug.charting.handlers.ChartEditorImportExportHandler;
import funkin.util.FileUtil;
import haxe.io.Path;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.events.MouseEvent;
import funkin.util.file.FNFCUtil.FNFCData;

@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/data/ui/camera-editor/dialogs/upload-chart.xml'))
class UploadChartDialog extends Dialog
{
  var locked:Bool = false;
  var cameraEditorState:CameraEditorState = null;
  var dropHandlers:Array<DialogDropTarget> = [];

  public function new(state:CameraEditorState)
  {
    super();

    this.cameraEditorState = state;

    this.dialogCancel.onClick = (_) -> this.hideDialog(DialogButton.CANCEL);

    this.destroyOnClose = true;
    this.onDialogClosed = event -> onClose(event);

    this.chartBox.onMouseOver = (_) ->
    {
      if (locked) return;
      this.chartBox.swapClass('upload-bg', 'upload-bg-hover');

      Cursor.cursorMode = Pointer;
    }

    this.chartBox.onMouseOut = (_) ->
    {
      if (locked) return;
      this.chartBox.swapClass('upload-bg-hover', 'upload-bg');

      Cursor.cursorMode = Default;
    }

    dropHandlers = [
      {component: this.chartBox, handler: this.onDropFileChartBox}
    ];

    for (dropTarget in dropHandlers) CameraEditorFileDropHandler.addDropHandler(dropTarget);
  }

  /**
   * Locks this dialog from interaction.
   * Use this when you want to prevent dialog interaction while another dialog is open.
   */
  public function lock():Void
  {
    this.locked = true;

    this.closable = false;
  }

  /**
   * Unlocks the dialog for interaction.
   */
  public function unlock():Void
  {
    this.locked = false;

    this.closable = true;
  }

  /**
   * Called when the upload chart dialog is closed.
   */
  public function onClose(_:DialogEvent):Void
  {
    for (dropTarget in dropHandlers)
    {
      CameraEditorFileDropHandler.removeDropHandler(dropTarget);
    }
  }

  @:bind(chartBox, MouseEvent.CLICK)
  public function onClickChartBox(_):Void
  {
    if (this.locked) return;

    this.lock();

    FileUtil.browseForFile('Open Chart', [FileUtil.FILE_FILTER_FNFC], onSelectFile, onCancelBrowse);
  }

  /**
   * Called when a file is selected by the dialog displayed when clicking the Upload Chart box.
   */
  function onSelectFile(selectedFile:SelectedFileData):Void
  {
    this.unlock();

    if (selectedFile == null || selectedFile.bytes == null) return;

    try
    {
      ChartEditorImportExportHandler.loadDataFromFNFCBytes(cameraEditorState, selectedFile.bytes, selectedFile.fullPath);

      this.hideDialog(DialogButton.APPLY);
    }
    catch (e)
    {
      CameraEditorNotificationHandler.failure(this.cameraEditorState, 'Failed to Load Chart', 'Failed to load chart (${selectedFile.name})');
      this.hideDialog(DialogButton.APPLY);
      return;
    }
  }

  /**
   * Called when a file is selected by dropping a file onto the Upload Chart box.
   */
  function onDropFileChartBox(path:String):Void
  {
    try
    {
      CameraEditorImportExportHandler.loadSongFromFNFCBytes(cameraEditorState, path);
    }
    catch (e)
    {
      CameraEditorNotificationHandler.failure(this.cameraEditorState, 'Failed to Load Chart', 'Failed to load chart (${selectedFile.name})');
      this.hideDialog(DialogButton.APPLY);
      return;
    }
  }

  function onCancelBrowse():Void
  {
    this.unlock();
  }
}
#end
