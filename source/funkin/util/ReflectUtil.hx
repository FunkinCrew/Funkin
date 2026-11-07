package funkin.util;

import Type.ValueType;
import polymod.hscript._internal.PolymodEnum;
import polymod.hscript._internal.PolymodScriptClass;
import polymod.hscript._internal.PolymodEnum.PolymodEnumValue;
import polymod.hscript._internal.PolymodStaticClassReference;
import polymod.hscript._internal.PolymodAbstractScriptClass;
import polymod.hscript._internal.Expr;

/**
 * Provides sanitized and blacklisted access to Haxe's Reflection and Type functions,
 * extended with support for Polymod scripted classes, static class references,
 * custom script enums, and secure sandbox execution.
 */
@:nullSafety
@SuppressWarnings(['checkstyle:VarTypeHint', 'checkstyle:FieldDocComment'])
@:access(polymod.hscript._internal.PolymodScriptClass)
class ReflectUtil
{
  /**
   * Calls a method value of a specific field on an object.
   * Accounts for property blacklist for security.
   * @param obj The target object.
   * @param func The method name (String) or function reference (Function) to call.
   * @param args Parameters to give to the method.
   * @throws error When trying to call a blacklisted method.
   */
  public static function callMethod(obj:Any, func:Any, args:Array<Any>):Null<Any>
  {
    if (func is String)
    {
      var methodName:String = cast func;

      if (!isAccessAllowed(obj, methodName))
      {
        throw 'Attempted to call blacklisted method "${methodName}"';
      }

      if (isScriptedClass(obj))
      {
        return getScriptedClassRef(obj).callFunction(methodName, args);
      }
      else if (Std.isOfType(obj, PolymodStaticClassReference))
      {
        return cast(obj, PolymodStaticClassReference).callFunction(methodName, args);
      }

      return Reflect.callMethod(getReflectionParent(obj), Reflect.field(getReflectionParent(obj), methodName), args);
    }
    else
    {
      return Reflect.callMethod(obj, func, args);
    }
  }

  /**
   * Compares two objects by value.
   *
   * @param valueA First value to compare
   * @param valueB Second value to compare
   * @return Int indicating relative order of values
   */
  public static function compare(valueA:Any, valueB:Any):Int
  {
    return compareValues(valueA, valueB);
  }

  /**
   * Compares two values and returns an integer indicating their relative order.
   * Returns:
   * - -1 if valueA < valueB
   * - 0 if valueA == valueB
   * - 1 if valueA > valueB
   *
   * @param valueA First value to compare
   * @param valueB Second value to compare
   * @return An integer indicating relative order of values
   */
  public static function compareValues(valueA:Any, valueB:Any):Int
  {
    return Reflect.compare(valueA, valueB);
  }

  /**
   * Compare the two Function objects to determine whether they are the same.
   * @param functionA A method closure to compare.
   * @param functionB A method closure to compare.
   * @return Whether functionA and functionB are equal.
   */
  public static function compareMethods(functionA:Any, functionB:Any):Bool
  {
    return Reflect.compareMethods(functionA, functionB);
  }

  /**
   * Recursively compare two enum instances to determine whether they are equal by value.
   * @param a An enum instance to compare.
   * @param b An enum instance to compare.
   * @return Whether enumA and enumB are equal.
   */
  public static function enumEq(a:Any, b:Any):Bool
  {
    if (a is PolymodEnumValue && b is PolymodEnumValue)
    {
      return PolymodEnum.enumEq(a, b);
    }

    return Type.enumEq(a, b);
  }

  /**
   * Copies the given object.
   * Only guaranteed to work on anonymous structures.
   * @param obj The object to copy.
   * @return An independent clone of that object.
   */
  public static function copy(obj:Any):Null<Any>
  {
    return copyAnonymousFieldsOf(obj);
  }

  /**
   * Copies the anonymous structure to a new object.
   * @param obj The object to copy.
   * @return An independent clone of the structure.
   */
  public static function copyAnonymousFieldsOf(obj:Any):Null<Any>
  {
    return Reflect.copy(obj);
  }

  /**
   * Delete the field of a given name from an object.
   * Only guaranteed to work on anonymous structures.
   * @param obj The object to delete the field from.
   * @param name The name of the field to delete.
   * @return Whether the operation was successful.
   */
  public static function delete(obj:Any, name:String):Bool
  {
    return deleteAnonymousField(obj, name);
  }

  /**
   * Delete the field of a given name from an anonymous structure.
   * Only guaranteed to work on anonymous structures.
   * @param obj The object to delete the field from.
   * @param name The name of the field to delete.
   * @return Whether the operation was successful.
   */
  public static function deleteAnonymousField(obj:Any, name:String):Bool
  {
    if (!isAccessAllowed(obj, name))
    {
      throw 'Attempted to delete blacklisted field "${name}"';
    };
    return Reflect.deleteField(obj, name);
  }

  /**
   * Retrive the value of a given field (by name) from an object.
   * Only guaranteed to work on anonymous structures.
   * @param obj The object to delete the field from.
   * @param name The name of the field to delete.
   * @return Whether the operation was successful.
   */
  public static function field(obj:Any, name:String):Null<Any>
  {
    return getAnonymousField(obj, name);
  }

  /**
   * Retrive the value of a given field (by name) from an object.
   * Only guaranteed to work on anonymous structures.
   * @param obj The object to delete the field from.
   * @param name The name of the field to delete.
   * @return Whether the operation was successful.
   */
  public static function getField(obj:Any, name:String):Null<Any>
  {
    return getAnonymousField(obj, name);
  }

  /**
   * Retrieve the value of the field of the given name from an anonymous structure.
   * @param obj The object to query.
   * @param name The name of the field to retrieve.
   * @return The resulting field value.
   * @throws error If the field is blacklisted.
   */
  public static function getAnonymousField(obj:Any, name:String):Null<Any>
  {
    if (isScriptedClass(obj) || Std.isOfType(obj, PolymodStaticClassReference))
    {
      var field = getScriptedField(obj, name);
      if (field != null) return field;
    }
    else if (obj is PolymodEnum)
    {
      return cast(obj, PolymodEnum).getField(name);
    }

    if (!isAccessAllowed(obj, name))
    {
      throw 'Attempted to retrieve blacklisted field "${name}"';
    };

    return Reflect.field(getReflectionParent(obj), name);
  }

