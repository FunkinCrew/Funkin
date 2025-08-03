package funkin.util;

import flixel.FlxG;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class BitmapUtil
{
  public static function createResultsBar():BitmapData
  {
    final width:Int = Math.ceil(FlxG.width * 1.011);
    final mainBitmap = new BitmapData(width, Math.ceil(width / 8.7), true, 0xFF000000);
    final bitmap = new BitmapData(width, Math.ceil(width / 8.7), true, 0);
    final rect = mainBitmap.rect.clone();
    final matrix = new Matrix();

    matrix.rotate(-3.8 * Math.PI / 180);
    matrix.translate(-15, 0);
    rect.width -= 15;

    bitmap.draw(mainBitmap, matrix, rect, true);
    return bitmap;
  }

  /**
   * Scales the bitmap at a specific position.
   * @param bitmap The original bitmap to scale.
   * @param scale The desired scale for the bitmap part (X Scale only).
   * @param scalePosition The position of where it should scale the bitmap, If null it'll use the middle of the bitmap.
   * @return A new BitmapData scaled at the specified position.
   */
  public static function scalePart(bitmap:BitmapData, scale:Float, ?scalePosition:Float):BitmapData
  {
    if (scalePosition == null) scalePosition = bitmap.width / 2;
    final scaledPartWidth:Int = Math.ceil(scalePosition * scale);
    final finalBitmap:BitmapData = new BitmapData(Math.ceil(bitmap.width + scalePosition), bitmap.height, true, 0);

    final matrix:Matrix = new Matrix();
    final rect:Rectangle = bitmap.rect.clone();
    matrix.scale(scale, 1);
    rect.width = scaledPartWidth;
    finalBitmap.draw(bitmap, matrix, rect, true);

    final rect:Rectangle = bitmap.rect.clone();
    rect.x = scalePosition;
    finalBitmap.copyPixels(bitmap, rect, new Point(scaledPartWidth, 0));

    return finalBitmap;
  }

  /**
   * Scales the bitmap by adding a specific width at a specific position.
   * @param bitmap The original bitmap to modify.
   * @param additionalWidth The desired additional width to add to the bitmap.
   * @param scalePosition The position of where it should scale the bitmap, If null it'll use the middle of the bitmap.
   * @return A new BitmapData scaled at the specified position.
   */
  public static function scalePartByWidth(bitmap:BitmapData, additionalWidth:Float, ?scalePosition:Float):BitmapData
  {
    if (scalePosition == null) scalePosition = bitmap.width / 2;
    final scaledPartWidth:Int = Math.ceil(scalePosition + additionalWidth);
    final scale:Float = scaledPartWidth / scalePosition;
    final finalBitmap:BitmapData = new BitmapData(Math.ceil(bitmap.width + additionalWidth), bitmap.height, true, 0);

    final matrix:Matrix = new Matrix();
    final rect:Rectangle = bitmap.rect.clone();
    matrix.scale(scale, 1);
    rect.width = scaledPartWidth;
    finalBitmap.draw(bitmap, matrix, rect, true);

    final rect:Rectangle = bitmap.rect.clone();
    rect.x = scalePosition;
    finalBitmap.copyPixels(bitmap, rect, new Point(scaledPartWidth, 0));

    return finalBitmap;
  }
}
