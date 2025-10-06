package funkin.ui.debug.stageeditor.dialogs;

import funkin.data.stage.StageRegistry;
import funkin.data.stage.StageData;
import funkin.ui.debug.stageeditor.StageEditorState;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import funkin.util.FileUtil;
import funkin.util.SortUtil;
import haxe.io.Path;
import haxe.ui.components.Label;
import haxe.ui.components.Link;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.containers.dialogs.Dialogs.SelectedFileInfo;
import haxe.ui.events.MouseEvent;

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/stage-editor/dialogs/welcome.xml"))
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorWelcomeDialog extends StageEditorBaseDialog
{
  public function new(state2:StageEditorState, params2:DialogParams)
  {
    super(state2, params2);

    // this.buttonNew.onClick = - -> ;
    this.stageBox.onClick = _ -> onClickStageBox();

    // Add items to the Recent Stages list
    #if sys
    for (stageFilePath in stageEditorState.previousWorkingFilePaths)
    {
      if (stageFilePath == null) continue;
      this.addRecentFilePath(stageEditorState, stageFilePath);
    }
    #else
    this.addHTML5RecentFileMessage();
    #end

    #if FILE_DROP_SUPPORTED
    stageEditorState.addDropHandler(
      {
        component: this.stageBox,
        handler: this.onDropFileStageBox
      });
    #end

    // Add items to the Load From Template list
    this.buildTemplateStageList(stageEditorState);
  }

  public static function build(stageEditorState:StageEditorState, ?closable:Bool, ?modal:Bool):StageEditorWelcomeDialog
  {
    var dialog = new StageEditorWelcomeDialog(stageEditorState,
      {
        closable: closable ?? false,
        modal: modal ?? true
      });

    dialog.showDialog(modal ?? true);

    return dialog;
  }

  public override function onClose(event:DialogEvent):Void
  {
    super.onClose(event);
  }

  public function addRecentFilePath(state:StageEditorState, stagePath:String):Void
  {
    var linkRecentStage:Link = new Link();

    var fileNamePattern:EReg = new EReg("([^/\\\\]+)$", "");
    var fileName:String = fileNamePattern.match(stagePath) ? fileNamePattern.matched(1) : stagePath;
    linkRecentStage.text = fileName;

    linkRecentStage.tooltip = stagePath;

    #if sys
    var lastModified:String = "Last Modified: " + sys.FileSystem.stat(stagePath).mtime.toString();
    linkRecentStage.tooltip += "\n" + lastModified;
    #end

    linkRecentStage.onClick = function(_event) {
      linkRecentStage.hide();

      this.hideDialog(DialogButton.CANCEL);

      // Load stage from file
      var result:Null<Array<String>> = StageEditorImportExportHandler.loadFromFNFSPath(state, stagePath);
      if (result != null)
      {
        stageEditorState.success('Loaded Stage',
          result.length == 0 ? 'Loaded stage (${stagePath.toString()})' : 'Loaded stage (${stagePath.toString()})\n${result.join("\n")}');
      }
      else
      {
        stageEditorState.error('Failed to Load Stage', 'Failed to load stage (${stagePath.toString()})');
      }
    }

    if (!FileUtil.fileExists(stagePath))
    {
      trace('Previously loaded stage file (${stagePath}) does not exist, disabling link...');
      linkRecentStage.disabled = true;
    }

    splashRecentContainer.addComponent(linkRecentStage);
  }

  /**
   * Add a string message to the "Open Recent" scroll box on the left.
   * Only displays on platforms which don't support direct file system access.
   */
  public function addHTML5RecentFileMessage():Void
  {
    var webLoadLabel:Label = new Label();
    webLoadLabel.text = 'Click the button below to load a stage file (.fnfs) from your computer.';

    splashRecentContainer.addComponent(webLoadLabel);
  }


  public function onClickStageBox():Void
  {
    this.lock();
    // TODO / BUG: File filtering not working on mac finder dialog, so we don't use it for now
    #if !mac
    FileUtil.browseForBinaryFile('Open Stage', [FileUtil.FILE_EXTENSION_INFO_FNFS], onSelectFile, onCancelBrowse);
    #else
    FileUtil.browseForBinaryFile('Open Stage', null, onSelectFile, onCancelBrowse);
    #end
  }

  /**
   * Called when a file is selected by dropping a file onto the Upload Stage box.
   */
  function onDropFileStageBox(pathStr:String):Void
  {
    var path:Path = new Path(pathStr);
    trace('Dropped file (${path})');

    try
    {
      var result:Null<Array<String>> = StageEditorImportExportHandler.loadFromFNFSPath(stageEditorState, path.toString());
      if (result != null)
      {
        stageEditorState.success('Loaded Stage',
          result.length == 0 ? 'Loaded stage (${path.toString()})' : 'Loaded stage (${path.toString()})\n${result.join("\n")}');
        this.hideDialog(DialogButton.APPLY);
      }
      else
      {
        stageEditorState.failure('Failed to Load Stage', 'Failed to load stage (${path.toString()})');
      }
    }
    catch (err)
    {
      stageEditorState.failure('Failed to Load Stage', 'Failed to load stage (${path.toString()}): ${err}');
    }
  }

  /**
   * Called when a file is selected by the dialog displayed when clicking the Upload Stage box.
   */
  function onSelectFile(selectedFile:SelectedFileInfo):Void
  {
    this.unlock();

    if (selectedFile != null && selectedFile.bytes != null)
    {
      try
      {
        var result:Null<Array<String>> = StageEditorImportExportHandler.loadFromFNFS(stageEditorState, selectedFile.bytes);
        if (result != null)
        {
          stageEditorState.success('Loaded Stage',
            result.length == 0 ? 'Loaded stage (${selectedFile.name})' : 'Loaded stage (${selectedFile.name})\n${result.join("\n")}');

          if (selectedFile.fullPath != null) stageEditorState.currentWorkingFilePath = selectedFile.fullPath;
          this.hideDialog(DialogButton.APPLY);
        }
      }
      catch (err)
      {
        stageEditorState.failure('Failed to Load Stage', 'Failed to load stage (${selectedFile.name}): ${err}');
      }
    }
  }

  public function onClickButtonNew(state:StageEditorState):Void {}

  function onCancelBrowse():Void
  {
    this.unlock();
  }

  public function buildTemplateStageList(state:StageEditorState):Void
  {
    var stageList:Array<String> = StageRegistry.instance.listEntryIds();
    stageList.sort(SortUtil.alphabetically);

    for (targetStageId in stageList)
    {
      var stageData:Null<StageData> = StageRegistry.instance.parseEntryDataWithMigration(targetStageId,
        StageRegistry.instance.fetchEntryVersion(targetStageId));
      if (stageData == null) continue;

      var stageName:Null<String> = stageData.name;
      if (stageName == null)
      {
        trace('[WARN] Could not fetch stage name for ${targetStageId}');
        continue;
      }

      this.addTemplateStage(stageName, _ -> {
        this.hideDialog(DialogButton.CANCEL);

        // Load song from template
        stageEditorState.loadStageAsTemplate(targetStageId);
      });
    }
  }

  public function addTemplateStage(stageName:String, onClickCb:(MouseEvent) -> Void):Void
  {
    var linkTemplateStage:Link = new Link();
    linkTemplateStage.text = stageName;
    linkTemplateStage.onClick = onClickCb;

    this.splashTemplateContainer.addComponent(linkTemplateStage);
  }
}