  /**
   * Gets the value of a field on a scripted object or static class reference.
   * overriding the normal fieldRead to bypass getters for variables.
   * @param obj The object or `PolymodStaticClassReference` to query.
   * @param name The name of the field or function to retrieve.
   * @return The field value, function closure, or reflection result, or `null` if unresolvable.
   */
  public static function getScriptedField(obj:Any, name:String):Null<Any>
  {
    if (isScriptedClass(obj))
    {
      if (!isAccessAllowed(obj, name))
      {
        throw 'Attempted to get blacklisted field "${name}" on script class instance "${getClassNameOf(obj)}"';
      };

      var scriptClass = getScriptedClassRef(obj);

      if (scriptClass.findFunction(name) != null)
      {
        return scriptClass._cachedFunctionCalls.get(name);
      }
      else if (scriptClass.findVar(name) != null)
      {
        var v = scriptClass.findVar(name, true);
        if (v == null) return null;

        var varValue:Null<Any> = null;
        if (!scriptClass._interp.variables.exists(name))
        {
          if (v.expr != null)
          {
            varValue = scriptClass._interp.exprWithType(v.expr, v.type);
            scriptClass._interp.variables.set(name, varValue);
          }
        }
        else
        {
          varValue = scriptClass._interp.variables.get(name);
        }

        return varValue;
      }
      else if (Std.isOfType(scriptClass.superClass, PolymodScriptClass))
      {
        return getScriptedField(scriptClass.superClass, name);
      }
    }
    else if (Std.isOfType(obj, PolymodStaticClassReference))
    {
      return getScriptClassStaticField(cast obj, name);
    }

    return null;
  }

  /**
   * Gets the value of a static field on a scripted class reference.
   * overriding the normal getField to bypass getters for variables.
   * @param cls The target `PolymodStaticClassReference` representing the scripted class.
   * @param name The name of the static field to retrieve.
   * @return The static field value or function reference, or `null` if unresolvable.
   */
  public static function getScriptClassStaticField(cls:PolymodStaticClassReference, name:String):Null<Dynamic>
  {
    if (!isAccessAllowed(cls, name))
    {
      throw 'Attempted to retrieve blacklisted static field "${name}" on script class "${getClassNameOf(cls)}"';
    }

    var clsName = getClassName(cls);
    var prefixedName = '$clsName#$name';
    var interp = PolymodScriptClass.scriptInterp;
    var fieldDecl = interp.getScriptClassStaticFieldDecl(clsName, name);

    if (fieldDecl != null)
    {
      if (!interp.variables.exists(prefixedName))
      {
        switch (fieldDecl.kind)
        {
          case KFunction(_):
            @:privateAccess
            var result = interp.buildScriptClassStaticFunction(clsName, name);
            interp.variables.set(prefixedName, result);
            return result;
          case KVar(v):
            if (v.expr != null)
            {
              var result = interp.exprWithType(v.expr, v.type);
              interp.variables.set(prefixedName, result);
              return result;
            }
            else
            {
              return null;
            }
          default:
            return null;
        }
      }
      else
      {
        return interp.variables.get(prefixedName);
      }
    }
    else
    {
      return null;
    }
  }

  /**
   * Get a list of fields available on the given object.
   * Only guaranteed to work on anonymous structures.
   * @param obj The object to query.
   * @return A list of fields on that object.
   */
  public static function fields(obj:Any):Array<String>
  {
    return getAnonymousFieldsOf(obj);
  }

  /**
   * Get a list of fields available on the given object.
   * Only guaranteed to work on anonymous structures.
   * @param obj The object to query.
   * @return A list of fields on that object.
   */
  public static function getFieldsOf(obj:Any):Array<String>
  {
    return getAnonymousFieldsOf(obj);
  }

  /**
   * Get a list of fields available on the given anonymous structure.
   * @param obj The object to query.
   * @return A list of fields on that object.
   */
  public static function getAnonymousFieldsOf(obj:Any):Array<String>
  {
    if (obj is PolymodEnum)
    {
      return getEnumConstructs(obj);
    }
    else if (obj is PolymodStaticClassReference)
    {
      return getClassFields(obj);
    }

    var result = getScriptedFieldsOf(obj);

    return result.concat(Reflect.fields(obj));
  }

  @:unreflective
  static var _scriptFieldsCache:Map<String, Array<String>> = new Map();

  /**
   * Get a list of fields available on the given scripted object.
   * @param obj The scripted object instance to query.
   * @return A list of fields on that scripted object.
   */
  public static function getScriptedFieldsOf(obj:Any):Array<String>
  {
    var result:Array<String> = [];
    if (obj == null) return result;
    if (!isScriptedClass(obj)) return result;
    if (!isAccessAllowed(obj)) return result;

    var clsName:String = getClassNameOf(obj);
    if (_scriptFieldsCache.exists(clsName)) return _scriptFieldsCache.get(clsName) ?? [];

    var scriptClass = getScriptedClassRef(obj);

    for (name => field in scriptClass._cachedFieldDecls)
    {
      if (scriptClass._cachedFunctionDecls.exists(name)) continue;
      if (!isAccessAllowed(obj, name)) continue;
      if (result.contains(name)) continue;
      result.push(name);
    }

    if (Std.isOfType(scriptClass.superClass, PolymodScriptClass))
    {
      return result.concat(getScriptedFieldsOf(scriptClass.superClass));
    }

    _scriptFieldsCache.set(clsName, result);
    return result;
  }

