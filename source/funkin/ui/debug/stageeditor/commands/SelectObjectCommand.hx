package funkin.ui.debug.stageeditor.commands;

import funkin.ui.debug.stageeditor.components.StageEditorObject;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class SelectObjectCommand implements StageEditorCommand
{
  var object:StageEditorObject;
  var previousObject:Null<StageEditorObject>;

  public function new(object:StageEditorObject)
  {
    this.object = object;
  }

  public function execute(state:StageEditorState):Void
  {
    this.previousObject = state.selectedProp;
    state.selectedProp = object;
  }

  public function undo(state:StageEditorState):Void
  {
    state.selectedProp = previousObject;
  }

  public function shouldAddToHistory(state:StageEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    var objectID = (object != null) ? object.name : 'Unknown';
    return 'Select Object with ID $objectID';
  }
}
