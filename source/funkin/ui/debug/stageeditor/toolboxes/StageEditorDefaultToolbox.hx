package funkin.ui.debug.stageeditor.toolboxes;

#if FEATURE_STAGE_EDITOR
import haxe.ui.containers.dialogs.CollapsibleDialog;
import funkin.audio.FunkinSound;
import funkin.ui.debug.charting.ChartEditorState;

@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorDefaultToolbox extends CollapsibleDialog
{
  var stageEditorState:StageEditorState;

  public var dialogVisible:Bool = false;

  private function new(stageEditorState:StageEditorState)
  {
    super();

    this.stageEditorState = stageEditorState;

    closable = true;
    modal = true;
    destroyOnClose = false;
  }

  /**
   * Handles the Sound and Visibility
   * @param on
   */
  public function toggle(on:Bool)
  {
    if (!dialogVisible && on) FunkinSound.playOnce(Paths.sound(ChartEditorState.CHART_EDITOR_OPEN_WINDOW_SOUND));
    else if (dialogVisible && !on) FunkinSound.playOnce(Paths.sound(ChartEditorState.CHART_EDITOR_EXIT_WINDOW_SOUND));

    if (on) showDialog(false);
    else
      hide();

    dialogVisible = on;
  }

  /**
   * Override to implement this.
   */
  public function refresh()
  {
  }
}
#end
