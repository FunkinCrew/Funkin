package funkin.ui.debug.stageeditor.toolboxes;

import haxe.ui.components.HorizontalSlider;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.components.TextArea;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.containers.dialogs.Dialogs.FileDialogTypes;
import haxe.ui.ToolkitAssets;
import haxe.ui.containers.dialogs.Dialogs;
import funkin.ui.debug.stageeditor.handlers.AssetDataHandler;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.ui.components.DropDown;
import haxe.ui.containers.ListView;
import haxe.ui.components.CheckBox;
import haxe.ui.components.Switch;
import flixel.util.FlxTimer;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.events.ItemEvent;
import haxe.ui.components.ColorPicker;
import flixel.util.FlxColor;
import haxe.ui.util.Color;
import flixel.graphics.frames.FlxFrame;
import flixel.animation.FlxAnimation;
import funkin.util.FileUtil;
import funkin.ui.debug.stageeditor.components.LoadFromUrlDialog;
import openfl.display.BitmapData;

using StringTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/toolboxes/object-properties.xml"))
class StageEditorObjectToolbox extends StageEditorDefaultToolbox
{
  var linkedObject:StageEditorObject = null;

  var objectImagePreview:Image;
  var objectLoadImageButton:Button;
  var objectLoadInternetButton:Button;
  var objectDownloadImageButton:Button;
  var objectResetImageButton:Button;
  var objectZIdxStepper:NumberStepper;
  var objectZIdxReset:Button;

  var objectPosXStepper:NumberStepper;
  var objectPosYStepper:NumberStepper;
  var objectPosResetButton:Button;
  var objectAlphaSlider:HorizontalSlider;
  var objectAlphaResetButton:Button;
  var objectAngleSlider:HorizontalSlider;
  var objectAngleResetButton:Button;
  var objectScaleXStepper:NumberStepper;
  var objectScaleYStepper:NumberStepper;
  var objectScaleResetButton:Button;
  var objectSizeXStepper:NumberStepper;
  var objectSizeYStepper:NumberStepper;
  var objectSizeResetButton:Button;
  var objectScrollXSlider:HorizontalSlider;
  var objectScrollYSlider:HorizontalSlider;
  var objectScrollResetButton:Button;

  var objectFrameText:TextArea;
  var objectFrameTextLoad:Button;
  var objectFrameTextSparrow:Button;
  var objectFrameTextPacker:Button;
  var objectFrameImageWidth:NumberStepper;
  var objectFrameImageHeight:NumberStepper;
  var objectFrameImageSetter:Button;
  var objectFrameReset:Button;

  var objectAnimDropdown:DropDown;
  var objectAnimName:TextField;
  var objectAnimFrameList:ListView;
  var objectAnimPrefix:TextField;
  var objectAnimFrames:TextField;
  var objectAnimLooped:CheckBox;
  var objectAnimFlipX:CheckBox;
  var objectAnimFlipY:CheckBox;
  var objectAnimFramerate:NumberStepper;
  var objectAnimOffsetX:NumberStepper;
  var objectAnimOffsetY:NumberStepper;
  var objectAnimDanceBeat:NumberStepper;
  var objectAnimDanceBeatReset:Button;
  var objectAnimStart:TextField;
  var objectAnimStartReset:Button;

  var objectMiscAntialias:CheckBox;
  var objectMiscAntialiasReset:Button;
  var objectMiscFlipReset:Button;
  var objectMiscBlendDrop:DropDown;
  var objectMiscBlendReset:Button;
  var objectMiscColor:ColorPicker;
  var objectMiscColorReset:Button;

