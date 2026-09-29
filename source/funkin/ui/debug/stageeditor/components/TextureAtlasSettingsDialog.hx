package funkin.ui.debug.stageeditor.components;

#if FEATURE_STAGE_EDITOR
import animate.FlxAnimateFrames;
import funkin.util.FileUtil;
import funkin.util.SerializerUtil;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import openfl.display.BitmapData;

@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/ui/editors/stage-editor/dialogs/texture-atlas-settings.xml'))
class TextureAtlasSettingsDialog extends Dialog
{
  var atlasPath:String;
  var stageEditorState:StageEditorState;
  var taSwfMode:CheckBox;
  var taCacheOnLoad:CheckBox;
  var taFilterQuality:DropDown;
  var taApplyStageMatrix:CheckBox;
  var taUseRenderTexture:CheckBox;

  override public function new(state:StageEditorState, atlasPath:String)
  {
    super();

    stageEditorState = state;
    this.atlasPath = atlasPath;

    buttons = DialogButton.CANCEL | DialogButton.APPLY;

    destroyOnClose = true;
  }

  override public function validateDialog(button:DialogButton, fn:Bool->Void)
  {
    var done:Bool = true;

    if (button == '{{apply}}')
    {
      var linkedObj:StageEditorObject = stageEditorState.selectedSprite;
      var files:Array<String> = FileUtil.readDir(atlasPath);

      var baseAtlasPath:String = Path.withoutDirectory(atlasPath);
      var animJson:String = FileUtil.readStringFromPath(Path.join([atlasPath, 'Animation.json']));
      var spritemapFiles:Array<StageEditorState.StageEditorAssetFile> = [];

      // Texture atlases could have multiple spritemaps so we have to locate and load them all.
      var i:Int = 1;
      while (files.containsAllExact(['spritemap$i.png', 'spritemap$i.json']))
      {
        var joinedPath:String = Path.join([baseAtlasPath, 'spritemap$i']);
        spritemapFiles.push({
          name: '$joinedPath.png',
          data: FileUtil.readBytesFromPath(Path.join([atlasPath, 'spritemap$i.png']))
        });
        spritemapFiles.push({
          name: '$joinedPath.json',
          data: FileUtil.readBytesFromPath(Path.join([atlasPath, 'spritemap$i.json']))
        });
        i++;
      }

      @:privateAccess
      var spritemaps:Array<SpritemapInput> = [for (i in 0...Std.int(spritemapFiles.length / 2)) {
        source: BitmapData.fromBytes(spritemapFiles[i * 2].data, true),
        json: SerializerUtil.sanitizeJSON(spritemapFiles[i * 2 + 1].data.toString())
      }];

      linkedObj.applyStageMatrix = taApplyStageMatrix.selected;
      linkedObj.useRenderTexture = taUseRenderTexture.selected;

      var settings:FlxAnimateSettings = {
        swfMode: taSwfMode.selected,
        cacheOnLoad: taCacheOnLoad.selected,
        filterQuality: cast taFilterQuality.selectedIndex
      };

      linkedObj.frames = FlxAnimateFrames.fromAnimate(animJson, spritemaps, null, linkedObj.name, true, settings);

      @:privateAccess
      cast(linkedObj.frames, FlxAnimateFrames)._settings = settings; // Settings are temporary, but we need to save them for exporting.

      // Unlike sparrow/packer assets, whose spritesheets can be loaded even when there's no animations attached to the sprite,
      // texture atlas objects need to have at least one animation before they could properly load, as boppers (animated assets)
      // are only created if an object's `danceEvery` isn't zero or the object has animations.
      var baseSymbol:String = cast(linkedObj.frames, FlxAnimateFrames).timeline.libraryItem.name;
      linkedObj.addAnimation({
        name: 'Idle',
        prefix: baseSymbol,
        animType: 'symbol',
        offsets: [0, 0],
        frameIndices: [],
        looped: false,
        flipX: false,
        flipY: false,
        frameRate: Std.int(linkedObj.anim.getDefaultFramerate())
      });
      linkedObj.startingAnimation = 'Idle';

      linkedObj.usedFiles.push({
        name: Path.join([baseAtlasPath, 'Animation.json']),
        data: Bytes.ofString(animJson)
      });
      linkedObj.usedFiles = linkedObj.usedFiles.concat(spritemapFiles);

      stageEditorState.notifyChange('Texture Atlas Loading Done', 'Finished loading the Texture Atlas for the object ${linkedObj.name}.');
      stageEditorState.updateDialog(OBJECT_ANIMS);
    }

    fn(done);
  }
}
#end