  /**
   * Get the value of the given property on a given object.
   * Unlike `getField()`, this will check if the field is a property with a getter function,
   * and use that if appropriate.
   * @param obj The object to query.
   * @param name The name of the field to query.
   * @return The value of the field.
   * @throws error If the field is blacklisted.
   */
  public static function getProperty(obj:Any, name:String):Any
  {
    if (!isAccessAllowed(obj, name))
    {
      throw 'Attempted to retrieve blacklisted field "${name}"';
    };

    if (isScriptedClass(obj))
    {
      return getScriptedClassRef(obj).fieldRead(name);
    }
    else if (Std.isOfType(obj, PolymodStaticClassReference))
    {
      return cast(obj, PolymodStaticClassReference).getField(name);
    }
    else if (obj is PolymodEnum)
    {
      return cast(obj, PolymodEnum).getField(name);
    }

    return Reflect.getProperty(getReflectionParent(obj), name);
  }

  /**
   * Determine whether the given object has the given field.
   * Only guaranteed to work for anonymous structures.
   * @param obj The object to query.
   * @param name The field name to query.
   * @return Whether the field exists.
   */
  public static function hasField(obj:Any, name:String):Bool
  {
    return hasAnonymousField(obj, name);
  }

  /**
   * Determine whether the given anonymous structure has the given field.
   * @param obj The structure to query.
   * @param name The field name to query.
   * @return Whether the field exists and isnt blacklisted.
   */
  public static function hasAnonymousField(obj:Any, name:String):Bool
  {
    if (!isAccessAllowed(obj, name))
    {
      return false;
    }

    if (isScriptedClass(obj))
    {
      return getScriptedClassRef(obj).fieldExists(name);
    }
    else if (Std.isOfType(obj, PolymodStaticClassReference))
    {
      return PolymodScriptClass.hasScriptClassStaticField(getClassName(obj), name);
    }
    else if (Std.isOfType(obj, PolymodEnum))
    {
      return cast(obj, PolymodEnum).hasField(name);
    }

    if (getInstanceFieldsOf(obj).contains(name) || getClassFields(obj).contains(name))
    {
      return true;
    }

    return Reflect.hasField(obj, name);
  }

  /**
   * Determine whether the given input is an enum value.
   * @param value The input to evaluate.
   * @return Whether `value` is an enum value.
   */
  public static function isEnumValue(value:Any):Bool
  {
    if (value is PolymodEnumValue) return true;
    return Reflect.isEnumValue(value);
  }

  /**
   * Determine whether the given input is a callable function.
   * @param value The input to evaluate.
   * @return Whether `value` is a function.
   */
  public static function isFunction(value:Any):Bool
  {
    return Reflect.isFunction(value);
  }

  /**
   * Determine whether the given input is an object.
   * @param value The input to evaluate.
   * @return Whether `value` is an object.
   */
  public static function isObject(value:Any):Bool
  {
    return Reflect.isObject(value);
  }

  /**
   * Set the value of a specific field on an object.
   * Only guaranteed to work for anonymous structures.
   * @param obj The object to modify.
   * @param name The field to modify.
   * @param value The new value to apply.
   */
  public static function setField(obj:Any, name:String, value:Any):Void
  {
    return setAnonymousField(obj, name, value);
  }

  /**
   * Set the value of a specific field on an anonymous structure.
   * @param obj The object to modify.
   * @param name The field to modify.
   * @param value The new value to apply.
   * @throws error When trying to set a blacklisted field.
   */
  public static function setAnonymousField(obj:Any, name:String, value:Any):Void
  {
    if (!isAccessAllowed(obj, name))
    {
      throw 'Attempted to set blacklisted field "${name}"';
    };

    if (isScriptedClass(obj))
    {
      var field = setScriptedField(obj, name, value);
      if (field != null) return;
    }
    else if (Std.isOfType(obj, PolymodStaticClassReference))
    {
      var field = setScriptClassStaticField(cast obj, name, value);
      if (field != null) return;
    }

    return Reflect.setField(getReflectionParent(obj), name, value);
  }

  /**
   * Sets the value of a field on a scripted object instance.
   * overriding the normal fieldWrite to bypass setters for variables.
   * @param obj The scripted object instance or reference to modify.
   * @param name The name of the field to update.
   * @param value The value to assign to the field.
   * @return The assigned value if successful, or `null` if the field was not found.
   */
  public static function setScriptedField(obj:Any, name:String, value:Any):Null<Any>
  {
    if (isScriptedClass(obj))
    {
      if (!isAccessAllowed(obj, name))
      {
        throw 'Attempted to set blacklisted field "${name}" on script class instance "${getClassNameOf(obj)}"';
      };

      var scriptClass = getScriptedClassRef(obj);

      if (scriptClass.findVar(name) != null)
      {
        scriptClass._interp.variables.set(name, value);
        return value;
      }
      else if (scriptClass.findFunction(name) != null)
      {
        var fnDecl = scriptClass.findFunction(name, true);

        if ((fnDecl?.isdynamic ?? false) && isFunction(value))
        {
          scriptClass._interp.functions.set(name, value);
          return value;
        }
      }
      else if (Std.isOfType(scriptClass.superClass, PolymodScriptClass))
      {
        return setScriptedField(scriptClass.superClass, name, value);
      }
    }
    return null;
  }

  /**
   * Sets the value of a static field on a scripted class reference.
   * overriding the normal setField to bypass setters for variables.
   * @param cls The target `PolymodStaticClassReference` representing the scripted class.
   * @param name The name of the static field to set.
   * @param value The value to assign to the static field.
   * @return The assigned value if successful. otherwise `null` if the field is immutable, a function, or unresolvable.
   */
  public static function setScriptClassStaticField(cls:PolymodStaticClassReference, name:String, value:Any):Null<Any>
  {
    var prefixedName = getClassName(cls) + '#' + name;
    var interp = PolymodScriptClass.scriptInterp;
    var fieldDecl = interp.getScriptClassStaticFieldDecl(getClassName(cls), name);

    if (fieldDecl != null)
    {
      switch (fieldDecl.kind)
      {
        case KFunction(f):
          if (f.isdynamic && isFunction(value))
          {
            interp.functions.set(prefixedName, value);
            return value;
          }
          else
          {
            return null;
          }
        case KVar(v):
          interp.variables.set(prefixedName, value);
          return value;
        default:
          return null;
      }
    }
    return null;
  }