  override public function new(state:StageEditorState)
  {
    super(state);

    // basic callbacks
    objectLoadImageButton.onClick = function(_) {
      if (linkedObject == null) return;

      Dialogs.openBinaryFile("Open Image File", FileDialogTypes.IMAGES, function(selectedFile) {
        if (selectedFile == null) return;

        objectImagePreview.resource = null;

        ToolkitAssets.instance.imageFromBytes(selectedFile.bytes, function(imageInfo) {
          if (imageInfo == null) return;

          objectImagePreview.resource = imageInfo.data;

          linkedObject.frame = imageInfo.data;

          var bit = linkedObject.updateFramePixels();
          var bitToLoad = state.addBitmap(bit);

          linkedObject.loadGraphic(state.bitmaps[bitToLoad]);
          linkedObject.updateHitbox();

          // update size stuff
          objectSizeXStepper.pos = linkedObject.width;
          objectSizeYStepper.pos = linkedObject.height;

          // remove unused bitmaps
          state.removeUnusedBitmaps();
        });
      });
    }

    objectLoadInternetButton.onClick = function(_) {
      if (linkedObject == null) return;

      state.createURLDialog(function(bytes:lime.utils.Bytes) {
        linkedObject.loadGraphic(BitmapData.fromBytes(bytes));
        linkedObject.updateHitbox();
        refresh();
      });
    }

    objectDownloadImageButton.onClick = function(_) {
      if (linkedObject == null) return;

      FileUtil.saveFile(linkedObject.pixels.image.encode(PNG), [FileUtil.FILE_FILTER_PNG], null, null,
        linkedObject.name + "-graphic.png"); // i'on need any callbacks
    }

    objectZIdxStepper.max = StageEditorState.MAX_Z_INDEX;
    objectZIdxStepper.onChange = function(_) {
      if (linkedObject != null)
      {
        linkedObject.zIndex = Std.int(objectZIdxStepper.pos);
        state.sortAssets();
      }
    }

    // numeric callbacks
    objectPosXStepper.onChange = function(_) {
      if (linkedObject != null) linkedObject.x = objectPosXStepper.pos;
    };

    objectPosYStepper.onChange = function(_) {
      if (linkedObject != null) linkedObject.y = objectPosYStepper.pos;
    };

    objectAlphaSlider.onChange = function(_) {
      if (linkedObject != null) linkedObject.alpha = objectAlphaSlider.pos;
    };

    objectAngleSlider.onChange = function(_) {
      if (linkedObject != null) linkedObject.angle = objectAngleSlider.pos;
    };

    objectScaleXStepper.onChange = objectScaleYStepper.onChange = function(_) {
      if (linkedObject != null)
      {
        linkedObject.scale.set(objectScaleXStepper.pos, objectScaleYStepper.pos);
        linkedObject.updateHitbox();
        objectSizeXStepper.pos = linkedObject.width;
        objectSizeYStepper.pos = linkedObject.height;

        linkedObject.playAnim(linkedObject.animation.name); // load offsets
      }
    };

    objectSizeXStepper.onChange = objectSizeYStepper.onChange = function(_) {
      if (linkedObject != null)
      {
        linkedObject.setGraphicSize(Std.int(objectSizeXStepper.pos), Std.int(objectSizeYStepper.pos));
        linkedObject.updateHitbox();
        objectScaleXStepper.pos = linkedObject.scale.x;
        objectScaleYStepper.pos = linkedObject.scale.y;

        linkedObject.playAnim(linkedObject.animation.name); // load offsets
      }
    };

    objectScrollXSlider.onChange = objectScrollYSlider.onChange = function(_) {
      if (linkedObject != null) linkedObject.scrollFactor.set(objectScrollXSlider.pos, objectScrollYSlider.pos);
    };

    // frame callbacks
    objectFrameTextLoad.onClick = function(_) {
      Dialogs.openTextFile("Open Text File", FileDialogTypes.TEXTS, function(selectedFile) {
        if (selectedFile.text == null || (!selectedFile.name.endsWith(".xml") && !selectedFile.name.endsWith(".txt"))) return;

        objectFrameText.text = selectedFile.text;

        state.notifyChange("Frame Text Loaded", "The Text File " + selectedFile.name + " has been loaded.");
      });
    }

    objectFrameTextSparrow.onClick = function(_) {
      if (linkedObject == null || objectFrameText.text == null || objectFrameText.text == "") return;

      try
      {
        linkedObject.frames = FlxAtlasFrames.fromSparrow(linkedObject.graphic, objectFrameText.text);
      }
      catch (e)
      {
        state.notifyChange("Frame Setup Error", e.toString(), true);
        return;
      }

      // might as well clear animations because frames SUCK
      linkedObject.animDatas.clear();
      linkedObject.animation.destroyAnimations();
      linkedObject.updateHitbox();
      refresh();

      state.notifyChange("Frame Setup Done", "Finished the Sparrow Frame Setup for the Object " + linkedObject.name + ".");
    }

    objectFrameTextPacker.onClick = function(_) {
      if (linkedObject == null || objectFrameText.text == null || objectFrameText.text == "") return;

      try // crash prevention
      {
        linkedObject.frames = FlxAtlasFrames.fromSpriteSheetPacker(linkedObject.graphic, objectFrameText.text);
      }
      catch (e)
      {
        state.notifyChange("Frame Setup Error", e.toString(), true);
        return;
      }

      // might as well clear animations because frames SUCK
      linkedObject.animDatas.clear();
      linkedObject.animation.destroyAnimations();

      linkedObject.updateHitbox();
      refresh();

      state.notifyChange("Frame Setup Done", "Finished the Packer Frame Setup for the Object " + linkedObject.name + ".");
    }

    objectFrameImageSetter.onClick = function(_) {
      if (linkedObject == null) return;

      linkedObject.loadGraphic(linkedObject.graphic, true, Std.int(objectFrameImageWidth.pos), Std.int(objectFrameImageHeight.pos));
      linkedObject.updateHitbox();

      // set da names
      for (i in 0...linkedObject.frames.frames.length)
      {
        linkedObject.frames.framesHash.set("Frame" + i, linkedObject.frames.frames[i]);
        linkedObject.frames.frames[i].name = "Frame" + i;
      }

      // might as well clear animations because frames SUCK
      linkedObject.animDatas.clear();
      linkedObject.animation.destroyAnimations();
      refresh();

      state.notifyChange("Frame Setup Done", "Finished the Image Frame Setup for the Object " + linkedObject.name + ".");
    }

    // animation
    objectAnimDropdown.onChange = function(_) {
      if (linkedObject == null) return;

      if (objectAnimDropdown.selectedIndex == -1) // RESET EVERYTHING INSTANTENEOUSLY
      {
        objectAnimName.text = "";
        objectAnimLooped.selected = objectAnimFlipX.selected = objectAnimFlipY.selected = false;
        objectAnimFramerate.pos = 24;
        objectAnimOffsetX.pos = objectAnimOffsetY.pos = 0;
        objectAnimFrames.text = "";

        return;
      }

      var animData = linkedObject.animDatas[objectAnimDropdown.selectedItem.text];
      if (animData == null) return;

      objectAnimName.text = objectAnimDropdown.selectedItem.text;
      objectAnimPrefix.text = animData.prefix ?? "";
      objectAnimFrames.text = (animData.frameIndices != null && animData.frameIndices.length > 0 ? animData.frameIndices.join(", ") : "");

      objectAnimLooped.selected = animData.looped ?? false;
      objectAnimFlipX.selected = animData.flipX ?? false;
      objectAnimFlipY.selected = animData.flipY ?? false;
      objectAnimFramerate.pos = animData.frameRate ?? 24;

      objectAnimOffsetX.pos = (animData.offsets != null && animData.offsets.length == 2 ? animData.offsets[0] : 0);
      objectAnimOffsetY.pos = (animData.offsets != null && animData.offsets.length == 2 ? animData.offsets[1] : 0);
    }

    objectAnimSave.onClick = function(_) {
      if (linkedObject == null) return;

      if (objectAnimName.text == null || objectAnimName.text == "")
      {
        state.notifyChange("Animation Saving Error", "Invalid Animation Name!", true);
        return;
      }

      if (objectAnimPrefix.text == null || objectAnimPrefix.text == "")
      {
        state.notifyChange("Animation Saving Error", "Missing Animation Prefix!", true);
        return;
      }

      if (linkedObject.animation.getNameList().contains(objectAnimName.text)) linkedObject.animation.remove(objectAnimName.text);

      var indices = [];

      if (objectAnimFrames.text != null && objectAnimFrames.text != "")
      {
        var splitter = objectAnimFrames.text.replace(" ", "").split(",");

        for (num in splitter)
        {
          indices.push(Std.parseInt(num));
        }
      }

      var shouldDoIndices:Bool = (indices.length > 0 && !indices.contains(null));

      linkedObject.addAnim(objectAnimName.text, objectAnimPrefix.text, [objectAnimOffsetX.pos, objectAnimOffsetY.pos], (shouldDoIndices ? indices : []),
        Std.int(objectAnimFramerate.pos), objectAnimLooped.selected, objectAnimFlipX.selected, objectAnimFlipY.selected);

      if (linkedObject.animation.getByName(objectAnimName.text) == null)
      {
        state.notifyChange("Animation Saving Error", "Invalid Frames!", true);
        return;
      }

      linkedObject.playAnim(objectAnimName.text);

      state.notifyChange("Animation Saving Done", "Animation " + objectAnimName.text + " has been saved to the Object " + linkedObject.name + ".");
      updateAnimList();

      // stops the animation preview if animation is looped for too long
      FlxTimer.wait(StageEditorState.TIME_BEFORE_ANIM_STOP, function() {
        if (linkedObject != null && linkedObject.animation.curAnim != null)
          linkedObject.animation.stop(); // null check cuz if we stop an anim for a null object the game crashes :[
      });
    }

    objectAnimDelete.onClick = function(_) {
      if (linkedObject == null || linkedObject.animation.getNameList().length <= 0 || objectAnimDropdown.selectedIndex < 0) return;

      linkedObject.animation.pause();
      linkedObject.animation.stop();
      linkedObject.animation.curAnim = null;

      var daAnim = linkedObject.animation.getNameList()[objectAnimDropdown.selectedIndex];

      linkedObject.animation.remove(daAnim);
      linkedObject.animDatas.remove(daAnim);
      linkedObject.offset.set();

      state.notifyChange("Animation Deletion Done",
        "Animation "
        + objectAnimDropdown.selectedItem.text
        + " has been removed from the Object "
        + linkedObject.name
        + ".");

      updateAnimList();

      objectAnimDropdown.selectedIndex = objectAnimDropdown.dataSource.size - 1;
    }

    objectAnimDanceBeat.onChange = function(_) {
      if (linkedObject != null) linkedObject.danceEvery = Std.int(objectAnimDanceBeat.pos);
    }

    objectAnimStart.onChange = function(_) {
      if (linkedObject != null)
      {
        if (linkedObject.animation.getNameList().contains(objectAnimStart.text)) objectAnimStart.styleString = "color: white";
        else
          objectAnimStart.styleString = "color: indianred";

        linkedObject.startingAnimation = objectAnimStart.text;
      }
    }

    // misc
    objectMiscAntialias.onClick = function(_) {
      if (linkedObject != null) linkedObject.antialiasing = objectMiscAntialias.selected;
    }

    objectMiscBlendDrop.onChange = function(_) {
      if (linkedObject != null)
        linkedObject.blend = objectMiscBlendDrop.selectedItem.text == "NONE" ? null : AssetDataHandler.blendFromString(objectMiscBlendDrop.selectedItem.text);
    }

    objectMiscColor.onChange = function(_) {
      if (linkedObject != null) linkedObject.color = FlxColor.fromRGB(objectMiscColor.currentColor.r, objectMiscColor.currentColor.g,
        objectMiscColor.currentColor.b);
    }

    // reset button callbacks
    objectResetImageButton.onClick = function(_) {
      if (linkedObject != null)
      {
        linkedObject.loadGraphic(AssetDataHandler.getDefaultGraphic());
        linkedObject.updateHitbox();
        refresh();

        // remove unused bitmaps
        state.removeUnusedBitmaps();
      }
    }

    objectZIdxReset.onClick = function(_) {
      if (linkedObject != null) objectZIdxStepper.pos = 0; // corner cutting because onChange will activate with this
    }

    objectPosResetButton.onClick = function(_) {
      if (linkedObject != null)
      {
        linkedObject.screenCenter();
        objectPosXStepper.pos = linkedObject.x;
        objectPosYStepper.pos = linkedObject.y;
      }
    }

    objectAlphaResetButton.onClick = function(_) {
      if (linkedObject != null) linkedObject.alpha = objectAlphaSlider.pos = 1;
    }

    objectAngleResetButton.onClick = function(_) {
      if (linkedObject != null) linkedObject.angle = objectAngleSlider.pos = 0;
    }

    objectScaleResetButton.onClick = objectSizeResetButton.onClick = function(_) // the corner cutting goes crazy
    {
      if (linkedObject != null)
      {
        linkedObject.scale.set(1, 1);
        refresh(); // refreshes like multiple shit
      }
    }

    objectScrollResetButton.onClick = function(_) {
      if (linkedObject != null) linkedObject.scrollFactor.x = linkedObject.scrollFactor.y = objectScrollXSlider.pos = objectScrollYSlider.pos = 1;
    }

    objectFrameReset.onClick = function(_) {
      if (linkedObject == null) return;

      linkedObject.loadGraphic(linkedObject.pixels);
      linkedObject.animDatas.clear();
      linkedObject.animation.destroyAnimations();
      refresh();
    }

    objectMiscAntialiasReset.onClick = function(_) {
      if (linkedObject != null) objectMiscAntialias.selected = true;
    }

    objectMiscBlendReset.onClick = function(_) {
      if (linkedObject != null) objectMiscBlendDrop.selectedItem = "NORMAL";
    }

    objectMiscColorReset.onClick = function(_) {
      if (linkedObject != null) objectMiscColor.currentColor = Color.fromString("white");
    }

    objectAnimDanceBeatReset.onClick = function(_) {
      if (linkedObject != null) objectAnimDanceBeat.pos = 0;
    }

    objectAnimStartReset.onClick = function(_) {
      if (linkedObject != null) objectAnimStart.text = "";
    }

    refresh();
  }

