package funkin.mobile.util;

#if ios
import funkin.mobile.external.ScreenUtils;
#elseif android
import extension.androidtools.Tools;
#end
import lime.math.Rectangle;

/**
 * A Utility class to get mobile screen related informations.
 */
class ScreenUtil
{
  /**
   * Get `Rectangle` Object that contains the dimensions of the screen's Notch.
   * Scales the dimensions to return coords in pixels, not points
   * @return Rectangle
   */
  public static function getNotchRect():Rectangle
  {
    final rectangle:Rectangle = new Rectangle();

    #if android
    final rectDimensions:Array<Array<Float>> = [[], [], [], []];

    // Push all the dimensions of the cutouts into an array
    for (rect in Tools.getCutoutDimensions())
    {
      rectDimensions[0].push(rect.x);
      rectDimensions[1].push(rect.y);
      rectDimensions[2].push(rect.width);
      rectDimensions[3].push(rect.height);
    }

    // Put all the dimensions into the rectangle
    for (i => dimensions in rectDimensions)
    {
      for (dimension in dimensions)
      {
        switch (i)
        {
          case 0:
            rectangle.x += dimension;
          case 1:
            rectangle.y += dimension;
          case 2:
            rectangle.width += dimension;
          case 3:
            rectangle.height += dimension;
        }
      }
    }
    #elseif ios
    var top:Float = -1;
    var left:Float = -1;
    var right:Float = -1;
    var bottom:Float = -1;
    var width:Float = -1;
    var height:Float = -1;

    ScreenUtils.getSafeAreaInsets(cpp.RawPointer.addressOf(top), cpp.RawPointer.addressOf(bottom), cpp.RawPointer.addressOf(left),
      cpp.RawPointer.addressOf(right));

    ScreenUtils.getScreenSize(cpp.RawPointer.addressOf(width), cpp.RawPointer.addressOf(height));

    // Calculate the rectangle dimensions for the notch
    // Note: iOS only spits out *insets* for "safe areas", so we can only get a broad position for the notch
    // left + right insets are the same, so we can use either

    // If we're in landscape, we want to create the rectangle with our left inset as width (notch width),
    // otherwise, we can just use the screen width
    rectangle.width = left > top ? left : width;

    // If we're in landscape, we want to create the rectangle with the screen size as height,
    // otherwise, we use the top inset as height
    rectangle.height = left > top ? height : top;

    // Todo: Check which landscape orientation we're in, and set `rectangle.x = width - right` if we're in flipped landscape
    rectangle.x = 0;
    rectangle.y = 0.0;
    #end

    return rectangle;
  }
}
