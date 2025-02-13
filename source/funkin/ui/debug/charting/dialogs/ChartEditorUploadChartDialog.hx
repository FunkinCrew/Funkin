package funkin.ui.debug.charting.dialogs;

import funkin.input.Cursor;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogDropTarget;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import funkin.util.FileUtil;
import haxe.io.Path;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.containers.dialogs.Dialogs.SelectedFileInfo;

// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/dialogs/upload-chart.xml"))
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorUploadChartDialog extends ChartEditorBaseDialog
{
  var dropHandlers:Array<DialogDropTarget> = [];

  public function new(state2:ChartEditorState, params2:DialogParams)
  {
    super(state2, params2);

    this.dialogCancel.onClick = (_) -> this.hideDialog(DialogButton.CANCEL);

    this.chartBox.onClick = (_) -> this.onClickChartBox();

    this.chartBox.onMouseOver = function(_event) {
      if (this.locked) return;
      this.chartBox.swapClass('upload-bg', 'upload-bg-hover');
      Cursor.cursorMode = Pointer;
    }

    this.chartBox.onMouseOut = function(_event) {
      this.chartBox.swapClass('upload-bg-hover', 'upload-bg');
      Cursor.cursorMode = Default;
    }

    dropHandlers.push({component: this.chartBox, handler: this.onDropFileChartBox});
  }

  public static function build(state:ChartEditorState, ?closable:Bool, ?modal:Bool):ChartEditorUploadChartDialog
  {
    var dialog = new ChartEditorUploadChartDialog(state,
      {
        closable: closable ?? false,
        modal: modal ?? true
      });

    for (dropTarget in dialog.dropHandlers)
    {
      state.addDropHandler(dropTarget);
    }

    dialog.showDialog(modal ?? true);

    return dialog;
  }

  public override function onClose(event:DialogEvent):Void
  {
    super.onClose(event);

    if (event.button != DialogButton.APPLY && !this.closable)
    {
      // User cancelled the wizard! Back to the welcome dialog.
      chartEditorState.openWelcomeDialog(this.closable);
    }

    for (dropTarget in dropHandlers)
    {
      chartEditorState.removeDropHandler(dropTarget);
    }
  }

  public override function lock():Void
  {
    super.lock();
    this.dialogCancel.disabled = true;
  }

  public override function unlock():Void
  {
    super.unlock();
    this.dialogCancel.disabled = false;
  }

  /**
   * Called when clicking the Upload Chart box.
   */
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
   * Called when a file is selected by dropping a file onto the Upload Chart box.
   */
  function onDropFileChartBox(pathStr:String):Void
  {
    var path:Path = new Path(pathStr);
    trace('Dropped file (${path})');

    try
    {
      var result:Null<Array<String>> = ChartEditorImportExportHandler.loadFromFNFCPath(chartEditorState, path.toString());
      if (result != null)
      {
        chartEditorState.success('Loaded Chart',
          result.length == 0 ? 'Loaded chart (${path.toString()})' : 'Loaded chart (${path.toString()})\n${result.join("\n")}');
        this.hideDialog(DialogButton.APPLY);
      }
      else
      {
        chartEditorState.failure('Failed to Load Chart', 'Failed to load chart (${path.toString()})');
      }
    }
    catch (err)
    {
      chartEditorState.failure('Failed to Load Chart', 'Failed to load chart (${path.toString()}): ${err}');
    }
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
        var result:Null<Array<String>> = ChartEditorImportExportHandler.loadFromFNFC(chartEditorState, selectedFile.bytes);
        if (result != null)
        {
          chartEditorState.success('Loaded Chart',
            result.length == 0 ? 'Loaded chart (${selectedFile.name})' : 'Loaded chart (${selectedFile.name})\n${result.join("\n")}');

          if (selectedFile.fullPath != null) chartEditorState.currentWorkingFilePath = selectedFile.fullPath;
          this.hideDialog(DialogButton.APPLY);
        }
      }
      catch (err)
      {
        chartEditorState.failure('Failed to Load Chart', 'Failed to load chart (${selectedFile.name}): ${err}');
      }
    }
  }

  function onCancelBrowse():Void
  {
    this.unlock();
  }
}
