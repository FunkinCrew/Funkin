package funkin.ui.debug.stageeditor.dialogs;

import funkin.data.stage.StageRegistry;
import funkin.data.stage.StageData;
import funkin.ui.debug.stageeditor.StageEditorState;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import funkin.util.FileUtil;
import funkin.util.SortUtil;
import haxe.ui.components.Label;
import haxe.ui.components.Link;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.events.MouseEvent;

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/stage-editor/dialogs/welcome.xml"))
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorWelcomeDialog extends StageEditorBaseDialog
{
  public function new(state2:StageEditorState, params2:DialogParams)
  {
    super(state2, params2);

    // this.buttonNew.onClick = - -> ;
    this.boxDrag.onClick = _ -> onClickBoxDrag();

    // Add items to the Recent Stages list
    // #if sys
    // for (stageFilePath in stageEditorState.previousWorkingFilePaths)
    // {
    //   if (stageFilePath == null) continue;
    //   this.addRecentFilePath(stageEditorState, stageFilePath);
    // }
    // #else
    // // this.addHTML5RecentFileMessage();
    // #end

    #if FILE_DROP_SUPPORTED
    state.addDropHandler(
      {
        component: this.boxDrag,
        handler: onFileOpenStage
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
      // var result:Null<Array<String>> = StageEditorImportExportHandler.loadFromFNFSPath(state, stagePath);
      // if (result != null)
      // {
      //   stageEditorState.success('Loaded Stage',
      //     result.length == 0 ? 'Loaded stage (${stagePath.toString()})' : 'Loaded stage (${stagePath.toString()})\n${result.join("\n")}');
      // }
      // else
      // {
      //   stageEditorState.error('Failed to Load Stage', 'Failed to load stage (${stagePath.toString()})');
      // }
    }

    if (!FileUtil.fileExists(stagePath))
    {
      trace('Previously loaded stage file (${stagePath}) does not exist, disabling link...');
      linkRecentStage.disabled = true;
    }

    contentRecent.addComponent(linkRecentStage);
  }

  public function onClickBoxDrag():Void
  {
    FileUtil.browseForSaveFile([FileUtil.FILE_FILTER_FNFS], onFileOpenStage, null, null, 'Open Stage Data');
  }

  public function onClickButtonNew(state:StageEditorState):Void {}

  public function onFileOpenStage(file:String)
  {
    var bytes = FileUtil.readBytesFromPath(file);

    if (bytes == null)
    {
      // notify
      return;
    }
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

      this.addTemplateStage(stageName, (_) -> {
        this.hideDialog(DialogButton.CANCEL);
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
