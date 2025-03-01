package funkin.ui.debug.char.animate;

import flxanimate.frames.FlxAnimateFrames;
import flxanimate.data.SpriteMapData.AnimateAtlas;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import openfl.display.BitmapData;

// yoinked from FlxAnimateFrames, but supports different inputs!
// this is cuz FlxAnimate doesn't support absolute (FileSystem) paths but only relative (openfl.Assets) paths!
class CharSelectAnimateFrames extends FlxAtlasFrames
{
  public function new()
  {
    super(null);
    parents = [];
  }

  public var parents:Array<FlxGraphic>;

  public static function fromTextureAtlas(spriteMapArray:Array<String>, bitmaps:Map<String, BitmapData>):CharSelectAnimateFrames
  {
    var frames = new CharSelectAnimateFrames();

    for (item in spriteMapArray)
    {
      var daJson:AnimateAtlas = haxe.Json.parse(item);
      if (daJson == null) continue;

      // copied from findImage or sumth

      var graphic = flixel.FlxG.bitmap.add(bitmaps[daJson.meta.image]);

      var frameThingOne = FlxAtlasFrames.findFrame(graphic);
      if (frameThingOne?.frames != null)
      {
        frames.addFromFrames(frameThingOne);
        continue;
      }

      // resuming to copy more
      var frameThingTwo = new FlxAtlasFrames(graphic);
      for (sprite in daJson.ATLAS.SPRITES)
      {
        var limb = sprite.SPRITE;
        var rect = flixel.math.FlxRect.get(limb.x, limb.y, limb.w, limb.h);
        if (limb.rotated) rect.setSize(rect.height, rect.width);

        FlxAnimateFrames.sliceFrame(limb.name, limb.rotated, rect, frameThingTwo);
      }

      frames.addFromFrames(frameThingTwo);
    }

    return frames;
  }

  public function addFromFrames(collection:FlxFramesCollection)
  {
    if (parents.indexOf(collection.parent) == -1) parents.push(collection.parent);
    for (frame in collection.frames)
      pushFrame(frame);
    return this;
  }
}