  /**
   * Set the value of a specific field on an object.
   * Accounts for property fields with getters and setters.
   * @param obj The object to modify.
   * @param name The field to modify.
   * @param value The new value to apply.
   * @throws error When trying to set a blacklisted field.
   */
  public static function setProperty(obj:Any, name:String, value:Any):Void
  {
    if (!isAccessAllowed(obj, name))
    {
      throw 'Attempted to set blacklisted field "${name}"';
    };

    if (isScriptedClass(obj))
    {
      getScriptedClassRef(obj).fieldWrite(name, value);
      return;
    }
    else if (Std.isOfType(obj, PolymodStaticClassReference))
    {
      cast(obj, PolymodStaticClassReference).setField(name, value);
      return;
    }

    return Reflect.setProperty(getReflectionParent(obj), name, value);
  }

  /**
   * Creats a instance of specified class
   * Accounts for property blacklist for security.
   * @param cls The class to create.
   * @param args Parameters to give to the constructor
   * @throws error When trying to create a blacklisted class.
   */
  public static function createInstance(cls:Any, args:Array<Any>):Null<Any>
  {
    if (Std.isOfType(cls, PolymodStaticClassReference))
    {
      if (!isAccessAllowed(cls))
      {
        throw 'Attempted to call createInstance onto a blacklisted script class "${getClassName(cls)}"';
      }

      var instance = cast(cls, PolymodStaticClassReference).instantiate(args);

      if (!isAccessAllowed(instance, "new"))
      {
        throw 'Attempted to call createInstance onto a blacklisted constructor for script class "${getClassName(cls)}"';
      }

      return instance;
    }

    if (!isAccessAllowed(cls))
    {
      throw 'Attempted to call createInstance onto a blacklisted class "${getClassNameOf(cls)}"';
    }

    return Type.createInstance(getReflectionParent(cls), args);
  }

  /**
   * Creats a empty instance of specified class
   * Accounts for property blacklist for security.
   * @param cls The class to create.
   * @throws error When trying to create a blacklisted class.
   */
  public static function createEmptyInstance(cls:Class<Any>):Any
  {
    if (!isAccessAllowed(cls))
    {
      throw 'Attempted to call createInstance onto a blacklisted class "${getClassNameOf(cls)}"';
    }

    return Type.createEmptyInstance(getReflectionParent(cls));
  }

  /**
   * Creates an instance of an enum by its constructor name and optional parameters.
   * @param enm The target enum type.
   * @param constr The string constructor name to instantiate.
   * @param params Optional arguments to pass to the enum constructor.
   * @return The created enum instance, or null if e or constr is null.
   * @throws error If the enum type is blacklisted.
   */
  public static function createEnum(enm:Any, constr:String, ?params:Array<Any>):Null<Any>
  {
    if (enm == null || constr == null) return null;

    if (enm is PolymodEnum)
    {
      var value = cast(enm, PolymodEnum).getField(constr);
      if (isFunction(value))
      {
        return Reflect.callMethod(enm, value, params ?? []);
      }

      return value;
    }

    return Type.createEnum(enm, constr, params);
  }

  /**
   * Creates an instance of an enum by its constructor index and optional parameters.
   * @param enm The target enum type.
   * @param index The zero-based index of the constructor to instantiate.
   * @param params Optional arguments to pass to the enum constructor.
   * @return The created enum instance, or null if `enm` is null.
   */
  public static function createEnumIndex(enm:Any, index:Int, ?params:Array<Any>):Null<Any>
  {
    if (enm == null) return null;

    if (enm is PolymodEnum)
    {
      @:privateAccess
      var field = cast(enm, PolymodEnum)._e.fields[index];

      if (field != null)
      {
        return createEnum(enm, field.name, params);
      }
    }

    return Type.createEnumIndex(enm, index, params);
  }

  /**
   * Resolves a class or scripted class reference by name, respecting import overrides and security access rules.
   * Checks native classes first before attempting script class resolution, verifying that the result is allowed.
   *
   * @param name The fully qualified name or path of the target class to resolve.
   * @return The resolved `Class<Dynamic>` or `PolymodStaticClassReference`, or `null` if resolution fails or returns an invalid type.
   * @throws error If the resolved target class is blacklisted or forbidden by access rules.
   */
  public static function resolveClass(name:String):Null<Any>
  {
    var resolved = getReflectionParent(getClassOrEnumFromName(name));
    if (resolved == null) return resolveScriptClass(name);
    if (!Std.isOfType(resolved, Class)) return null;
    if (!isAccessAllowed(resolved))
    {
      throw 'Attempted to resolve a blacklisted class "${getClassName(getClassOrEnumFromName(name))}"';
    }
    return resolved;
  }

  @:unreflective
  static var _scriptClassCache:Map<String, PolymodStaticClassReference> = new Map();

  /**
   * Attempts to resolve a script class reference by name and return its static wrapper.
   * Validates that the built result is non-null and strictly of type `PolymodStaticClassReference`.
   *
   * @param name The fully qualified name or path of the target script class.
   * @return The built `PolymodStaticClassReference` if resolution succeeds, or `null` if invalid.
   */
  public static function resolveScriptClass(name:String):Null<PolymodStaticClassReference>
  {
    if (_scriptClassCache.exists(name)) return _scriptClassCache.get(name);
    var resolved = PolymodStaticClassReference.tryBuild(name);
    if (resolved == null) return null;
    if (!Std.isOfType(resolved, PolymodStaticClassReference)) return null;
    if (!isAccessAllowed(resolved))
    {
      throw 'Attempted to resolve a blacklisted script class "${getClassName(resolved)}"';
    }
    _scriptClassCache.set(name, resolved);
    return _scriptClassCache.get(name);
  }

