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

  public function new(objectID:String, ?bitmap:BitmapData)
  {
    this.objectID = objectID;
    this.bitmap = bitmap;
  }

  public function execute(state:StageEditorState):Void
  {
    var sprite = new StageEditorObject();

    if (bitmap != null)
    {
      var bitToLoad = StageEditorAssetHandler.addBitmap(bitmap);
      if (bitToLoad != null) sprite.loadGraphic(StageEditorAssetHandler.bitmaps[bitToLoad] ?? StageEditorAssetHandler.getDefaultGraphic());
    }
    else
      sprite.loadGraphic(StageEditorAssetHandler.getDefaultGraphic());

    sprite.name = objectID;
    sprite.screenCenter();

    var spriteArray = state.spriteArray;
    sprite.zIndex = spriteArray.length == 0 ? 0 : (spriteArray[spriteArray.length - 1].zIndex + 1);

    var data = sprite.toData(false);
    state.stageData.props.push(
      {
        name: data.name,
        assetPath: data.assetPath.startsWith("#") ? data.color : data.assetPath,
        position: data.position.copy(),
        zIndex: data.zIndex,
        isPixel: data.isPixel,
        scale: data.scale,
        alpha: data.alpha,
        danceEvery: data.danceEvery,
        scroll: data.scroll?.copy() ?? [1.0, 1.0],
        animations: data.animations,
        startingAnimation: data.startingAnimation,
        animType: data.animType,
        flipX: data.flipX,
        flipY: data.flipY,
        angle: data.angle,
        blend: data.blend,
        color: data.assetPath.startsWith("#") ? "#FFFFFF" : data.color
      }
    );

    state.selectedProp = sprite;

    state.add(sprite);
    state.sortObjects();
    this.addedObject = sprite;

    state.refreshToolbox(StageEditorState.STAGE_EDITOR_TOOLBOX_OBJECT_PROPERTIES_LAYOUT);

    state.saveDataDirty = true;

    state.success('Object Creating Successfully', 'Successfully created an object with the name $objectID!');
  }

  public function undo(state:StageEditorState):Void
  {
    state.playSound(Paths.sound('chartingSounds/undo'));

    if (addedObject == null) return;

    state.spriteArray.remove(addedObject);
    state.remove(addedObject, true);

    state.playSound(Paths.sound('chartingSounds/undo'));

    state.saveDataDirty = true;

    state.sortObjects();
  }

  public function shouldAddToHistory(state:StageEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    return 'Add $objectID';
  }
}
