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
    var rectangle:Rectangle = new Rectangle();

    #if ios
    final top:Float = -1;
    final left:Float = -1;
    final right:Float = -1;
    final bottom:Float = -1;
    ScreenUtils.getSafeAreaInsets(cpp.Pointer.addressOf(top).raw, cpp.Pointer.addressOf(bottom).raw, cpp.Pointer.addressOf(left).raw,
      cpp.Pointer.addressOf(right).raw);
    rectangle.x = left;
    rectangle.y = right;
    rectangle.width = top;
    rectangle.height = bottom;
    #elseif android
    var rectDimensions:Array<Array<Float>> = [[], [], [], []];
    for (rect in Tools.getCutoutDimensions())
    {
      rectDimensions[0].push(rect.x);
      rectDimensions[1].push(rect.y);
      rectDimensions[2].push(rect.width);
      rectDimensions[3].push(rect.height);
    }

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
    #end

    return rectangle;
  }
}
