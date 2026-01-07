package funkin.ui.debug.cameraeditor.components;

import funkin.ui.debug.charting.handlers.ChartEditorImportExportHandler;
#if FEATURE_CAMERA_EDITOR
import haxe.ui.containers.dialogs.Dialog;

import funkin.input.Cursor;

import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogDropTarget;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;

import funkin.util.FileUtil;
import haxe.io.Path;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.containers.dialogs.Dialogs.SelectedFileInfo;

import funkin.ui.debug.cameraeditor.CameraEditorState;

@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/data/ui/camera-editor/dialogs/upload-chart.xml'))
class UploadChartDialog extends Dialog
{
  var locked:Bool = false;

  var cameraEditorState:CameraEditorState = null;

  public function new(state:CameraEditorState)
  {
    super();

    this.cameraEditorState = state;

    this.dialogCancel.onClick = (_) -> this.hideDialog(DialogButton.CANCEL);

    this.chartBox.onClick = (_) -> this.onClickChartBox();

    this.chartBox.onMouseOver = function(_event) {
      if (locked) return;
      this.chartBox.swapClass('upload-bg', 'upload-bg-hover');
      Cursor.cursorMode = Pointer;
    }

    this.chartBox.onMouseOut = function(_event) {
      if (locked) return;
      this.chartBox.swapClass('upload-bg-hover', 'upload-bg');
      Cursor.cursorMode = Default;
    }

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

  public function onClickChartBox():Void
  {
    if (this.locked) return;

    this.lock();
    // TODO / BUG: File filtering not working on mac finder dialog, so we don't use it for now
    #if !mac
    FileUtil.browseForBinaryFile('Open Chart', [FileUtil.FILE_EXTENSION_INFO_FNFC], onSelectFile, onCancelBrowse);
    #else
    FileUtil.browseForBinaryFile('Open Chart', null, onSelectFile, onCancelBrowse);
    #end
  }

  /**
   * Called when a file is selected by the dialog displayed when clicking the Upload Chart box.
   */
  function onSelectFile(selectedFile:SelectedFileInfo):Void
  {
    this.unlock();

    if (selectedFile != null && selectedFile.bytes != null)
    {
      try
      {
        var entires = ChartEditorImportExportHandler.genericLoadFNFC(selectedFile.bytes);
        if (entires == null || entires.length != 3)
        {
          throw 'Invalid or corrupted FNFC file.';
        }
        this.cameraEditorState.songMetadatas = entires[0];
        this.cameraEditorState.songDatas = entires[1];
        this.hideDialog(DialogButton.APPLY);
      }
      catch (err)
      {
        trace('Failed to load chart (${selectedFile.name}): ${err}');
      }
    }
  }

  function onCancelBrowse():Void
  {
    this.unlock();
  }
}
#end
