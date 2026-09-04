package funkin.ui.debug.stageeditor.toolboxes;

#if FEATURE_STAGE_EDITOR
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.ui.debug.stageeditor.handlers.AssetDataHandler;
import funkin.ui.debug.stageeditor.StageEditorState.StageEditorAssetFile;
import funkin.ui.debug.stageeditor.components.TextureAtlasSettingsDialog;
import funkin.util.BitmapUtil;
import funkin.util.FileUtil;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextArea;
import haxe.ui.ToolkitAssets;
import openfl.display.BitmapData;
import haxe.ui.events.UIEvent;

@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/ui/editors/stage-editor/toolboxes/object-graphic.xml'))
class StageEditorObjectGraphicToolbox extends StageEditorDefaultToolbox
{
  var linkedObj:StageEditorObject = null;
  var objImage:Image;
  var objLoad:Button;
  var objLoadNet:Button;
  var objLoadTextureAtlas:Button;
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
    objLoad.onClick = function(_)
    {
      if (linkedObj == null) return;

      FileUtil.browseForFile('Open Image File', [FileUtil.FILE_FILTER_PNG], function(selectedFile)
      {
        if (selectedFile == null) return;
        objImage.resource = null;

        ToolkitAssets.instance.imageFromBytes(selectedFile.bytes, function(imageInfo)
        {
          if (imageInfo == null) return;

          objImage.resource = imageInfo.data;

          var file:StageEditorAssetFile = state.createFile(selectedFile.name, selectedFile.bytes);
          linkedObj.loadGraphic(BitmapData.fromBytes(file.data));
          linkedObj.updateHitbox();

          linkedObj.usedFiles.push(file);

          refresh();
          objImageWidth.pos = objImageWidth.max;
          objImageHeight.pos = objImageHeight.max;

          state.notifyChange('Object Graphic Loaded', 'The Image File ' + selectedFile.name + ' has been loaded.');
        });
      });
    }

    // Callback for loading the image from the internet.
    objLoadNet.onClick = function(_)
    {
      if (linkedObj == null) return;

      state.createURLDialog(function(bytes:lime.utils.Bytes)
      {
        var file:StageEditorAssetFile = state.createFile('${linkedObj.name}.png', bytes);
        linkedObj.loadGraphic(BitmapData.fromBytes(file.data));
        linkedObj.updateHitbox();

        linkedObj.usedFiles.push(file);

        // Update the image preview.
        refresh();

        stageEditorState.updateDialog(OBJECT_ANIMS);
      });
    }

    // Callback for loading a texture atlas.
    objLoadTextureAtlas.onClick = function(_)
    {
      if (linkedObj == null) return;

      FileUtil.browseForDirectory('Open Exported Texture Atlas', function(path:String)
      {
        var files:Array<String> = FileUtil.readDir(path);

        if (!files.containsAllExact(['Animation.json', 'spritemap1.json', 'spritemap1.png']))
        {
          state.notifyChange('Texture Atlas Loading Error', 'The folder $path doesn\'t contain required assets for a Texture Atlas.', true);
          return;
        }

        if (files.contains('metadata.json'))
        {
          state.notifyChange('Texture Atlas Loading Error', 'The Texture Atlas from the folder $path doesn\'t have inlined assets.', true);
          return;
        }

        var dialog:TextureAtlasSettingsDialog = new TextureAtlasSettingsDialog(state, path);
        dialog.showDialog();

        /**/
      });
    }

    // Callback for resetting the image.
    objReset.onClick = function(_)
    {
      if (linkedObj == null) return;

      linkedObj.loadGraphic(AssetDataHandler.getDefaultGraphic());
      linkedObj.updateHitbox();

      // Update the image preview.
      refresh();
      stageEditorState.updateDialog(OBJECT_ANIMS);
    }

    // Callback for resetting frames.
    objResetFrames.onClick = function(_)
    {
      if (linkedObj == null) return;

      var file:Null<StageEditorAssetFile> = linkedObj.usedFiles.find(f -> f.name.endsWith('.png'));
      linkedObj.loadGraphic(linkedObj.graphic);

      if (file != null) linkedObj.usedFiles.push(file);

      refresh();
      stageEditorState.updateDialog(OBJECT_ANIMS);
    }

    // Callback for loading the text for the Frame Data.
    objLoadFrames.onClick = function(_)
    {
      FileUtil.browseForFile('Open Text File', [FileUtil.FILE_FILTER_XML, FileUtil.FILE_FILTER_TXT], function(selectedFile)
      {
        if (selectedFile != null && selectedFile.bytes != null)
        {
          objFrameTxt.text = selectedFile.bytes.toString();
          state.notifyChange('Frame Text Loaded', 'The Text File ' + selectedFile.name + ' has been loaded.');
        }
      });
    }

    // Callback for setting the frames as Sparrow.
    objSetSparrow.onClick = function(_) setObjFrames(false);

    // Callback for setting the frames as Packer.
    objSetPacker.onClick = function(_) setObjFrames(true);

    // Callback for splitting the graphic into frames.
    objSplit.onClick = function(_)
    {
      if (linkedObj == null) return;

      var file:StageEditorAssetFile = state.createFile('${linkedObj.name}.png', BitmapUtil.encode(linkedObj.pixels));
      linkedObj.loadGraphic(linkedObj.graphic, true, Std.int(objImageWidth.pos), Std.int(objImageHeight.pos));
      linkedObj.updateHitbox();

      // Set the names of the frames.
      for (i in 0...linkedObj.frames.frames.length)
      {
        @:privateAccess
        linkedObj.frames.framesByName.set('Frame$i', linkedObj.frames.frames[i]);

        linkedObj.frames.frames[i].name = 'Frame$i';
      }

      linkedObj.usedFiles.push(file);

      // Add a generated XML file to the files, so that this sprite can be used in-game.
      var name:String = Path.withoutExtension(linkedObj.usedFiles[0].name);
      linkedObj.usedFiles.push(state.createFile('$name.xml', Bytes.ofString(AssetDataHandler.generateXML(linkedObj, name))));

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
   * Set the linked object's frames based on its graphic and loaded text. Only for sparrow and packer atlases.
   * @param usePacker
   */
  function setObjFrames(usePacker:Bool)
  {
    if (linkedObj == null || objFrameTxt.text == null || objFrameTxt.text.length == 0) return;

    var file:StageEditorAssetFile = stageEditorState.createFile('${linkedObj.name}.png', BitmapUtil.encode(linkedObj.pixels));

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
      stageEditorState.notifyChange('Frame Setup Error', e.toString(), true);
      return;
    }

    linkedObj.updateHitbox();

    linkedObj.usedFiles.push(file);

    var name:String = Path.withoutExtension(linkedObj.usedFiles[0].name);
    linkedObj.usedFiles.push(stageEditorState.createFile('$name.${usePacker ? 'txt' : 'xml'}', Bytes.ofString(objFrameTxt.text)));

    refresh();

    stageEditorState.notifyChange('Frame Setup Done', 'Finished the Frame Setup for the Object ' + linkedObj.name + '.');
    stageEditorState.updateDialog(OBJECT_ANIMS);
  }
}
#end
