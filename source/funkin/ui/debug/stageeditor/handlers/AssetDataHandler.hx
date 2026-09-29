package funkin.ui.debug.stageeditor.handlers;

#if FEATURE_STAGE_EDITOR
import animate.FlxAnimateFrames;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import funkin.data.stage.StageData.StageDataProp;
import haxe.io.Path;
import openfl.display.BitmapData;
import openfl.display.BlendMode;

using StringTools;

/**
 * Handles the Stage Props and Datas - being able to convert one to the other.
 */
class AssetDataHandler
{
  /**
   * Turns an Object into Data.
   * @param obj the Object whose data to read.
   * @param useBitmaps Whether to Save object's BitmapData directly.
   * @return Data of the Object
   */
  public static function toData(obj:StageEditorObject):StageEditorObjectData
  {
    var outputData:StageEditorObjectData = {
      name: obj.name,
      assetPath: '',
      position: [obj.x, obj.y],
      zIndex: obj.zIndex,
      isPixel: !obj.antialiasing,
      scale: obj.scale.x == obj.scale.y ? Left(obj.scale.x) : Right([obj.scale.x, obj.scale.y]),
      alpha: obj.alpha,
      danceEvery: obj.animation.getNameList().length > 0 ? obj.danceEvery : 0,
      scroll: [obj.scrollFactor.x, obj.scrollFactor.y],
      animations: [for (n => d in obj.animationDatas) d],
      startingAnimation: obj.startingAnimation,
      animType: getAnimType(obj),
      angle: obj.angle,
      flipX: obj.flipX,
      flipY: obj.flipY,
      blend: obj.blend == null ? "" : Std.string(obj.blend),
      color: obj.color.toWebString(),
      neededFiles: obj.usedFiles.clone()
    }

    if (obj.usedFiles.length > 0)
    {
      if (outputData.animType == 'animateatlas')
      {
        outputData.assetPath = Path.directory(obj.usedFiles[0].name);

        // Additionally set the atlas settings here.
        var frames:FlxAnimateFrames = cast obj.frames;

        @:privateAccess
        outputData.atlasSettings = {
          useRenderTexture: obj.useRenderTexture,
          applyStageMatrix: obj.applyStageMatrix,
          swfMode: frames._settings?.swfMode ?? false,
          cacheOnLoad: frames._settings?.cacheOnLoad ?? false,
          filterQuality: frames._settings?.filterQuality ?? animate.FlxAnimateFrames.FilterQuality.MEDIUM
        }
      }
      else
      {
        outputData.assetPath = Path.withoutExtension(obj.usedFiles[0].name);
      }
    }
    else // Solid color
    {
      outputData.assetPath = obj.color.toWebString();
    }

    return outputData;
  }

