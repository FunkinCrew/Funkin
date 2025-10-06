package funkin.ui.debug.stageeditor.commands;

import funkin.ui.debug.stageeditor.components.StageEditorObject;
import openfl.display.BitmapData;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class AddObjectCommand implements StageEditorCommand
{
  var objectID:String;
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
      sprite.loadGraphic(StageEditorAssetDataHandler.getDefaultGraphic());

    sprite.name = objectID;
    sprite.screenCenter();

    var spriteArray = state.spriteArray;
    sprite.zIndex = spriteArray.length == 0 ? 0 : (spriteArray[spriteArray.length - 1].zIndex + 1);

    state.selectedProp = sprite;

    state.add(sprite);
    state.sortObjects();

    state.success('Object Creating Successfully', 'Successfully created an object with the name $objectID!');
  }

  public function undo(state:StageEditorState):Void {}

  public function shouldAddToHistory(state:StageEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    return 'Add Object with ID $objectID';
  }
}
