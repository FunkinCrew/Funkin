package funkin.ui.debug.stageeditor.handlers;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.input.mouse.FlxMouse;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import funkin.data.stage.StageData.StageDataProp;
import funkin.ui.debug.stageeditor.StageEditorState;
import funkin.ui.debug.stageeditor.components.StageEditorObject;
import lime.utils.UInt8Array;
import openfl.display.BitmapData;
import openfl.display.BlendMode;

using StringTools;

@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:access(funkin.ui.debug.stageeditor.components.StageEditorObject)
@:nullSafety
class StageEditorAssetHandler
{
  // public var state:StageEditorState;
  // public function new(state:StageEditorState)
  // {
  //   this.state = state;
  // }

  /**
   * An array of all the prop bitmaps in the stage editor.
   * This is used to keep track of all the props, and to easily iterate over them,
   * making sure to optimize saving files by not saving duplicate/unused bitmaps.
   */
  public static var bitmaps:Map<String, BitmapData> = [];

  public static function toData(object:StageEditorObject, useBitmaps:Bool = false):StageEditorObjectData
  {
    var output:StageEditorObjectData =
      {
        name: object.name,
        assetPath: "",
        position: [object.x, object.y],
        zIndex: object.zIndex,
        isPixel: !object.antialiasing,
        scale: (object.scale == null) ? Left(1.0) : object.scale.x == object.scale.y ? Left(object.scale.x) : Right([object.scale.x, object.scale.y]),
        alpha: object.alpha,
        danceEvery: object.animation.getNameList().length > 0 ? object.danceEvery : 0,
        scroll: [object.scrollFactor.x, object.scrollFactor.y],
        animations: [for (n => d in object.animData) d],
        startingAnimation: object.startingAnimation,
        animType: "sparrow", // We're automatically making sparrow atlases, yeah...
        angle: object.angle,
        flipX: object.flipX,
        flipY: object.flipY,
        blend: object.blend == null ? "" : Std.string(object.blend),
        color: object.color.toWebString(),
        animData: ""
      }

    if (useBitmaps)
    {
      output.bitmap = object.pixels.clone();
      output.animData = object.generateXML();
      return output;
    }

    for (name => bit in bitmaps)
    {
      if (areBitmapsEqual(bit, object.pixels))
      {
        output.assetPath = name;
        output.animData = object.generateXML(name);
        return output;
      }
    }

    output.assetPath = "#FFFFFF";

    return output;
  }

  /**
   * Creates a StageEditorObject from the given data.
   * If the data contains a bitmap, it will use that instead of looking for the assetPath.
   * If the assetPath is a solid color (starts with #), it will create a color graphic.
   * @return StageEditorObject The object
   */
  public static function fromData(object:StageEditorObject, data:StageEditorObjectData):StageEditorObject
  {
    var hasAnimations = data.animations != null && data.animations.length > 0;
    var isSolidColor = data.assetPath.startsWith('#');

    if (data.bitmap != null)
    {
      var bitmapID = addBitmap(data.bitmap.clone());
      var bitmap = bitmaps.get(bitmapID);
      if (bitmap == null) return object; // This should never happen, but just in case

      if (hasAnimations && bitmap != null) object.frames = FlxAtlasFrames.fromSparrow(bitmap, data.animData);
      else if (areBitmapsEqual(data.bitmap, getDefaultGraphic())) object.loadGraphic(getDefaultGraphic());
      else
      {
        if (bitmap != null) object.loadGraphic(bitmap.clone());
      }
    }
    else
    {
      var bitmap = bitmaps.get(data.assetPath);
      if (bitmap == null && !isSolidColor) return object; // This should never happen, but just in case
      if (hasAnimations)
      {
        var bitmapData = bitmap?.clone();
        if (bitmapData != null) object.frames = data.animData.contains('<TextureAtlas') ? FlxAtlasFrames.fromSparrow(bitmapData,
          data.animData) : FlxAtlasFrames.fromSpriteSheetPacker(bitmapData, data.animData);
      }
      else if (isSolidColor)
      {
        object.loadGraphic(getDefaultGraphic());
        if (data.assetPath != null) object.color = FlxColor.fromString(data?.assetPath ?? '#00000000') ?? 0x00000000;
      }
      else
      {
        if (bitmap != null) object.loadGraphic(bitmap.clone());
      }
    }

    object.name = data.name ?? 'Unnamed';
    object.setPosition(data.position[0], data.position[1]);
    object.zIndex = data.zIndex ?? 0;
    object.antialiasing = !(data.isPixel ?? false);
    object.alpha = data.alpha ?? 1.0;
    object.danceEvery = data.danceEvery ?? 0.0;
    object.scrollFactor.set(data.scroll != null ? data.scroll[0] : 1.0, data.scroll != null ? data.scroll[1] : 1.0);
    object.startingAnimation = data.startingAnimation ?? '';
    object.angle = data.angle ?? 0;
    @:privateAccess object.blend = BlendMode.fromString((data.blend ?? '').toLowerCase().trim());
    if (!isSolidColor) object.color = FlxColor.fromString(data?.color ?? '#00000000') ?? 0x00000000;

    for (anim in data.animations ?? [])
    {
      object.addAnimation(anim.name ?? 'Unknown', anim.prefix ?? '', anim.offsets ?? [0, 0], anim.frameIndices ?? [], anim.frameRate ?? 24,
        anim.looped ?? false, anim.flipX ?? false, anim.flipY ?? false);
    }

    switch (data.scale ?? Left(1.0))
    {
      case Left(value):
        object.scale.set(value, value);
      case Right(values):
        object.scale.set(values[0], values[1]);
    }
    object.updateHitbox();

    if (object.animation.getNameList().contains(data.startingAnimation ?? '')) object.startingAnimation = data.startingAnimation ?? '';

    return object;
  }

