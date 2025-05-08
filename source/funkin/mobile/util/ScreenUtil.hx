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
    final notchRect:Rectangle = new Rectangle();

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
            notchRect.x += dimension;
          case 1:
            notchRect.y += dimension;
          case 2:
            notchRect.width += dimension;
          case 3:
            notchRect.height += dimension;
        }
      }
    }
    #elseif ios
    var topInset:Float = -1;
    var leftInset:Float = -1;
    var rightInset:Float = -1;
    var bottomInset:Float = -1;
    var deviceWidth:Float = -1;
    var deviceHeight:Float = -1;

    ScreenUtils.getSafeAreaInsets(cpp.RawPointer.addressOf(topInset), cpp.RawPointer.addressOf(bottomInset), cpp.RawPointer.addressOf(leftInset),
      cpp.RawPointer.addressOf(rightInset));

    ScreenUtils.getScreenSize(cpp.RawPointer.addressOf(deviceWidth), cpp.RawPointer.addressOf(deviceHeight));

    // Calculate the rectangle dimensions for the notch
    // Note: iOS only spits out *insets* for "safe areas", so we can only get a broad position for the notch
    // left + right insets are the same, so we can use either

    // If we're in landscape, we want to create the rectangle with our left inset as width (notch width),
    // otherwise, we can just use the screen width
    notchRect.width = leftInset > topInset ? leftInset : deviceWidth;

    // If we're in landscape, we want to create the rectangle with the screen size as height,
    // otherwise, we use the top inset as height
    notchRect.height = leftInset > topInset ? deviceHeight : topInset;

    // Todo: Check which landscape orientation we're in, and set `rectangle.x = width - right` if we're in flipped landscape
    notchRect.x = 0;
    notchRect.y = 0.0;
    #end

    return notchRect;
  }
}
