package funkin.ui.debug.stageeditor.toolboxes;

import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.components.DropDown;
import funkin.util.SortUtil;
import haxe.ui.events.UIEvent;

@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/toolboxes/stage-settings.xml"))
class StageEditorStageToolbox extends StageEditorDefaultToolbox
{
  var stageNameText:TextField;
  var stageZoomStepper:NumberStepper;
  var stageLibraryDrop:DropDown;

  override public function new(state:StageEditorState)
  {
    super(state);

    stageNameText.onChange = function(_) {
      state.stageName = stageNameText.text;
      state.saved = false;
    }

    stageZoomStepper.onChange = function(_) {
      state.stageZoom = stageZoomStepper.pos;
      state.updateMarkerPos();
      state.saved = false;
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
    allLibs.sort(SortUtil.alphabetically); // this system is VERY stupid, it relies on the possibility that the future libraries will be named week(end)[x]

    for (lib in allLibs)
    {
      stageLibraryDrop.dataSource.add({text: lib});
    }

    stageLibraryDrop.onChange = function(_) {
      state.stageFolder = stageLibraryDrop.selectedItem.text;
    }

    refresh();

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    stageEditorState.menubarItemWindowStage.selected = false;
  }

  override public function refresh()
  {
    stageNameText.text = stageEditorState.stageName;
    stageZoomStepper.pos = stageEditorState.stageZoom;
    stageLibraryDrop.selectedItem = stageEditorState.stageFolder;
  }
}
