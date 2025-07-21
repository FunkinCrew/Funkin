package funkin.mobile.external.android;

#if android
import lime.system.JNI;

/**
 * A utility class for caching JNI method and field references.
 */
class JNIUtil
{
  @:noCompletion
  private static var staticMethodCache:Map<String, Dynamic> = [];

  @:noCompletion
  private static var memberMethodCache:Map<String, Dynamic> = [];

  @:noCompletion
  private static var staticFieldCache:Map<String, JNIStaticField> = [];

  @:noCompletion
  private static var memberFieldCache:Map<String, JNIMemberField> = [];

  /**
   * Retrieves or creates a cached static method reference.
   *
   * @param className The name of the Java class containing the method.
   * @param methodName The name of the method.
   * @param signature The method signature in JNI format.
   * @param cache Whether to cache the result (default true).
   * @return A dynamic reference to the static method.
   */
  public static function createStaticMethod(className:String, methodName:String, signature:String, cache:Bool = true):Null<Dynamic>
  {
    @:privateAccess
    className = JNI.transformClassName(className);

    final key:String = '$className::$methodName::$signature';

    if (cache && !staticMethodCache.exists(key)) staticMethodCache.set(key, JNI.createStaticMethod(className, methodName, signature));
    else if (!cache) return JNI.createStaticMethod(className, methodName, signature);

    return staticMethodCache.get(key);
  }

  /**
   * Retrieves or creates a cached member method reference.
   *
   * @param className The name of the Java class containing the method.
   * @param methodName The name of the method.
   * @param signature The method signature in JNI format.
   * @param cache Whether to cache the result (default true).
   * @return A dynamic reference to the member method.
   */
  public static function createMemberMethod(className:String, methodName:String, signature:String, cache:Bool = true):Null<Dynamic>
  {
    @:privateAccess
    className = JNI.transformClassName(className);

    final key:String = '$className::$methodName::$signature';

    if (cache && !memberMethodCache.exists(key)) memberMethodCache.set(key, JNI.createMemberMethod(className, methodName, signature));
    else if (!cache) return JNI.createMemberMethod(className, methodName, signature);

    return memberMethodCache.get(key);
  }

  /**
   * Retrieves or creates a cached static field reference.
   *
   * @param className The name of the Java class containing the field.
   * @param fieldName The name of the field.
   * @param signature The field signature in JNI format.
   * @param cache Whether to cache the result (default true).
   * @return A reference to the static field.
   */
  public static function createStaticField(className:String, fieldName:String, signature:String, cache:Bool = true):Null<JNIStaticField>
  {
    @:privateAccess
    className = JNI.transformClassName(className);

    final key:String = '$className::$fieldName::$signature';

    if (cache && !staticFieldCache.exists(key)) staticFieldCache.set(key, JNI.createStaticField(className, fieldName, signature));
    else if (!cache) return JNI.createStaticField(className, fieldName, signature);

    return staticFieldCache.get(key);
  }

  /**
   * Retrieves or creates a cached member field reference.
   *
   * @param className The name of the Java class containing the field.
   * @param fieldName The name of the field.
   * @param signature The field signature in JNI format.
   * @param cache Whether to cache the result (default true).
   * @return A reference to the member field.
   */
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
#end
