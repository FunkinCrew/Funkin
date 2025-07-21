package funkin.ui.debug.stageeditor.toolboxes;

import haxe.ui.containers.dialogs.CollapsibleDialog;
import funkin.audio.FunkinSound;

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
    if (!dialogVisible && on) FunkinSound.playOnce(Paths.sound('chartingSounds/openWindow'));
    else if (dialogVisible && !on) FunkinSound.playOnce(Paths.sound('chartingSounds/exitWindow'));

    if (on) showDialog(false);
    else
      hide();

    dialogVisible = on;
  }

  /**
   * Override to implement this.
   */
  public function refresh() {}
}