  /**
   * Resolves an enum type reference by name, respecting security access rules and type safety.
   * Checks runtime enums first before verifying that the resolved target is permitted.
   *
   * @param name The fully qualified name or path of the target enum to resolve.
   * @return The resolved `Enum<Any>`, or `null` if resolution fails or the resolved target is not an enum.
   * @throws error If the resolved target enum is blacklisted or forbidden by access rules.
   */
  public static function resolveEnum(name:String):Null<Any>
  {
    var resolved = getReflectionParent(getClassOrEnumFromName(name));
    if (resolved == null) return PolymodEnum.tryBuild(name);
    if (!Std.isOfType(resolved, Enum)) return null;
    if (!isAccessAllowed(resolved))
    {
      throw 'Attempted to resolve a blacklisted enum "${getClassNameOf(getClassOrEnumFromName(name))}"';
    }
    return resolved;
  }

  /**
   * Gets the Type of a given value safely within the script environment.
   * Prevents scripts from inspecting blacklisted native classes and handles script class references.
   *
   * @param value The value to inspect.
   * @return The ScriptValueType representation of the target value.
   */
  public static function typeof(value:Any):ScriptValueType
  {
    if (value == null) return TNull;

    if (isScriptedClass(value))
    {
      var cls = getClass(value);
      if (cls != null) return TScriptClass(cls);

      return TUnknown;
    }
    else if (value is PolymodEnumValue)
    {
      var enm = getEnum(value);

      if (enm != null) return TScriptEnum(enm);

      return TUnknown;
    }
    else if (value is PolymodStaticClassReference || value is PolymodEnum)
    {
      if (!isAccessAllowed(value)) return TUnknown;
      return TObject;
    }

    var result = Type.typeof(value);
    return switch (result)
    {
      case TNull:
        TNull;
      case TInt:
        TInt;
      case TFloat:
        TFloat;
      case TBool:
        TBool;
      case TObject:
        TObject;
      case TFunction:
        TFunction;
      case TEnum(e):
        TEnum(e);
      case TClass(c):
        var cls = getReflectionParent(c);
        if (!isAccessAllowed(cls)) TUnknown;

        if (Std.isOfType(cls, Class)) TClass(cast cls); else TUnknown;
      default:
        TUnknown;
    };
  }

  @:unreflective
  static var _staticFieldsCache:Map<String, Array<String>> = new Map();
  @:unreflective
  static var _scriptStaticFieldsCache:Map<String, Array<String>> = new Map();

  /**
   * Get a list of the static class fields on the given class.
   * @param cls The class object to query.
   * @return A list of class field names.
   */
  public static function getClassFields(cls:Any):Array<String>
  {
    if (Std.isOfType(cls, PolymodStaticClassReference))
    {
      if (!isAccessAllowed(cls)) return [];

      var sClsName = getClassName(cls);
      if (_scriptStaticFieldsCache.exists(sClsName)) return _scriptStaticFieldsCache.get(sClsName) ?? [];

      var result:Array<String> = [];
      var staticRef:PolymodStaticClassReference = cast cls;
      for (field in staticRef.cls?.staticFields ?? [])
      {
        if (!isAccessAllowed(staticRef, field.name)) continue;
        if (!result.contains(field.name)) result.push(field.name);
      }
      _scriptStaticFieldsCache.set(sClsName, result);
      return result;
    }

    if (!Std.isOfType(cls, Class)) return [];

    var clsName = Type.getClassName(cls);

    if (!_staticFieldsCache.exists(clsName))
    {
      _staticFieldsCache.set(clsName, Type.getClassFields(cls));
    }

    return _staticFieldsCache.get(clsName) ?? [];
  }

  /**
   * Get a list of the static class fields on the class of the given object.
   * @param obj The object whose class should be queried.
   * @return A list of class field names.
   */
  public static function getClassFieldsOf(obj:Any):Array<String>
  {
    if (obj == null) return [];
    var cls = getClass(obj);
    if (cls == null) return [];
    return getClassFields(cls);
  }

  @:unreflective
  static var _instanceFieldsCache:Map<String, Array<String>> = new Map();

  /**
   * Get a list of all the fields on instances of the given class.
   * @param cls The class object to query.
   * @return A list of object field names.
   */
  public static function getInstanceFields(cls:Any):Array<String>
  {
    if (cls == null) return [];

    if (Std.isOfType(cls, PolymodStaticClassReference))
    {
      return getScriptedInstanceFields(cast cls);
    }

    if (!Std.isOfType(cls, Class)) return [];

    var clsName = Type.getClassName(cls);

    if (!_instanceFieldsCache.exists(clsName))
    {
      _instanceFieldsCache.set(clsName, Type.getInstanceFields(cls));
    }

    return _instanceFieldsCache.get(clsName) ?? [];
  }

  @:unreflective
  static var _scriptInstanceFieldsCache:Map<String, Array<String>> = new Map();

  /**
   * Retrieves all instance field names for a scripted class reference, including inherited parent fields.
   *
   * @param staticRef The target scripted class reference.
   * @return An array of instance field names.
   */
  public static function getScriptedInstanceFields(staticRef:PolymodStaticClassReference):Array<String>
  {
    if (!isAccessAllowed(staticRef)) return [];
    if (staticRef.cls == null) return [];

    var clsName = getClassName(staticRef);
    if (_scriptInstanceFieldsCache.exists(clsName))
    {
      return _scriptInstanceFieldsCache.get(clsName) ?? [];
    }

    var blacklistedFields = PolymodScriptClass.blacklistedScriptClassInstanceFields.get(clsName) ?? [];

    var result:Array<String> = [];
    var descriptors:Null<ClassDecl> = staticRef.cls;

    if (descriptors != null)
    {
      for (f in descriptors.fields)
      {
        if (!result.contains(f.name))
        {
          if (blacklistedFields.contains(f.name)) continue;
          result.push(f.name);
        }
      }

      var parentTarget = getScriptSuperClass(staticRef);
      if (parentTarget != null)
      {
        var parentFields:Array<String> = [];

        if (Std.isOfType(parentTarget, PolymodStaticClassReference))
        {
          parentFields = getScriptedInstanceFields(cast parentTarget);
        }
        else if (parentTarget is Class)
        {
          parentFields = getInstanceFields(parentTarget);
        }

        for (p in parentFields)
        {
          if (!result.contains(p)) result.push(p);
        }
      }
    }

    _scriptInstanceFieldsCache.set(clsName, result);
    return result;
  }

