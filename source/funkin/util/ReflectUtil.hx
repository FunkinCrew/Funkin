package funkin.util;

/**
 * Provides sanitized and blacklisted access to haxe's Reflection functions.
 * Used for sandboxing in scripts.
 */
@:nullSafety
@:build(funkin.util.macro.BlacklistClassMacro.build(
  {
    classes: ['Reflect', 'Type'],
    aliases:
    [
      'compare' => ['compareValues'],
      'copy' => ['copyAnonymousFieldsOf'],
      'deleteField' => ['deleteAnonymousField', 'delete'],
      'field' => ['getAnonymousField', 'getField'],
      'fields' => ['getAnonymousFieldsOf', 'getFieldsOf'],
      'hasField' => ['hasAnonymousField'],
      'setField' => ['setAnonymousField']
    ],
    wrapList:
    [
      'compare',
      'compareMethods',
      'copy',
      'enumEq',
      'deleteField',
      'fields',
      'getClassFields',
      'getClassName',
      'getEnumName',
      'getInstanceFields',
      'isEnumValue',
      'isFunction',
      'isObject',
      'makeVarArgs',
      'setField',
      'setProperty'
    ]
  }))
class ReflectUtil
{
  /**
   * A list of field names which cannot be retrieved with `getAnonymousField()`
   */
  @:unreflective
  static var FIELD_NAME_BLACKLIST:Array<String> = ['_interp'];

  /**
   * This function is not allowed to be used by scripts.
   * @throws error When called by a script.
   */
  // public static function callMethod(obj:Any, name:String, args:Array<Any>):Any
  /**
   * Compares two objects by value.
   *
   * The actual function exists and is generated at build time.
   * @param valueA First value to compare
   * @param valueB Second value to compare
   * @return Int indicating relative order of values
   */
  // public static function compare(valueA:Any, valueB:Any):Int
  /**
   * Compares two values and returns an integer indicating their relative order.
   * Returns:
   * - -1 if valueA < valueB
   * - 0 if valueA == valueB
   * - 1 if valueA > valueB
   *
   * The actual function exists and is generated at build time.
   * @param valueA First value to compare
   * @param valueB Second value to compare
   * @return An integer indicating relative order of values
   */
  // public static function compareValues(valueA:Any, valueB:Any):Int
  /**
   * Compare the two Function objects to determine whether they are the same.
   * @param functionA A method closure to compare.
   * @param functionB A method closure to compare.
   * @return Whether functionA and functionB are equal.
   */
  // public static function compareMethods(functionA:Any, functionB:Any):Bool
  /**
   * Copies the given object.
   * Only guaranteed to work on anonymous structures.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to copy.
   * @return An independent clone of that object.
   */
  // public static function copy(obj:Any):Null<Any>
  /**
   * Copies the anonymous structure to a new object.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to copy.
   * @return An independent clone of the structure.
   */
  // public static function copyAnonymousFieldsOf(obj:Any):Null<Any>
  /**
   * Delete the field of a given name from an object.
   * Only guaranteed to work on anonymous structures.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to delete the field from.
   * @param name The name of the field to delete.
   * @return Whether the operation was successful.
   */
  // public static function delete(obj:Any, name:String):Bool
  /**
   * Delete the field of a given name from an anonymous structure.
   * Only guaranteed to work on anonymous structures.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to delete the field from.
   * @param name The name of the field to delete.
   * @return Whether the operation was successful.
   */
  // public static function deleteAnonymousField(obj:Any, name:String):Bool
  /**
   * Retrive the value of a given field (by name) from an object.
   * Only guaranteed to work on anonymous structures.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to delete the field from.
   * @param name The name of the field to delete.
   * @return Whether the operation was successful.
   */
  // public static function field(obj:Any, name:String):Any
  /**
   * Retrive the value of a given field (by name) from an object.
   * Only guaranteed to work on anonymous structures.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to delete the field from.
   * @param name The name of the field to delete.
   * @return Whether the operation was successful.
   */
  // public static function getField(obj:Any, name:String):Any

  /**
   * Retrieve the value of the field of the given name from an anonymous structure.
   * @param obj The object to query.
   * @param name The name of the field to retrieve.
   * @return The resulting field value.
   * @throws error If the field is blacklisted.
   */
  @:blacklistOverride
  public static function field(obj:Any, name:String):Any
  {
    if (FIELD_NAME_BLACKLIST.contains(name))
    {
      throw 'Attempted to retrieve blacklisted field "${name}"';
    };

    return Reflect.field(obj, name);
  }

  /**
   * Get a list of fields available on the given object.
   * Only guaranteed to work on anonymous structures.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to query.
   * @return A list of fields on that object.
   */
  // public static function fields(obj:Any):Array<String>
  /**
   * Get a list of fields available on the given object.
   * Only guaranteed to work on anonymous structures.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to query.
   * @return A list of fields on that object.
   */
  // public static function getFieldsOf(obj:Any):Array<String>
  /**
   * Get a list of fields available on the given anonymous structure.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to query.
   * @return A list of fields on that object.
   */
  // public static function getAnonymousFieldsOf(obj:Any):Array<String>

