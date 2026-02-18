package funkin.ui.debug.stageeditor.toolboxes;

#if FEATURE_STAGE_EDITOR
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.components.DropDown;
import funkin.util.SortUtil;
import haxe.ui.events.UIEvent;

@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/ui/editors/stage-editor/toolboxes/stage-settings.xml"))
class StageEditorStageToolbox extends StageEditorDefaultToolbox
{
  var stageNameText:TextField;
  var stageZoomStepper:NumberStepper;

  override public function new(state:StageEditorState)
  {
    super(state);

    stageNameText.onChange = function(_)
    {
      state.stageName = stageNameText.text;
      state.saved = false;
    }

    stageZoomStepper.onChange = function(_)
    {
      state.stageZoom = stageZoomStepper.pos;
      state.updateMarkerPos();
      state.saved = false;
    }

    final EXCLUDE_LIBS = ["art", "default", "vlc", "videos", "songs", "libvlc"];

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
  }
}
#end