  @:unreflective
  static var _enumConstructsCache:Map<String, Array<String>> = new Map();
  @:unreflective
  static var _scriptEnumConstructsCache:Map<String, Array<String>> = new Map();

  /**
   * Returns a list of the names of all constructors of enum `enm`.
   * The order of the constructor names in the returned Array is preserved
   * from the original syntax.
   * @param enm The enum type to inspect.
   * @return A list of enum constructor names in declaration order.
   */
  public static function getEnumConstructs(enm:Any):Array<String>
  {
    if (enm == null) return [];
    var result:Array<String> = [];

    if (enm is PolymodEnum)
    {
      var sEnumName:String = getEnumName(enm);
      if (_scriptEnumConstructsCache.exists(sEnumName))
      {
        return _scriptEnumConstructsCache.get(sEnumName) ?? [];
      }

      @:privateAccess
      for (fld in cast(enm, PolymodEnum)._e.fields)
      {
        result.push(fld.name);
      }

      _scriptEnumConstructsCache.set(sEnumName, result);
      return result;
    }

    if (!Std.isOfType(enm, Enum)) return [];

    var enumName:String = Type.getEnumName(enm);
    if (_enumConstructsCache.exists(enumName))
    {
      return _enumConstructsCache.get(enumName) ?? [];
    }

    result = Type.getEnumConstructs(enm);
    _enumConstructsCache.set(enumName, result);
    return result;
  }

  /**
   * Get a list of all the fields on instances of the class of the given object.
   * @param obj The object whose class should be query.
   * @return A list of object field names.
   */
  public static function getInstanceFieldsOf(obj:Any):Array<String>
  {
    if (obj == null) return [];
    var cls = getClass(obj);
    if (cls == null) return [];
    return getInstanceFields(cls);
  }

  /**
   * Get a list of all constructor names for the enum type of the given enum value.
   * @param value The enum value whose enum type should be queried.
   * @return A list of enum constructor names in declaration order.
   */
  public static function getEnumConstructsOf(value:Any):Array<String>
  {
    if (value == null) return [];
    var enm = getEnum(value);
    if (enm == null) return [];
    return getEnumConstructs(enm);
  }

  /**
   * Get the fully qualified string name of the given class or scripted class reference.
   *
   * @param cls The class reference or scripted static class target to query.
   * @return The fully qualified name of the class, or `"Unknown"` if the class is null or invalid.
   */
  public static function getClassName(cls:Null<Any>):String
  {
    if (cls == null) return "Unknown";
    if (Std.isOfType(cls, PolymodStaticClassReference))
    {
      return cast(cls, PolymodStaticClassReference).getFullyQualifiedName();
    }
    if (!Std.isOfType(cls, Class)) return "Unknown";
    return Type.getClassName(cls);
  }

  /**
   * Get the string name of the given enum.
   * @param enm The enum to query.
   * @return The name of the given enum. or `"Unknown"` if the enum is null or invalid.
   */
  public static function getEnumName(enm:Any):String
  {
    if (enm == null) return "Unknown";
    if (Std.isOfType(enm, PolymodEnum)) return cast(enm, PolymodEnum).getFullName();
    if (!Std.isOfType(enm, Enum)) return "Unknown";
    return Type.getEnumName(enm);
  }

  /**
   * Get the string name of the class of the given object.
   * @param obj The object to query.
   * @return The name of the given class, or `Unknown` if the class couldn't be determined.
   */
  public static function getClassNameOf(obj:Null<Any>):String
  {
    if (obj == null) return 'Unknown';
    if (obj is PolymodStaticClassReference || obj is Class) return getClassName(obj);
    if (obj is String && resolveClass(obj) != null) return obj;
    if (isScriptedClass(obj)) return getScriptedClassRef(obj).fullyQualifiedName;
    var cls = Type.getClass(obj);
    if (cls == null) return 'Unknown';
    return Type.getClassName(cls);
  }

  /**
   * Get the string name of the enum of the given enum value.
   * @param value The enum value to query.
   * @return The name of the given enum, or `Unknown` if the enum couldn't be determined.
   */
  public static function getEnumNameOf(value:Any):String
  {
    if (value == null) return 'Unknown';
    if (value is String && resolveEnum(cast value) != null) return cast value;
    if (value is PolymodEnumValue) return cast(value, PolymodEnumValue).parentEnum.getFullName();
    var enm = Type.getEnum(value);
    if (enm == null) return 'Unknown';
    return Type.getEnumName(enm);
  }

  /**
   * Resolves the runtime type representation corresponding to the provided instance.
   * Handles both native native Haxe `Class` types and scripted `PolymodStaticClassReference` targets.
   *
   * @param obj The target object instance to inspect.
   * @return The resolved `Class<Dynamic>` or `PolymodStaticClassReference`, or `null` if the input is null or unresolved.
   */
  public static function getClass(obj:Any):Null<Any>
  {
    if (obj == null) return null;

    return resolveClass(getClassNameOf(obj));
  }

  /**
   * Resolves the enum type corresponding to the provided enum value.
   *
   * @param value The enum value instance to inspect.
   * @return The resolved `Enum<Any>`, or `null` if the input is null or unresolved.
   */
  public static function getEnum(value:Any):Null<Any>
  {
    if (value == null) return null;

    return resolveEnum(getEnumNameOf(value));
  }

  static var _superClassCache:Map<String, Null<Class<Any>>> = new Map();

