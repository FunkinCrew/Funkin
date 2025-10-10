package funkin.ui.debug.stageeditor.commands;

import funkin.ui.debug.stageeditor.components.StageEditorObject;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class DeselectObjectCommand implements StageEditorCommand
{
  var object:StageEditorObject;

  public function new(object:StageEditorObject)
  {
    this.object = object;
  }

  public function execute(state:StageEditorState):Void
  {
    state.selectedProp = null;
  }

  public function undo(state:StageEditorState):Void
  {
    state.selectedProp = object;
  }

  public function shouldAddToHistory(state:StageEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    var objectID = (object != null) ? object.name : 'Unknown';
    return 'Deselect $objectID';
  }
}