  /**
   * Modifies an Object based on the Data.
   * @param object Object to modify. Set to null to create a new one.
   * @param data The Data used for the Object.
   */
  public static function fromData(object:StageEditorObject, data:StageEditorObjectData)
  {
    if (data.animations != null && data.animations.length > 0)
    {
      switch (data.animType)
      {
        case 'sparrow':
          var spritesheet:Null<StageEditorState.StageEditorAssetFile> = data.neededFiles.find(f -> f.name.endsWith('.png'));
          var frameData:Null<StageEditorState.StageEditorAssetFile> = data.neededFiles.find(f -> f.name.endsWith('.xml'));

          if (spritesheet != null && frameData != null)
          {
            object.frames = FlxAtlasFrames.fromSparrow(BitmapData.fromBytes(spritesheet.data, true), frameData.data.toString());
          }

        case 'packer':
          var spritesheet:Null<StageEditorState.StageEditorAssetFile> = data.neededFiles.find(f -> f.name.endsWith('.png'));
          var frameData:Null<StageEditorState.StageEditorAssetFile> = data.neededFiles.find(f -> f.name.endsWith('.txt'));

          if (spritesheet != null && frameData != null)
          {
            object.frames = FlxAtlasFrames.fromSpriteSheetPacker(BitmapData.fromBytes(spritesheet.data, true), frameData.data.toString());
          }

        case 'animateatlas':
          var animateJson:String = data.neededFiles.find(f -> f.name.endsWith('/Animation.json'))?.data?.toString() ?? '';
          var spritemaps:Array<SpritemapInput> = [];

          var totalSpritemaps:Int = Std.int((data.neededFiles.length - 1) / 2);
          for (i in 0...totalSpritemaps)
          {
            var name:String = '/spritemap${i + 1}';
            spritemaps.push({
              source: BitmapData.fromBytes(data.neededFiles.find(f -> f.name.endsWith('$name.png'))?.data, true),
              json: data.neededFiles.find(f -> f.name.endsWith('$name.json'))?.data?.toString() ?? ''
            });
          }

          object.applyStageMatrix = data.atlasSettings?.applyStageMatrix ?? false;
          object.useRenderTexture = data.atlasSettings?.useRenderTexture ?? false;

          var settings:FlxAnimateSettings = {
            swfMode: data.atlasSettings?.swfMode ?? false,
            cacheOnLoad: data.atlasSettings?.cacheOnLoad ?? false,
            filterQuality: cast data.atlasSettings?.filterQuality ?? animate.FlxAnimateFrames.FilterQuality.MEDIUM
          };

          object.frames = FlxAnimateFrames.fromAnimate(animateJson, spritemaps, null, data.name, true, settings);

          @:privateAccess
          cast(object.frames, FlxAnimateFrames)._settings = settings; // Settings are temporary, but we need to save them for exporting.
        default:
          // Do nothing.
      }
    }
    else if (data.assetPath.startsWith("#"))
    {
      object.loadGraphic(getDefaultGraphic());
      object.color = FlxColor.fromString(data.assetPath);
    }
    else
      object.loadGraphic(BitmapData.fromBytes(data.neededFiles[0].data, true));

    object.usedFiles = data.neededFiles;

    object.name = data.name;
    object.setPosition(data.position[0], data.position[1]);
    object.zIndex = data.zIndex;
    object.antialiasing = !data.isPixel;
    object.alpha = data.alpha;
    object.danceEvery = data.danceEvery;
    object.scrollFactor.set(data.scroll[0], data.scroll[1]);
    object.startingAnimation = data.startingAnimation ?? "";
    object.angle = data.angle;
    object.blend = blendFromString(data.blend);
    if (!data.assetPath.startsWith("#")) object.color = FlxColor.fromString(data.color);

    for (anim in data.animations)
    {
      object.addAnimation(anim);
    }

    if (object.animation.getNameList().contains(data.startingAnimation))
    {
      object.startingAnimation = data.startingAnimation;
      object.playAnimation(object.startingAnimation);

      flixel.util.FlxTimer.wait(StageEditorState.TIME_BEFORE_ANIM_STOP, function()
      {
        if (object?.animation?.curAnim != null) object.animation.stop();
      });
    }

    switch (data.scale)
    {
      case Left(value):
        object.scale.set(value, value);

      case Right(values):
        object.scale.set(values[0], values[1]);
    }
    object.updateHitbox();

    return object;
  }

  /**
   * Get the animation type of an object depending on the frames and animation count.
   */
  public static function getAnimType(object:StageEditorObject)
  {
    if (object.isAnimate) return 'animateatlas';

    // For packer we check every file for the object to see if it has a .txt file.
    for (file in object.usedFiles)
    {
      if (file.name.endsWith(".txt")) return 'packer';
    }

    return 'sparrow'; // Sparrow is the default value, even for static sprites.
  }

  /**
   * Returns a default BitmapData to be used for all the props.
   * @return BitmapData
   */
  public static function getDefaultGraphic():BitmapData
  {
    return new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE).pixels.clone();
  }

  /**
   * Returns OpenFL's BlendMode based on the Name.
   * @param blend the BlendMode Name.
   * @return BlendMode
   */
  public static function blendFromString(blend:String):BlendMode
  {
    @:privateAccess
    return BlendMode.fromString(blend.toLowerCase().trim());
  }

  public static function generateXML(obj:StageEditorObject, bitmapName:String = "")
  {
    // the last check is for if the only frame is the standard graphic frame
    if (obj == null || obj.frames.frames.length == 0 || obj.frames.frames[0].name == null) return "";

    var xml = [
      "<!--This XML File was automatically generated by the Stage Editor.-->",
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<TextureAtlas imagePath="${haxe.io.Path.withoutDirectory(bitmapName)}.png" width="${obj.pixels.width}" height="${obj.pixels.height}">'
    ].join("\n");

    for (daFrame in obj.frames.frames)
    {
      xml += ' <SubTexture name="${daFrame.name}" x="${daFrame.frame.x}" y="${daFrame.frame.y}" width="${daFrame.frame.width}" height="${daFrame.frame.height}" frameX="${- daFrame.offset.x}" frameY="${- daFrame.offset.y}" frameWidth="${daFrame.sourceSize.x}" frameHeight="${daFrame.sourceSize.y}" flipX="${daFrame.flipX}" flipY="${daFrame.flipY}" rotated="${daFrame.angle == -90}"/>\n';
    }

    xml += "</TextureAtlas>";
    return xml;
  }
}

typedef StageEditorObjectData =
{
  > StageDataProp,
  var neededFiles:Array<StageEditorState.StageEditorAssetFile>;
}
#end