  /**
   * Resolves the super class of a given class or scripted class reference, respecting security access rules.
   * Handles both native Haxe `Class` types and scripted `PolymodStaticClassReference` targets.
   *
   * @param cls The target class reference or scripted static reference to inspect.
   * @return The resolved super class as `Class<Dynamic>` or `PolymodStaticClassReference`, or `null` if no parent class exists.
   * @throws error If the resolved super class is blacklisted.
   */
  public static function getSuperClass(cls:Any):Null<Any>
  {
    if (Std.isOfType(cls, PolymodStaticClassReference))
    {
      return getScriptSuperClass(cast cls);
    }

    if (!Std.isOfType(cls, Class)) return null;

    var clsName = getClassName(cls);
    if (_superClassCache.exists(clsName))
    {
      return _superClassCache.get(clsName);
    }

    var superCls = getReflectionParent(Type.getSuperClass(cls));

    if (!isAccessAllowed(superCls))
    {
      throw 'Attempted to resolve a blacklisted super class "${getClassName(superCls)}"';
    }

    _superClassCache.set(clsName, superCls);
    return superCls;
  }

  @:unreflective
  static var _scriptSuperClassCache:Map<String, Null<Any>> = new Map();

  /**
   * Resolves the super class target (either a scripted class reference or a native `Class<Any>`) for a given scripted class.
   *
   * @param staticRef The target scripted class reference to inspect.
   * @return The resolved `PolymodStaticClassReference` or native `Class<Any>`, or `null` if no super class exists/resolves.
   */
  public static function getScriptSuperClass(staticRef:PolymodStaticClassReference):Null<Any>
  {
    if (staticRef == null) return null;

    if (!isAccessAllowed(staticRef))
    {
      throw 'Attempted to get super class of a blacklisted script class "${getClassName(staticRef)}"';
    }

    var clsName = getClassName(staticRef);

    var superCls:Null<Any> = null;

    if (_scriptSuperClassCache.exists(clsName))
    {
      superCls = _scriptSuperClassCache.get(clsName);
      if (!isAccessAllowed(superCls))
      {
        throw 'Attempted to resolve a blacklisted script super class "${getClassName(superCls)}"';
      }
      return superCls;
    }

    var descriptors = staticRef.cls;
    if (descriptors != null && descriptors.extend != null)
    {
      var fullExtendString = new polymod.hscript._internal.Printer().typeToString(descriptors.extend);

      if (fullExtendString.indexOf('<') != -1) fullExtendString = fullExtendString.split('<')[0];

      var superRef = resolveClass(fullExtendString);

      if (superRef != null)
      {
        superCls = superRef;
      }
    }

    _scriptSuperClassCache.set(clsName, superCls);

    if (!isAccessAllowed(superCls))
    {
      throw 'Attempted to resolve a blacklisted script super class "${getClassName(superCls)}"';
    }

    return superCls;
  }

  /**
   * Resolves the super class of the class of the given object instance.
   * Handles instances of both native Haxe classes and scripted types.
   *
   * @param obj The target object instance to inspect.
   * @return The resolved super class as `Class<Dynamic>` or `PolymodStaticClassReference`, or `null` if the object is null or has no parent class.
   */
  public static function getSuperClassOf(obj:Any):Null<Any>
  {
    if (obj == null) return null;
    var cls = getClass(obj);
    if (cls == null) return null;
    return getSuperClass(cls);
  }

  /**
   * Returns the constructor name of the given enum value.
   * @param value The enum value to query.
   * @return The string constructor name of the enum value, or `Unknown` if value is null.
   */
  public static function enumConstructor(value:Any):String
  {
    if (value == null) return "Unknown";
    if (value is PolymodEnumValue) return cast(value, PolymodEnumValue).value;
    return Type.enumConstructor(value);
  }

  /**
   * Returns a list of the constructor arguments of the given enum value.
   * @param value The enum value to query.
   * @return An array containing the allowed arguments of the enum value, or an empty array if value has no arguments or is null.
   */
  public static function enumParameters(value:Any):Array<Any>
  {
    if (value == null) return [];

    var result:Array<Any> = [];

    if (value is PolymodEnumValue)
    {
      return cast(value, PolymodEnumValue).args;
    }

    var rawParams = Type.enumParameters(value);

    for (p in rawParams)
    {
      var safeParam = getReflectionParent(p);
      if (!isAccessAllowed(safeParam)) continue;
      if (safeParam != null) result.push(safeParam);
    }

    return result;
  }

  /**
   * Returns the index of the given enum value.
   * @param value The enum value to query.
   * @return The integer index of the enum value, or -1 if not found or null.
   */
  public static function enumIndex(value:Any):Int
  {
    if (!isEnumValue(value)) return -1;

    if (value is PolymodEnumValue)
    {
      var enmValue = cast(value, PolymodEnumValue);

      @:privateAccess
      var fields = enmValue.parentEnum._e.fields;

      for (i in 0...fields.length)
      {
        if (fields[i].name == enmValue.value) return i;
      }

      return -1;
    }

    return Type.enumIndex(value);
  }

  /**
   * Transform a function taking an array of arguments into a function that can
   * be called with any number of arguments.
   *
   * @param f A function which takes an array of arguments.
   * @return A new function that takes any number of arguments and passes them as an array to `f`.
   */
  public static function makeVarArgs(f:Array<Dynamic>->Dynamic):Dynamic
  {
    return Reflect.makeVarArgs(f);
  }

  /**
   * Retrieves the underlying `PolymodAbstractScriptClass` reference from a given object instance.
   * Handles both direct scripted class instances and native instances with an injected `_asc` reference.
   *
   * @param obj The target object instance to inspect (can be a `PolymodScriptClass` or a native instance wrapping a script).
   * @return The associated `PolymodAbstractScriptClass` instance.
   * @throws error If the provided object is not a valid scripted class instance or lacks an `_asc` reference.
   */
  @:unreflective
  static function getScriptedClassRef(obj:Dynamic):PolymodAbstractScriptClass
  {
    if (Std.isOfType(obj, PolymodScriptClass))
    {
      return cast(obj, PolymodScriptClass);
    }
    else if (obj._asc != null)
    {
      return obj._asc;
    }

    throw "Object is not a valid scripted class instance";
  }

