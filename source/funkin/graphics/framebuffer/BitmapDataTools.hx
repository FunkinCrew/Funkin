package funkin.graphics.framebuffer;

import flixel.FlxG;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.filters.BitmapFilter;

/**
 * Provides cool stuff for `BitmapData`s that have a hardware texture internally.
 */
class BitmapDataTools
{
  /**
   * Applies a bitmap filter to a bitmap immediately. The bitmap filter may refer
   * the bitmap itself as a shader input.
   * @param bitmap the bitmap data
   * @param filter the bitmap filter
   */
  public static function applyFilter(bitmap:BitmapData, filter:BitmapFilter):Void
  {
    if (bitmap.readable)
    {
      FlxG.log.error('do not use `BitmapDataTools` for non-GPU bitmaps!');
    }
    // man, allow me to use anon structuers for local vars!
    static var cache:{sprite:Sprite, bitmap:Bitmap} = null;
    if (cache == null)
    {
      final sprite = new Sprite();
      final bitmap = new Bitmap();
      sprite.addChild(bitmap);
      cache =
        {
          sprite: sprite,
          bitmap: bitmap
        }
    }
    cache.bitmap.bitmapData = bitmap;
    cache.sprite.filters = [filter];
    bitmap.draw(cache.sprite);
  }
}
