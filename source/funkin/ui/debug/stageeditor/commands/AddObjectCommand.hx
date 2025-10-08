package funkin.ui.debug.stageeditor.commands;

import funkin.ui.debug.stageeditor.components.StageEditorObject;
import openfl.display.BitmapData;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class AddObjectCommand implements StageEditorCommand
{
  var objectID:String;
  var addedObject:Null<StageEditorObject>;
  var bitmap:Null<BitmapData> = null;

  public function new(objectID:String, ?bitmap:BitmapData = null)
  {
    this.objectID = objectID;
    this.bitmap = bitmap;
  }

  public function execute(state:StageEditorState):Void
  {
    var sprite = new StageEditorObject();

    if (bitmap != null) {}
    else
      sprite.loadGraphic(StageEditorAssetHandler.getDefaultGraphic());

    sprite.name = objectID;
    sprite.screenCenter();

    var spriteArray = state.spriteArray;
    sprite.zIndex = spriteArray.length == 0 ? 0 : (spriteArray[spriteArray.length - 1].zIndex + 1);

    state.selectedProp = sprite;

    state.add(sprite);
    state.sortObjects();
    this.addedObject = sprite;

    state.saveDataDirty = true;

    state.success('Object Creating Successfully', 'Successfully created an object with the name $objectID!');
  }

  public function undo(state:StageEditorState):Void
  {
    state.playSound(Paths.sound('chartingSounds/undo'));

    if (addedObject == null) return;
    
    state.spriteArray.remove(addedObject);
    state.remove(addedObject, true);

    state.sortObjects();
  }

  public function shouldAddToHistory(state:StageEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    return 'Add Object with ID $objectID';
  }
}
