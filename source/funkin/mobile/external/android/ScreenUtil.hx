package funkin.mobile.external.android;

import lime.math.Rectangle;
import lime.system.JNI;

/**
 * A Utility class to get Android screen related informations.
 */
@:unreflective
class ScreenUtil
{
  #if android
  /**
   * Retrieves the dimensions of display cutouts (such as notches) on Android devices.
   *
   * @return An array of `Rectangle` objects, each representing a display cutout's position and size.
   */
  public static function getCutoutDimensions():Array<Rectangle>
  {
    final getCutoutDimensionsJNI:Null<Dynamic> = JNIUtil.createStaticMethod('funkin/util/ScreenUtil', 'getCutoutDimensions', '()[Landroid/graphics/Rect;');

    if (getCutoutDimensionsJNI != null)
    {
      final rectangles:Array<Rectangle> = [];

      for (rectangle in cast(getCutoutDimensionsJNI(), Array<Dynamic>))
      {
        if (rectangle == null) continue;

        final topJNI:Null<JNIMemberField> = JNIUtil.createMemberField('android/graphics/Rect', 'top', 'I');
        final leftJNI:Null<JNIMemberField> = JNIUtil.createMemberField('android/graphics/Rect', 'left', 'I');
        final rightJNI:Null<JNIMemberField> = JNIUtil.createMemberField('android/graphics/Rect', 'right', 'I');
        final bottomJNI:Null<JNIMemberField> = JNIUtil.createMemberField('android/graphics/Rect', 'bottom', 'I');

        if (topJNI != null && leftJNI != null && rightJNI != null && bottomJNI != null)
        {
          final top:Int = topJNI.get(rectangle);
          final left:Int = leftJNI.get(rectangle);
          final right:Int = rightJNI.get(rectangle);
          final bottom:Int = bottomJNI.get(rectangle);

          rectangles.push(new Rectangle(left, top, right - left, bottom - top));
        }
      }

      return rectangles;
    }

    return [];
  }
  #end
}
