package funkin.ui.debug.stageeditor.commands;

import funkin.ui.debug.stageeditor.components.StageEditorObject;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class RemoveObjectCommand implements StageEditorCommand
{
  var object:StageEditorObject;
  var objectData:Null<StageEditorObjectData>;

  public function new(object:StageEditorObject)
  {
    this.object = object;
    this.objectData = object.toData();
  }

  public function execute(state:StageEditorState):Void
  {
    if (object == null) return;

    state.spriteArray.remove(object);

    state.remove(object, true);
    state.selectedProp?.destroy();
    state.selectedProp = null;

    state.saveDataDirty = true;

    state.sortObjects();
  }

  public function undo(state:StageEditorState):Void
  {
    // state.playSound(Paths.sound('chartingSounds/undo'));
    // var sprite:Null<StageEditorObject> = new StageEditorObject();
    // trace(object);
    // sprite.fromData(object.toData());

    // if (sprite == null) return;

    // state.add(sprite);
    // state.selectedProp = sprite;

    // state.saveDataDirty = true;

    // state.sortObjects();
  }

  public function shouldAddToHistory(state:StageEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    var objectID = (object != null) ? object.name : 'Unknown';
    return 'Remove Object with ID $objectID';
  }
}
