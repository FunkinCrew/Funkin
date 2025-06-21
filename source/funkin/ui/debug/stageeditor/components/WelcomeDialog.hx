package funkin.ui.debug.stageeditor.components;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.components.Link;
import funkin.save.Save;
import funkin.util.FileUtil;
import flixel.FlxG;
import funkin.data.stage.StageData;
import funkin.data.stage.StageRegistry;
import funkin.ui.debug.stageeditor.StageEditorState.StageEditorDialogType;

using funkin.util.tools.FloatTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/dialogs/welcome.xml"))
class WelcomeDialog extends Dialog
{
  var stageEditorState:StageEditorState;

  override public function new(state:StageEditorState)
  {
    super();

    stageEditorState = state;

    buttonNew.onClick = function(_) {
      stageEditorState.clearAssets();
      stageEditorState.loadDummyData();
      stageEditorState.currentFile = "";
      killDaDialog();
    }

    for (file in Save.instance.stageEditorPreviousFiles)
    {
      trace(file);

      if (!FileUtil.fileExists(file)) continue; // whats the point of loading something that doesnt exist

      var patj = new haxe.io.Path(file);

      var fileText = new Link();
      fileText.percentWidth = 100;
      fileText.text = patj.file + "." + patj.ext;
      fileText.onClick = function(_) {
        fileText.hide();
        loadFromFilePath(file);
      };

      #if sys
      var stat = sys.FileSystem.stat(file);
      var sizeInMB = (stat.size / 1000000).round(2);

      fileText.tooltip = "Full Name: " + file + "\nLast Modified: " + stat.mtime.toString() + "\nSize: " + sizeInMB + "MB";
      #end

      contentRecent.addComponent(fileText);
    }

    boxDrag.onClick = function(_) FileUtil.browseForSaveFile([FileUtil.FILE_FILTER_FNFS], loadFromFilePath, null, null, "Open Stage Data");

    var defaultStages:Array<String> = StageRegistry.instance.listBaseGameEntryIds();
    defaultStages.sort(funkin.util.SortUtil.alphabetically);

    for (stage in defaultStages)
    {
      var baseStage = StageRegistry.instance.parseEntryDataWithMigration(stage, StageRegistry.instance.fetchEntryVersion(stage));
      if (baseStage == null) continue;

      var link = new Link(); // this is how the legend of zelda started btw
      link.percentWidth = 100;
      link.text = baseStage.name;

      link.onClick = function(_) loadFromPreset(baseStage);

      contentPresets.addComponent(link);
    }

    FlxG.stage.window.onDropFile.add(loadFromFilePath);
  }

  public function loadFromPreset(data:StageData)
  {
    if (data == null) return;

    if (!stageEditorState.saved)
    {
      Dialogs.messageBox("This will destroy all of your Unsaved Work.\n\nAre you sure? This cannot be undone.", "Load Stage", MessageBoxType.TYPE_YESNO, true,
        function(btn:DialogButton) {
          if (btn == DialogButton.YES)
          {
            stageEditorState.saved = true;
            loadFromPreset(data);
          }
        });

      return;
    }

    stageEditorState.clearAssets();
    stageEditorState.currentFile = "";
    stageEditorState.loadFromDataRaw(data);
    killDaDialog();
  }

  public function loadFromFilePath(file:String)
  {
    if (!stageEditorState.saved)
    {
      Dialogs.messageBox("This will destroy all of your Unsaved Work.\n\nAre you sure? This cannot be undone.", "Load Stage", MessageBoxType.TYPE_YESNO, true,
        function(btn:DialogButton) {
          if (btn == DialogButton.YES)
          {
            stageEditorState.saved = true;
            loadFromFilePath(file);
          }
        });

      return;
    }

    var bytes = FileUtil.readBytesFromPath(file);

    if (bytes == null)
    {
      stageEditorState.notifyChange("Problem Loading the Stage", "The Stage File could not be loaded.", true);
      return;
    }

    stageEditorState.clearAssets();
    stageEditorState.currentFile = file;
    stageEditorState.unpackShitFromZip(bytes);
    killDaDialog();
  }

  function killDaDialog()
  {
    stageEditorState.updateDialog(StageEditorDialogType.OBJECT_GRAPHIC);
    stageEditorState.updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);
    stageEditorState.updateDialog(StageEditorDialogType.CHARACTER);
    stageEditorState.updateDialog(StageEditorDialogType.STAGE);

    FlxG.stage.window.onDropFile.remove(loadFromFilePath);
    hide();
    destroy();
  }
}
