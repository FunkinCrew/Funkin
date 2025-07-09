package funkin.mobile.external.android;

import lime.math.Rectangle;
import lime.system.JNI;

/**
 * A Utility class to get Android screen related informations.
 */
class ScreenUtils
{
  @:noCompletion
  private static var staticMethodCache:Map<String, Dynamic> = [];

  @:noCompletion
  private static var memberFieldCache:Map<String, JNIMemberField> = [];

  public static function getCutoutDimensions():Array<Rectangle>
  {
    final getCutoutDimensionsJNI:Null<Dynamic> = createStaticMethod('funkin/util/ScreenUtils', 'getCutoutDimensions', '()[Landroid/graphics/Rect;');

    if (getCutoutDimensionsJNI != null)
    {
      final rectangles:Array<Rectangle> = [];

      for (rectangle in cast(getCutoutDimensionsJNI(), Array<Dynamic>))
      {
        if (rectangle == null) continue;

        final topJNI:Null<JNIMemberField> = createMemberField('android/graphics/Rect', 'top', 'I');
        final leftJNI:Null<JNIMemberField> = createMemberField('android/graphics/Rect', 'left', 'I');
        final rightJNI:Null<JNIMemberField> = createMemberField('android/graphics/Rect', 'right', 'I');
        final bottomJNI:Null<JNIMemberField> = createMemberField('android/graphics/Rect', 'bottom', 'I');

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

  public static function createStaticMethod(className:String, methodName:String, signature:String, cache:Bool = true):Null<Dynamic>
  {
    @:privateAccess
    className = JNI.transformClassName(className);

    final key:String = '$className::$methodName::$signature';

    if (cache && !staticMethodCache.exists(key)) staticMethodCache.set(key, JNI.createStaticMethod(className, methodName, signature));
    else if (!cache) return JNI.createStaticMethod(className, methodName, signature);

    return staticMethodCache.get(key);
  }

  public static function createMemberField(className:String, fieldName:String, signature:String, cache:Bool = true):Null<JNIMemberField>
  {
    @:privateAccess
    className = JNI.transformClassName(className);

    final key:String = '$className::$fieldName::$signature';

    if (cache && !memberFieldCache.exists(key)) memberFieldCache.set(key, JNI.createMemberField(className, fieldName, signature));
    else if (!cache) return JNI.createMemberField(className, fieldName, signature);

    return memberFieldCache.get(key);
  }
}
