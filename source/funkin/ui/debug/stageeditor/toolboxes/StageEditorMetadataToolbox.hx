package funkin.ui.debug.stageeditor.toolboxes;

import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.components.DropDown;
import funkin.util.SortUtil;
import haxe.ui.events.UIEvent;

@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/toolboxes/stage-settings.xml"))
class StageEditorMetadataToolbox extends StageEditorBaseToolbox
{
  var inputStageName:TextField;
  var inputStageZoom:NumberStepper;
  var inputStageLibrary:DropDown;

  public function new(stageEditorState2:StageEditorState)
  {
    super(stageEditorState2);

    initialize();

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    stageEditorState.menubarItemWindowStage.selected = false;
  }

  function initialize():Void
  {
    inputStageName.onChange = event -> {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        inputStageName.removeClass('invalid-value');
        stageEditorState.stageData.name = event.target.text;
      }
      else stageEditorState.stageData.name = 'Unknown';
    }

    inputStageZoom.onChange = event -> {
      if (event.value == null || event.value <= 0) return;

      stageEditorState.stageData.cameraZoom = event.value;
    }

    final EXCLUDE_LIBS = ["art", "default", "vlc", "videos", "songs", "libvlc"];
    var allLibs = [];

    @:privateAccess
    {
      for (lib => idk in lime.utils.Assets.libraryPaths)
      {
        if (!EXCLUDE_LIBS.contains(lib)) allLibs.push(lib);
      }
    }
    allLibs.sort(SortUtil.alphabetically);

    for (lib in allLibs) inputStageLibrary.dataSource.add({text: lib});

    inputStageLibrary.onChange = event -> {
      var valid:Bool = event.data != null && event.data.text != null;

      if (valid) stageEditorState.stageData.directory = event.data.text;
    }
  }

  public override function refresh():Void
  {
    inputStageName.text = stageEditorState.currentStageName;
    inputStageZoom.value = stageEditorState.currentStageZoom;
    inputStageLibrary.value = {text: stageEditorState.currentStageDirectory};
  }

  public static function build(stageEditorState:StageEditorState):StageEditorMetadataToolbox
  {
    return new StageEditorMetadataToolbox(stageEditorState);
  }
}