  var prevFrames:Array<FlxFrame> = [];
  var prevAnims:Array<String> = [];

  override public function refresh()
  {
    linkedObject = stageEditorState.selectedSprite;

    objectPosXStepper.step = stageEditorState.moveStep;
    objectPosYStepper.step = stageEditorState.moveStep;
    objectAngleSlider.step = funkin.save.Save.instance.stageEditorAngleStep;

    if (linkedObject == null)
    {
      updateFrameList();
      updateAnimList();
      return;
    }

    // saving fps
    if (objectImagePreview.resource != linkedObject.frame) objectImagePreview.resource = linkedObject.frame;

    if (objectZIdxStepper.pos != linkedObject.zIndex) objectZIdxStepper.pos = linkedObject.zIndex;
    if (objectPosXStepper.pos != linkedObject.x) objectPosXStepper.pos = linkedObject.x;
    if (objectPosYStepper.pos != linkedObject.y) objectPosYStepper.pos = linkedObject.y;
    if (objectAlphaSlider.pos != linkedObject.alpha) objectAlphaSlider.pos = linkedObject.alpha;
    if (objectAngleSlider.pos != linkedObject.angle) objectAngleSlider.pos = linkedObject.angle;
    if (objectScaleXStepper.pos != linkedObject.scale.x) objectScaleXStepper.pos = linkedObject.scale.x;
    if (objectScaleYStepper.pos != linkedObject.scale.y) objectScaleYStepper.pos = linkedObject.scale.y;
    if (objectSizeXStepper.pos != linkedObject.width) objectSizeXStepper.pos = linkedObject.width;
    if (objectSizeYStepper.pos != linkedObject.height) objectSizeYStepper.pos = linkedObject.height;
    if (objectScrollXSlider.pos != linkedObject.scrollFactor.x) objectScrollXSlider.pos = linkedObject.scrollFactor.x;
    if (objectScrollYSlider.pos != linkedObject.scrollFactor.y) objectScrollYSlider.pos = linkedObject.scrollFactor.y;
    if (objectMiscAntialias.selected != linkedObject.antialiasing) objectMiscAntialias.selected = linkedObject.antialiasing;

    if (objectMiscColor.currentColor != Color.fromString(linkedObject.color.toHexString() ?? "white"))
      objectMiscColor.currentColor = Color.fromString(linkedObject.color.toHexString());

    if (objectAnimDanceBeat.pos != linkedObject.danceEvery) objectAnimDanceBeat.pos = linkedObject.danceEvery;
    if (objectAnimStart.text != linkedObject.startingAnimation) objectAnimStart.text = linkedObject.startingAnimation;

    var objBlend = Std.string(linkedObject.blend) ?? "NONE";
    if (objectMiscBlendDrop.selectedItem != objBlend.toUpperCase()) objectMiscBlendDrop.selectedItem = objBlend.toUpperCase();

    // ough the max
    if (objectFrameImageWidth.max != linkedObject.pixels.width) objectFrameImageWidth.max = linkedObject.graphic.width;
    if (objectFrameImageHeight.max != linkedObject.pixels.height) objectFrameImageHeight.max = linkedObject.graphic.height;

    // update some anim shit
    if (prevFrames != linkedObject.frames.frames.copy()) updateFrameList();
    if (prevAnims != linkedObject.animation.getNameList().copy()) updateAnimList();
  }

  function updateFrameList()
  {
    prevFrames = [];
    objectAnimFrameList.dataSource = new ArrayDataSource();

    if (linkedObject == null) return;

    for (fname in linkedObject.frames.frames)
    {
      if (fname != null) objectAnimFrameList.dataSource.add({name: fname.name, tooltip: fname.name});

      prevFrames.push(fname);
    }
  }

  function updateAnimList()
  {
    objectAnimDropdown.dataSource.clear();
    prevAnims = [];
    if (linkedObject == null) return;

    for (aname in linkedObject.animation.getNameList())
    {
      objectAnimDropdown.dataSource.add({text: aname});
      prevAnims.push(aname);
    }

    if (linkedObject.animation.getNameList().contains(objectAnimStart.text)) objectAnimStart.styleString = "color: white";
    else
      objectAnimStart.styleString = "color: indianred";

    linkedObject.startingAnimation = objectAnimStart.text;
  }
}
