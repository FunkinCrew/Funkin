package funkin.ui.debug.stageeditor.commands;

import funkin.ui.debug.stageeditor.components.StageEditorObject;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class DeleteObjectCommand implements StageEditorCommand
{
  var object:StageEditorObject;

  public function new(object:StageEditorObject)
  {
    this.object = object;
  }

  public function execute(state:StageEditorState):Void
  {
    if (object == null) return;
    
    state.spriteArray.remove(object);

    state.remove(object, true);
    state.selectedProp?.destroy();
    state.selectedProp = null;

    state.sortObjects();
  }

  public function undo(state:StageEditorState):Void {}

  public function shouldAddToHistory(state:StageEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    var objectID = if (object != null) object.name else "Unknown";
    return 'Removed Object with ID $objectID';
  }
}
