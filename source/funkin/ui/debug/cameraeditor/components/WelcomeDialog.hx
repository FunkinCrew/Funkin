package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.Conductor;
import funkin.data.song.SongRegistry;
import funkin.input.Cursor;
import funkin.play.song.Song;
import funkin.ui.debug.cameraeditor.CameraEditorState;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorImportExportHandler;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorFileDropHandler;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorNotificationHandler;
import funkin.ui.debug.charting.ChartEditorState;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogDropTarget;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import funkin.ui.debug.charting.handlers.ChartEditorImportExportHandler;
import funkin.ui.debug.charting.util.FNFCData;
import funkin.util.FileUtil;
import funkin.util.SortUtil;
import haxe.io.Path;
import haxe.io.Bytes;
import haxe.ui.components.Label;
import haxe.ui.components.Link;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.events.MouseEvent;

/**
 * Builds and opens a dialog letting the user create a new chart, open a recent chart, or load from a template.
 * Opens when the chart editor first opens.
 */
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/data/ui/camera-editor/dialogs/welcome.xml')) @:access(funkin.ui.debug.charting.CameraEditorState)
class WelcomeDialog extends Dialog
{
  var locked:Bool = false;
  var defaultClosable:Bool = false;
  var cameraEditorState:CameraEditorState = null;
  var dropHandlers:Array<DialogDropTarget> = [];

  public function new(state:CameraEditorState, closable:Bool = false)
  {
    super();

    this.cameraEditorState = state;
    this.defaultClosable = closable;
    this.closable = this.defaultClosable;

    this.destroyOnClose = true;
    this.onDialogClosed = event -> onClose(event);

    // Add items to the Recent Charts list
    #if sys
    for (chartPath in cameraEditorState.previousWorkingFilePaths)
    {
      if (chartPath == null) continue;
      this.addRecentFilePath(cameraEditorState, chartPath);
    }
    #else
    this.addHTML5RecentFileMessage();
    #end

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
    this.closable = this.defaultClosable;
  }

  /**
   * Called when the welcome dialog is closed.
   */
  public function onClose(_:DialogEvent):Void
  {
    for (dropTarget in dropHandlers)
    {
      CameraEditorFileDropHandler.removeDropHandler(dropTarget);
    }
  }

  /**
   * Called when the user clicks the "Upload Chart" box in the dialog.
   */
  @:bind(chartBox, MouseEvent.CLICK)
  public function onClickChartBox(_):Void
  {
    if (this.locked) return;

    this.lock();

    FileUtil.browseForFile('Open Chart', [FileUtil.FILE_FILTER_FNFC], onSelectFile, onCancelBrowse);
  }

  /**
   * Called when the user clicks the "Upload Chart" box in the dialog, then cancels out of the file browser.
   */
  function onCancelBrowse():Void
  {
    this.unlock();
  }

  /**
   * Called when a file is selected by the dialog displayed when clicking the Upload Chart box.
   */
  function onSelectFile(selectedFile:SelectedFileData):Void
  {
    this.unlock();

    if (selectedFile == null || selectedFile.bytes == null) return;

    var entries = ChartEditorImportExportHandler.genericLoadFNFC(selectedFile.bytes, true);
    if (entries == null)
    {
      CameraEditorNotificationHandler.failure(this.cameraEditorState, 'Failed to Load Chart', 'Failed to load chart (${selectedFile.name})');
      this.hideDialog(DialogButton.APPLY);
      return;
    }

    CameraEditorNotificationHandler.success(this.cameraEditorState, 'Loaded Chart', 'Loaded chart (${selectedFile.name})');

    if (selectedFile.fullPath != null)
    {
      this.cameraEditorState.currentWorkingFilePath = selectedFile.fullPath;
      this.cameraEditorState.saved = true; // Just loaded file!
    }

    this.cameraEditorState.songMetadatas = entries.songMetadatas;
    this.cameraEditorState.songDatas = entries.songChartDatas;
    this.cameraEditorState.songManifestData = entries.manifest;
    this.cameraEditorState.audioInstTrackData = entries.instrumentals;
    this.cameraEditorState.audioVocalTrackData = entries.vocals;
    this.cameraEditorState.onChartLoaded();

    this.hideDialog(DialogButton.APPLY);
  }

  /**
   * Called when a file is selected by dropping a file onto the Upload Chart box.
   */
  function onDropFileChartBox(path:String):Void
  {
    var selectedFileBytes:Null<Bytes> = FileUtil.readBytesFromPath(path);
    if (selectedFileBytes == null)
    {
      trace('Failed to load bytes for FNFC from $path');
      return;
    }

    var entries = ChartEditorImportExportHandler.genericLoadFNFC(selectedFileBytes, true);
    if (entries == null)
    {
      CameraEditorNotificationHandler.failure(this.cameraEditorState, 'Failed to Load Chart', 'Failed to load chart (${path})');
      this.hideDialog(DialogButton.APPLY);
      return;
    }

    CameraEditorNotificationHandler.success(this.cameraEditorState, 'Loaded Chart', 'Loaded chart (${path})');

    this.cameraEditorState.currentWorkingFilePath = path;
    this.cameraEditorState.saved = true; // Just loaded file!

    this.cameraEditorState.songMetadatas = entries.songMetadatas;
    this.cameraEditorState.songDatas = entries.songChartDatas;
    this.cameraEditorState.songManifestData = entries.manifest;
    this.cameraEditorState.audioInstTrackData = entries.instrumentals;
    this.cameraEditorState.audioVocalTrackData = entries.vocals;
    this.cameraEditorState.onChartLoaded();

    this.hideDialog(DialogButton.APPLY);
  }

  /**
   * Add a file path to the "Open Recent" scroll box on the left.
   * @param state The current state of the chart editor.
   * @param chartPath The file path to add to the recent charts list.
   */
  public function addRecentFilePath(state:CameraEditorState, chartPath:String):Void
  {
    var linkRecentChart:Link = new Link();

    var fileNamePattern:EReg = new EReg('([^/\\\\]+)$', '');
    var fileName:String = fileNamePattern.match(chartPath) ? fileNamePattern.matched(1) : chartPath;
    linkRecentChart.text = fileName;

    linkRecentChart.tooltip = chartPath;

    #if sys
    if (!FileUtil.fileExists(chartPath))
    {
      trace('Previously loaded chart file (${chartPath}) does not exist, disabling link...');
      linkRecentChart.disabled = true;
    }
    else
    {
      var lastModified:String = 'Last Modified: ' + sys.FileSystem.stat(chartPath).mtime.toString();
      linkRecentChart.tooltip += '\n' + lastModified;
    }
    #end

    linkRecentChart.onClick = function(_event)
    {
      linkRecentChart.hide();

      this.hideDialog(DialogButton.CANCEL);

      // Load chart from file
      var result:Bool = CameraEditorImportExportHandler.loadFNFCFromPath(state, chartPath);

      if (result)
      {
        CameraEditorNotificationHandler.success(state, 'Loaded Chart', 'Loaded chart (${chartPath})');
        state.currentWorkingFilePath = chartPath;
      }
      else
      {
        CameraEditorNotificationHandler.failure(state, 'Failed to Load Chart', 'Failed to load chart (${chartPath})');
      }
    }

    splashRecentContainer.addComponent(linkRecentChart);
  }
}
#end