  /**
   * Get the value of the given property on a given object.
   * Unlike `getField()`, this will check if the field is a property with a getter function,
   * and use that if appropriate.
   * @param obj The object to query.
   * @param name The name of the field to query.
   * @return The value of the field.
   * @throws error If the field is blacklisted.
   */
  @:blacklistOverride
  public static function getProperty(obj:Any, name:String):Any
  {
    if (FIELD_NAME_BLACKLIST.contains(name))
    {
      throw 'Attempted to retrieve blacklisted field "${name}"';
    };

    return Reflect.getProperty(obj, name);
  }

  /**
   * Determine whether the given object has the given field.
   * Only guaranteed to work for anonymous structures.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to query.
   * @param name The field name to query.
   * @return Whether the field exists.
   */
  // public static function hasField(obj:Any, name:String):Bool

  /**
   * Determine whether the given anonymous structure has the given field.
   * @param obj The structure to query.
   * @param name The field name to query.
   * @return Whether the field exists.
   */
  @:blacklistOverride
  public static function hasField(obj:Any, name:String):Bool
  {
    if (FIELD_NAME_BLACKLIST.contains(name))
    {
      return false;
    }

    return Reflect.hasField(obj, name);
  }

  /**
   * Determine whether the given input is an enum value.
   *
   * The actual function exists and is generated at build time.
   * @param value The input to evaluate.
   * @return Whether `value` is an enum value.
   */
  // public static function isEnumValue(value:Any):Bool
  /**
   * Determine whether the given input is a callable function.
   *
   * The actual function exists and is generated at build time.
   * @param value The input to evaluate.
   * @return Whether `value` is a function.
   */
  // public static function isFunction(value:Any):Bool
  /**
   * Determine whether the given input is an object.
   *
   * The actual function exists and is generated at build time.
   * @param value The input to evaluate.
   * @return Whether `value` is an object.
   */
  // public static function isObject(value:Any):Bool
  /**
   * Set the value of a specific field on an object.
   * Only guaranteed to work for anonymous structures.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to modify.
   * @param name The field to modify.
   * @param value The new value to apply.
   */
  // public static function setField(obj:Any, name:String, value:Any):Void
  /**
   * Set the value of a specific field on an anonymous structure.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to modify.
   * @param name The field to modify.
   * @param value The new value to apply.
   */
  // public static function setAnonymousField(obj:Any, name:String, value:Any):Void
  /**
   * Set the value of a specific field on an object.
   * Accounts for property fields with getters and setters.
   *
   * The actual function exists and is generated at build time.
   * @param obj The object to modify.
   * @param name The field to modify.
   * @param value The new value to apply.
   */
  // public static function setProperty(obj:Any, name:String, value:Any):Void
  /**
   * This function is not allowed to be used by scripts.
   *
   * The actual function exists and is generated at build time.
   * @throws error When called by a script.
   */
  // public static function createEmptyInstance(cls:Class<Any>):Any
  /**
   * This function is not allowed to be used by scripts.
   *
   * The actual function exists and is generated at build time.
   * @throws error When called by a script.
   */
  // public static function createInstance(cls:Class<Any>, args:Array<Any>):Any
  /**
   * This function is not allowed to be used by scripts.
   * @throws error When called by a script.
   */
  // public static function resolveEnum(name:String):Enum<Any>
  /**
   * This function is not allowed to be used by scripts.
   * @throws error When called by a script.
   */
  // public static function typeof(value:Any):ValueType
  /**
   * Get a list of the static class fields on the given class.
   *
   * The actual function exists and is generated at build time.
   * @param cls The class object to query.
   * @return A list of class field names.
   */
  // public static function getClassFields(cls:Class<Any>):Array<String>

  /**
   * Get a list of the static class fields on the class of the given object.
   * @param obj The object whose class should be queried.
   * @return A list of class field names.
   */
  public static function getClassFieldsOf(obj:Any):Array<String>
  {
    if (obj == null) return [];
    @:nullSafety(Off)
    var cls = Type.getClass(obj);
    if (cls == null) return [];
    return Type.getClassFields(cls);
  }

  /**
   * Get a list of all the fields on instances of the given class.
   *
   * The actual function exists and is generated at build time.
   * @param cls The class object to query.
   * @return A list of object field names.
   */
  // public static function getInstanceFields(cls:Class<Any>):Array<String>

  /**
   * Get a list of all the fields on instances of the class of the given object.
   * @param obj The object whose class should be query.
   * @return A list of object field names.
   */
  public static function getInstanceFieldsOf(obj:Any):Array<String>
  {
    if (obj == null) return [];
    @:nullSafety(Off)
    var cls = Type.getClass(obj);
    if (cls == null) return [];
    return Type.getInstanceFields(cls);
  }

  /**
   * Get the string name of the given class.
   *
   * The actual function exists and is generated at build time.
   * @param cls The class to query.
   * @return The name of the given class.
   */
  // public static function getClassName(cls:Class<Any>):String

  /**
   * Get the string name of the class of the given object.
   * @param obj The object to query.
   * @return The name of the given class, or `Unknown` if the class couldn't be determined.
   */
  public static function getClassNameOf(obj:Any):String
  {
    if (obj == null) return 'Unknown';
    @:nullSafety(Off)
    var cls = Type.getClass(obj);
    if (cls == null) return 'Unknown';
    return Type.getClassName(cls);
  }
}
