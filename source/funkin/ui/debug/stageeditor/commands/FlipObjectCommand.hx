package funkin.ui.debug.stageeditor.commands;

import funkin.ui.debug.stageeditor.components.StageEditorObject;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class FlipObjectCommand implements StageEditorCommand
{
  var object:StageEditorObject;
  var flipX:Bool;

  public function new(object:StageEditorObject, flipX:Bool = true)
  {
    this.object = object;
    this.flipX = flipX;
  }

  public function execute(state:StageEditorState):Void
  {
    if (object == null) return;

    if (flipX) object.flipX = !object.flipX;
    else
      object.flipY = !object.flipY;

    state.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;
  }

  public function undo(state:StageEditorState):Void
  {
    // Same as execute() lol!!!
    if (object == null) return;

    if (flipX) object.flipX = !object.flipX;
    else
      object.flipY = !object.flipY;

    state.playSound(Paths.sound('chartingSounds/undo'));

    state.saveDataDirty = true;
  }

  public function shouldAddToHistory(state:StageEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    var objectID = (object != null) ? object.name : 'Unknown';
    return 'Flip $objectID on ${flipX ? 'X' : 'Y'} axis';
  }
}