  /**
   * Returns a default BitmapData to be used for all the props.
   * @return BitmapData
   */
  public static function getDefaultGraphic():BitmapData
  {
    return new FlxSprite().makeGraphic(100, 100, FlxColor.BLACK).pixels.clone();
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
      xml += '  <SubTexture name="${daFrame.name}" x="${daFrame.frame.x}" y="${daFrame.frame.y}" width="${daFrame.frame.width}" height="${daFrame.frame.height}" frameX="${- daFrame.offset.x}" frameY="${- daFrame.offset.y}" frameWidth="${daFrame.sourceSize.x}" frameHeight="${daFrame.sourceSize.y}" flipX="${daFrame.flipX}" flipY="${daFrame.flipY}" rotated="${daFrame.angle == -90}"/>\n';
    }

    xml += "</TextureAtlas>";
    return xml;
  }

  /** While there is a similar function in OpenFL,
   * it is a bit longer since it actually outputs the bitmap difference
   */
  static function areBitmapsEqual(bitmap1:BitmapData, bitmap2:BitmapData)
  {
    if (bitmap1.width != bitmap2.width || bitmap1.height != bitmap2.height) return false;

    var bytes1:UInt8Array = bitmap1.image.data;
    var bytes2:UInt8Array = bitmap2.image.data;

    if (bytes1 == null || bytes2 == null) return false;

    for (i in 0...bytes1.length)
    {
      @:nullSafety(Off)
      if (bytes1[i] != bytes2[i]) return false;
    }

    return true;
  }

  /**
   * This removes any bitmaps that are not being used by any props.
   * This is useful for keeping the memory usage low, especially when there are a lot of props.
   */
  public static function removeUnusedBitmaps(state:StageEditorState):Void
  {
    var usedBitmaps:Array<String> = [];

    for (asset in state.spriteArray ?? [])
    {
      var data = asset.toData(false);
      if (data.assetPath.startsWith("#")) continue; // The simple graphics, aka just the color

      if (data.assetPath != null) usedBitmaps.push(data.assetPath);
    }

    for (name => bit in bitmaps)
    {
      if (usedBitmaps.contains(name)) continue;
      bitmaps.remove(name);
    }
  }

  /**
   * Adds a bitmap to the internal bitmap map, and returns the ID of the bitmap.
   * If the bitmap already exists, it will return the existing ID instead of adding a new one.
   */
  public static function addBitmap(newBitmap:BitmapData):String
  {
    // First we check for existing bitmaps, so that way we don't add duplicates
    for (name => bitmap in bitmaps)
    {
      if (bitmap == newBitmap) return name;
    }

    var id:Int = 0;
    while (bitmaps.exists("image" + id))
      id++;

    bitmaps.set("image" + id, newBitmap);
    return "image" + id;
  }

  public static function sortObjects(state:StageEditorState):Void
  {
    state.sortAssets();
    state.spriteArray = [];

    for (item in state.members)
    {
      if (Std.isOfType(item, StageEditorObject)) state.spriteArray.push(cast item);
    }
  }

  public static function sortAssets(state:StageEditorState):Void
  {
    state.sort(funkin.util.SortUtil.byZIndex, flixel.util.FlxSort.ASCENDING);
  }

  public static function clearAssets(state:StageEditorState):Void
  {
    state.selectedProp = null;

    while (state.spriteArray.length > 0)
    {
      var obj = state.spriteArray.pop();
      if (obj == null) continue;

      obj.kill();
      state.remove(obj, true);
      obj.destroy();
      obj = null;
    }

    state.undoHistory = [];
    state.redoHistory = [];
    state.commandHistoryDirty = true;
    state.sortObjects();
    state.removeUnusedBitmaps();
  }

  public static function pixelPerfectCheck(mouse:FlxMouse, sprite:FlxSprite):Bool
  {
    if (sprite == null || mouse == null) return false;

    if (!mouse.overlaps(sprite)) return false;

    return sprite.pixelsOverlapPoint(mouse.getWorldPosition());

    return false;
  }
}

typedef StageEditorObjectData =
{
  > StageDataProp,
  var animData:String;
  var ?bitmap:BitmapData;
}