  /**
   * Checks whether the provided object is a valid scripted class instance or a native object bound to a script.
   * Safely verifies type inheritance and runtime `_asc` property existence without throwing errors.
   *
   * @param obj The target object instance to check.
   * @return `true` if the object is a direct `PolymodScriptClass` or has an active `_asc` script reference. otherwise `false`.
   */
  static function isScriptedClass(obj:Dynamic):Bool
  {
    if (obj == null) return false;
    return Std.isOfType(obj, PolymodScriptClass) || obj._asc != null;
  }

  /**
   * Clears all cached reflection data associated with scripted classes and fields.
   *
   * Should be called when reloading scripts to ensure stale class definitions,
   * field signatures, and static members are purged from memory.
   */
  public static function clearScriptCache():Void
  {
    _scriptClassCache.clear();
    _scriptSuperClassCache.clear();
    _scriptFieldsCache.clear();
    _scriptStaticFieldsCache.clear();
    _scriptInstanceFieldsCache.clear();
    _scriptEnumConstructsCache.clear();
    blacklistedScriptFieldsCache.clear();
  }

  @:unreflective
  static var pathResolveCache:Map<String, Any> = new Map();
  @:unreflective
  static var blacklistedFieldsCache:Map<String, Any> = new Map();
  @:unreflective
  static var blacklistedScriptFieldsCache:Map<String, Any> = new Map();

  /**
   * Resolves a fully qualified path string into a Haxe `Class` or `Enum` type, caching the lookup for performance.
   * Attempts `Type.resolveClass` first before falling back to `Type.resolveEnum`.
   *
   * @param path The fully qualified dot-path string of the target type (e.g., "flixel.FlxSprite").
   * @return The resolved `Class<Dynamic>` or `Enum<Dynamic>` type reference, or `null` if resolution fails.
   */
  @:unreflective
  static function getClassOrEnumFromName(path:String):Dynamic
  {
    if (pathResolveCache.exists(path)) return pathResolveCache.get(path);
    var resultCls:Class<Dynamic> = Type.resolveClass(path);
    if (resultCls != null)
    {
      pathResolveCache.set(path, resultCls);
      return resultCls;
    }
    else
    {
      var resultEnm:Enum<Dynamic> = Type.resolveEnum(path);
      if (resultEnm != null) pathResolveCache.set(path, resultEnm);
      return resultEnm;
    }
  }

  /**
   * Resolves the canonical reflection target or override mapping for a given object instance or type identifier.
   * Intercepts import overrides mapped in `PolymodScriptClass.importOverrides` to preserve structural integrity.
   *
   * @param obj The target object, string identifier, or type reference to resolve.
   * @return The substituted override target if registered, or the original object reference.
   */
  @:unreflective
  static function getReflectionParent(obj:Dynamic):Dynamic
  {
    var clsName:Null<String> = getClassNameOf(obj);
    if (clsName == 'Unknown') clsName = null;
    var objName = obj is String ? obj : (clsName ?? obj);
    return PolymodScriptClass.importOverrides.exists(objName) ? PolymodScriptClass.importOverrides.get(objName) : obj;
  }

  /**
   * Evaluates security permissions and blacklist status for reflective access to a target object or field.
   *
   * @param obj The target object or type reference to inspect.
   * @param varName Optional name of the specific member variable or field to check against blacklists.
   * @return `true` if reflective access to the object and field is permitted; otherwise `false`.
   */
  @:unreflective
  static function isAccessAllowed(obj:Dynamic, ?varName:String):Bool
  {
    var reflectedObj = getReflectionParent(obj);

    var isScript = isScriptedClass(reflectedObj);
    var isScriptStaticRef = Std.isOfType(reflectedObj, PolymodStaticClassReference);

    var isClassReflect = !isScript && !isScriptStaticRef && Std.isOfType(reflectedObj, Class);

    var key:String;
    if (isClassReflect || isScriptStaticRef)
    {
      key = getClassName(reflectedObj);
    }
    else
    {
      key = getClassNameOf(reflectedObj);
    }

    if ((isScript || isScriptStaticRef) && PolymodScriptClass.blacklistedScriptClasses.contains(key))
    {
      return false;
    }

    if (PolymodScriptClass.importOverrides.exists(key) && PolymodScriptClass.importOverrides.get(key) == null) return false;

    if (varName != null)
    {
      var cacheKey = '${(isClassReflect || isScriptStaticRef) ? "C_" : "I_"}$key';

      var targetCache = (isScript || isScriptStaticRef) ? blacklistedScriptFieldsCache : blacklistedFieldsCache;
      var blacklistedFields:Null<Array<String>> = targetCache.get(cacheKey);

      if (blacklistedFields == null)
      {
        if (isScriptStaticRef)
        {
          blacklistedFields = PolymodScriptClass.blacklistedScriptClassStaticFields.get(key);
        }
        else if (isScript)
        {
          blacklistedFields = PolymodScriptClass.blacklistedScriptClassInstanceFields.get(key);
        }
        else if (isClassReflect)
        {
          blacklistedFields = PolymodScriptClass.blacklistedStaticFields.get(reflectedObj);
        }
        else
        {
          blacklistedFields = PolymodScriptClass.blacklistedInstanceFields.get(key);
        }

        if (blacklistedFields == null) blacklistedFields = [];
        targetCache.set(cacheKey, blacklistedFields);
      }
      if (blacklistedFields.contains(varName)) return false;
    }

    return true;
  }
}

/**
 * Custom enum expanding Haxe's ValueType with Polymod script class / enum support.
 * Used by ReflectUtil for scripted class / enum reflection and type inspection.
 */
enum ScriptValueType
{
  TNull;
  TInt;
  TFloat;
  TBool;
  TObject;
  TFunction;
  TClass(c:Class<Dynamic>);
  TEnum(e:Enum<Dynamic>);
  TScriptClass(c:PolymodStaticClassReference);
  TScriptEnum(c:PolymodEnum);
  TUnknown;
}
