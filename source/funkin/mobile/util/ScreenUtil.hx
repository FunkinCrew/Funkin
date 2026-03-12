package funkin.mobile.util;

#if ios
import funkin.external.apple.ScreenUtil as NativeScreenUtil;
#elseif android
import funkin.external.android.ScreenUtil as NativeScreenUtil;
#end
import lime.system.System;
import lime.app.Application;
import openfl.geom.Rectangle;

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

    notchRect.x = 0.0;
    notchRect.y = 0.0;

    #if android
    final rectDimensions:Array<Array<Float>> = [[], [], [], []];

    // Push all the dimensions of the cutouts into an array
    for (rect in NativeScreenUtil.getCutoutDimensions())
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

    NativeScreenUtil.getSafeAreaInsets(cpp.RawPointer.addressOf(topInset), cpp.RawPointer.addressOf(bottomInset), cpp.RawPointer.addressOf(leftInset),
      cpp.RawPointer.addressOf(rightInset));
    NativeScreenUtil.getScreenSize(cpp.RawPointer.addressOf(deviceWidth), cpp.RawPointer.addressOf(deviceHeight));

    // Calculate the rectangle dimensions for the notch
    // Note: iOS only spits out *insets* for "safe areas", so we can only get a broad position for the notch
    // Note: *inset* is the distance from the edge of the screen where a safe area gets defined
    // see: https://developer.apple.com/documentation/uikit/uiview/safeareainsets
    switch (System.getDisplayOrientation(Application.current.window.display))
    {
      case DISPLAY_ORIENTATION_LANDSCAPE: // landscape
        notchRect.width = leftInset;
        notchRect.height = deviceHeight;
      case DISPLAY_ORIENTATION_LANDSCAPE_FLIPPED: // landscape
        notchRect.width = leftInset;
        notchRect.height = deviceHeight;
        notchRect.x = deviceWidth - rightInset;
      case DISPLAY_ORIENTATION_PORTRAIT: // portrait
        notchRect.width = deviceWidth;
        notchRect.height = topInset;
      case DISPLAY_ORIENTATION_PORTRAIT_FLIPPED: // portrait
        notchRect.width = deviceWidth;
        notchRect.height = bottomInset;
        notchRect.y = deviceHeight - notchRect.height; // move notchRect if we are flipped, the notch is at the bottom of screen
      default: // display orientation unknown? perhaps this occurs on desktop
    }
    #end

    return notchRect;
  }
}
