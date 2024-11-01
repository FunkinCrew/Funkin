package funkin.util;

import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class BitmapUtil
{
  /**
   * Scales the bitmap by adding a specific width at a specific position.
   * @param bitmap The original bitmap to modify.
   * @param additionalWidth The desired additional width for one side of the bitmap.
   * @param scalePosition The position of where it should the width should be added, If null it'll use the left side of the bitmap.
   * @return A new BitmapData with the specified side scaled to the additional width.
   */
  public static function scalePartByWidth(bitmap:BitmapData, additionalWidth:Float, ?scalePosition:Float):BitmapData
  {
    if (scalePosition == null) scalePosition = bitmap.width / 2;
    var addedWidth = Math.floor(additionalWidth);
    var scaledPartWidth = scalePosition + addedWidth;
    var scaleFactor = scaledPartWidth / scalePosition;

    var matrix = new Matrix();
    matrix.scale(scaleFactor, 1);

    var scaledBitmap = new BitmapData(Math.floor(bitmap.width + addedWidth), bitmap.height, true, 0);

    var leftPortionRect = new Rectangle(0, 0, scalePosition, bitmap.height);
    var leftBitmap = new BitmapData(Math.floor(scalePosition), bitmap.height, true, 0);
    leftBitmap.copyPixels(bitmap, leftPortionRect, new Point(0, 0));

    scaledBitmap.draw(leftBitmap, matrix, null, null, new Rectangle(0, 0, scaledPartWidth, bitmap.height));

    var rightPortion = new Rectangle(scalePosition, 0, bitmap.width - scalePosition, bitmap.height);
    scaledBitmap.copyPixels(bitmap, rightPortion, new Point(scaledPartWidth, 0));

    return scaledBitmap;
  }
}
