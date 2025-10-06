package funkin.ui.debug.stageeditor.toolboxes;

import haxe.ui.containers.dialogs.CollapsibleDialog;

/**
 * The base class for the Toolboxes (manipulatable, arrangeable control windows) in the Stage Editor.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorBaseToolbox extends CollapsibleDialog
{
  var stageEditorState:StageEditorState;

  private function new(stageEditorState:StageEditorState)
  {
    super();

    this.stageEditorState = stageEditorState;
  }

  /**
   * Override to implement this.
   */
  public function refresh() {}
}
