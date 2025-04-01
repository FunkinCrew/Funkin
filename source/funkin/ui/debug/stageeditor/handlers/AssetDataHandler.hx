package funkin.ui.debug.stageeditor.handlers;

import flixel.FlxG;
import openfl.display.BitmapData;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxRect;
import openfl.display.BlendMode;
import flixel.math.FlxPoint;
import funkin.data.stage.StageData.StageDataProp;

using StringTools;

/**
 * Handles the Stage Props and Datas - being able to convert one to the other.
 */
class AssetDataHandler
{
  static var state:StageEditorState;

  public static function init(state:StageEditorState)
  {
    AssetDataHandler.state = state;
  }

  /**
   * Turns an Object into Data.
   * @param obj the Object whose data to read.
   * @param useBitmaps Whether to Save object's BitmapData directly.
   * @return Data of the Object
   */
  public static function toData(obj:StageEditorObject, useBitmaps:Bool = false):StageEditorObjectData
  {
    var outputData:StageEditorObjectData =
      {
        name: obj.name,
        assetPath: "",
        position: [obj.x, obj.y],
        zIndex: obj.zIndex,
        isPixel: !obj.antialiasing,
        scale: obj.scale.x == obj.scale.y ? Left(obj.scale.x) : Right([obj.scale.x, obj.scale.y]),
        alpha: obj.alpha,
        danceEvery: obj.animation.getNameList().length > 0 ? obj.danceEvery : 0,
        scroll: [obj.scrollFactor.x, obj.scrollFactor.y],
        animations: [for (n => d in obj.animDatas) d],
        startingAnimation: obj.startingAnimation,
        animType: "sparrow", // automatically making sparrow atlases yeah
        angle: obj.angle,
        blend: obj.blend == null ? "" : Std.string(obj.blend),
        color: obj.color.toWebString(),
        xmlData: obj.generateXML()
      }

    if (useBitmaps)
    {
      outputData.bitmap = obj.pixels.clone();
      return outputData;
    }

    for (name => bit in state.bitmaps)
    {
      if (areTheseBitmapsEqual(bit, obj.pixels))
      {
        outputData.assetPath = name;
        return outputData;
      }
    }

    outputData.assetPath = "#FFFFFF";

    return outputData;
  }

  /**
   * Modifies an Object based on the Data.
   * @param object Object to modify. Set to null to create a new one.
   * @param data The Data used for the Object.
   */
  public static function fromData(object:StageEditorObject, data:StageEditorObjectData)
  {
    if (data.bitmap != null)
    {
      var bitToLoad = state.addBitmap(data.bitmap.clone());
      object.loadGraphic(state.bitmaps[bitToLoad]);
    }
    else
    {
      if (data.animations != null && data.animations.length > 0) // considering we're unpacking we might as well just do this instead of switch
      {
        object.frames = flixel.graphics.frames.FlxAtlasFrames.fromSparrow(state.bitmaps[data.assetPath].clone(), data.xmlData);
      }
      else if (data.assetPath.startsWith("#"))
      {
        object.loadGraphic(getDefaultGraphic());
        object.color = FlxColor.fromString(data.assetPath);
      }
      else
        object.loadGraphic(state.bitmaps[data.assetPath].clone());
    }

    object.name = data.name;
    object.setPosition(data.position[0], data.position[1]);
    object.zIndex = data.zIndex;
    object.antialiasing = !data.isPixel;
    object.alpha = data.alpha;
    object.danceEvery = data.danceEvery;
    object.scrollFactor.set(data.scroll[0], data.scroll[1]);
    object.startingAnimation = data.startingAnimation;
    object.angle = data.angle;
    object.blend = blendFromString(data.blend);
    if (!data.assetPath.startsWith("#")) object.color = FlxColor.fromString(data.color);

    // yeah
    object.pixelPerfectRender = data.isPixel;
    object.pixelPerfectPosition = data.isPixel;

    for (anim in data.animations)
    {
      object.addAnim(anim.name, anim.prefix, anim.offsets ?? [0, 0], anim.frameIndices ?? [], anim.frameRate ?? 24, anim.looped ?? false, anim.flipX ?? false,
        anim.flipY ?? false);
    }

    if (object.animation.getNameList().contains(data.startingAnimation)) object.startingAnimation = data.startingAnimation;

    switch (data.scale)
    {
      case Left(value):
        object.scale.set(value, value);

      case Right(values):
        object.scale.set(values[0], values[1]);
    }
    object.updateHitbox();

    object.playAnim(object.startingAnimation);

    flixel.util.FlxTimer.wait(StageEditorState.TIME_BEFORE_ANIM_STOP, function() {
      if (object != null && object.animation.curAnim != null) object.animation.stop();
    });

    return object;
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
    // originally this was a MASSIVE and I do mean MASSIVE switch case, though then I found out that blendmode already has one implemented
    @:privateAccess
    return BlendMode.fromString(blend.toLowerCase().trim());
  }

  public static function generateXML(obj:StageEditorObject)
  {
    // the last check is for if the only frame is the standard graphic frame
    if (obj == null || obj.frames.frames.length == 0 || obj.frames.frames[0].name == null) return "";

    var xml = [
      "<!--This XML File was automatically generated by StageEditorEngine, in order to make Funkin' be able to load it.-->",
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<TextureAtlas imagePath="${obj.toData(false).assetPath}.png" width="${obj.pixels.width}" height="${obj.pixels.height}">'
    ].join("\n");

    for (daFrame in obj.frames.frames)
    {
      xml += '  <SubTexture name="${daFrame.name}" x="${daFrame.frame.x}" y="${daFrame.frame.y}" width="${daFrame.frame.width}" height="${daFrame.frame.height}" frameX="${- daFrame.offset.x}" frameY="${- daFrame.offset.y}" frameWidth="${daFrame.sourceSize.x}" frameHeight="${daFrame.sourceSize.y}" flipX="${daFrame.flipX}" flipY="${daFrame.flipY}"/>\n';
    }

    xml += "</TextureAtlas>";
    return xml;
  }

  // I am aware OpenFL has it's own compare bitmap function, though I find this to be better ngl
  static function areTheseBitmapsEqual(bitmap1:BitmapData, bitmap2:BitmapData)
  {
    if (bitmap1.width != bitmap2.width || bitmap1.height != bitmap2.height) return false;

    for (px in 0...bitmap1.width)
    {
      for (py in 0...bitmap1.height)
      {
        if (bitmap1.getPixel32(px, py) != bitmap2.getPixel32(px, py)) return false;
      }
    }

    return true;
  }
}

typedef StageEditorObjectData =
{
  > StageDataProp,
  var xmlData:String;
  var ?bitmap:BitmapData;
}
