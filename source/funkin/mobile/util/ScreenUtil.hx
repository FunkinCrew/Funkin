package funkin.mobile.util;

#if ios
import funkin.mobile.external.ScreenUtils;
#elseif android
import android.Tools;
#end
import lime.math.Rectangle;

/**
 * A Utility class to get mobile screen related informations.
 */
class ScreenUtil
{
  /**
   * Get `Rectangle` Object that contains the dimensions of the screen's Notch.
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
    rectangle.width = -(width - left - right);
    rectangle.width += width;
    rectangle.height = top;
    rectangle.x = left;
    // notchs are always at the top of the screen so they have 0 y position
    rectangle.y = 0.0;
    #end

    return rectangle;
  }
}
