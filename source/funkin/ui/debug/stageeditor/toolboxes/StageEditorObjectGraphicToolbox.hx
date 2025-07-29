package funkin.ui.debug.stageeditor.toolboxes;

import flixel.graphics.frames.FlxAtlasFrames;
import funkin.ui.debug.stageeditor.handlers.AssetDataHandler;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextArea;
import haxe.ui.containers.dialogs.Dialogs.FileDialogTypes;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.ToolkitAssets;
import openfl.display.BitmapData;
import haxe.ui.events.UIEvent;

@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/toolboxes/object-graphic.xml"))
class StageEditorObjectGraphicToolbox extends StageEditorDefaultToolbox
{
  var linkedObj:StageEditorObject = null;

  var objImage:Image;
  var objLoad:Button;
  var objLoadNet:Button;
  var objReset:Button;
  var objResetFrames:Button;

  var objFrameTxt:TextArea;
  var objLoadFrames:Button;
  var objSetSparrow:Button;
  var objSetPacker:Button;

  var objImageWidth:NumberStepper;
  var objImageHeight:NumberStepper;
  var objSplit:Button;

  override public function new(state:StageEditorState)
  {
    super(state);

    // Callback for loading the image from the local hard drive.
    objLoad.onClick = function(_) {
      if (linkedObj == null) return;

      Dialogs.openBinaryFile("Open Image File", FileDialogTypes.IMAGES, function(selectedFile) {
        if (selectedFile == null) return;
        objImage.resource = null;

        ToolkitAssets.instance.imageFromBytes(selectedFile.bytes, function(imageInfo) {
          if (imageInfo == null) return;

          objImage.resource = imageInfo.data;
          linkedObj.frame = imageInfo.data;

          // This checks if the same image had already been loaded, so that we don't add it twice.
          // Kind of hacky but it is what it is.
          var bitToLoad:String = state.addBitmap(linkedObj.updateFramePixels());
          linkedObj.loadGraphic(state.bitmaps[bitToLoad]);
          linkedObj.updateHitbox();

          state.removeUnusedBitmaps();

          refresh();
          objImageWidth.pos = objImageWidth.max;
          objImageHeight.pos = objImageHeight.max;

          state.notifyChange("Object Graphic Loaded", "The Image File " + selectedFile.name + " has been loaded.");
        });
      });
    }

    // Callback for loading the image from the internet.
    objLoadNet.onClick = function(_) {
      if (linkedObj == null) return;

      state.createURLDialog(function(bytes:lime.utils.Bytes) {
        var bitToLoad:String = state.addBitmap(BitmapData.fromBytes(bytes));
        linkedObj.loadGraphic(state.bitmaps[bitToLoad]);
        linkedObj.updateHitbox();

        state.removeUnusedBitmaps();

        // Update the image preview.
        refresh();

        stageEditorState.updateDialog(OBJECT_ANIMS);
      });
    }

    // Callback for resetting the image.
    objReset.onClick = function(_) {
      if (linkedObj == null) return;

      linkedObj.loadGraphic(AssetDataHandler.getDefaultGraphic());
      linkedObj.updateHitbox();

      // remove unused bitmaps
      state.removeUnusedBitmaps();

      // Update the image preview.
      refresh();
      stageEditorState.updateDialog(OBJECT_ANIMS);
    }

    // Callback for resetting frames.
    objResetFrames.onClick = function(_) {
      if (linkedObj == null) return;

      linkedObj.loadGraphic(linkedObj.graphic);
      refresh();
      stageEditorState.updateDialog(OBJECT_ANIMS);
    }

    // Callback for loading the text for the Frame Data.
    objLoadFrames.onClick = function(_) {
      Dialogs.openTextFile("Open Text File", FileDialogTypes.TEXTS, function(selectedFile) {
        if (selectedFile.text == null || (!selectedFile.name.endsWith(".xml") && !selectedFile.name.endsWith(".txt"))) return;

        objFrameTxt.text = selectedFile.text;

        state.notifyChange("Frame Text Loaded", "The Text File " + selectedFile.name + " has been loaded.");
      });
    }

    // Callback for setting the frames as Sparrow.
    objSetSparrow.onClick = function(_) setObjFrames(false);

    // Callback for setting the frames as Packer.
    objSetPacker.onClick = function(_) setObjFrames(true);

    // Callback for splitting the graphic into frames.
    objSplit.onClick = function(_) {
      if (linkedObj == null) return;

      linkedObj.loadGraphic(linkedObj.graphic, true, Std.int(objImageWidth.pos), Std.int(objImageHeight.pos));
      linkedObj.updateHitbox();

      // Set the names of the frames.
      for (i in 0...linkedObj.frames.frames.length)
      {
        @:privateAccess
        linkedObj.frames.framesByName.set('Frame$i', linkedObj.frames.frames[i]);

        linkedObj.frames.frames[i].name = 'Frame$i';
      }

      // Refresh the display.
      refresh();

      stageEditorState.updateDialog(OBJECT_ANIMS);
    }

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    stageEditorState.menubarItemWindowObjectGraphic.selected = false;
  }

  override public function refresh()
  {
    linkedObj = stageEditorState.selectedSprite;

    if (linkedObj == null)
    {
      // If there is no selected object, reset displays.
      objImage.resource = null;
      return;
    }

    // Otherwise, update only the changed fields.
    if (objImage.resource != linkedObj.frame) objImage.resource = linkedObj.frame;
    if (objImageWidth.max != linkedObj.graphic.width) objImageWidth.max = objImageWidth.pos = linkedObj.graphic.width;
    if (objImageHeight.max != linkedObj.graphic.height) objImageHeight.max = objImageHeight.pos = linkedObj.graphic.height;
  }

  /**
   * Set the linked object's frames based on its graphic and loaded text.
   * @param usePacker
   */
  function setObjFrames(usePacker:Bool)
  {
    if (linkedObj == null || objFrameTxt.text == null || objFrameTxt.text.length == 0) return;

    try
    {
      if (usePacker)
      {
        linkedObj.frames = FlxAtlasFrames.fromSpriteSheetPacker(linkedObj.graphic, objFrameTxt.text);
      }
      else
      {
        linkedObj.frames = FlxAtlasFrames.fromSparrow(linkedObj.graphic, objFrameTxt.text);
      }
    }
    catch (e)
    {
      stageEditorState.notifyChange("Frame Setup Error", e.toString(), true);
      return;
    }

    linkedObj.animDatas.clear();
    linkedObj.animation.destroyAnimations();
    linkedObj.updateHitbox();
    refresh();

    stageEditorState.notifyChange("Frame Setup Done", "Finished the Frame Setup for the Object " + linkedObj.name + ".");
    stageEditorState.updateDialog(OBJECT_ANIMS);
  }
}
