package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * A collection of utility functions for Haxe macros.
 */
@:nullSafety
class MacroUtil
{
  /**
   * Gets the value of a Haxe compiler define.
   *
   * @param key The name of the define to get the value of.
   * @param defaultValue The value to return if the define is not set.
   * @return An expression containing the value of the define.
   */
  public static macro function getDefine(key:String, ?defaultValue:String):haxe.macro.Expr
  {
    var value:Null<String> = haxe.macro.Context.definedValue(key);
    if (value == null) value = defaultValue;
    return macro $v{value};
  }

  /**
   * Gets the current date and time (at compile time).
   * @return A `Date` object containing the current date and time.
   */
  public static macro function getDate():ExprOf<Date>
  {
    var date:Date = Date.now();
    var year:Expr = toExpr(date.getFullYear());
    var month:Expr = toExpr(date.getMonth());
    var day:Expr = toExpr(date.getDate());
    var hours:Expr = toExpr(date.getHours());
    var mins:Expr = toExpr(date.getMinutes());
    var secs:Expr = toExpr(date.getSeconds());
    return macro new Date($year, $month, $day, $hours, $mins, $secs);
  }

  #if macro
  //
  // MACRO HELPER FUNCTIONS
  //

  /**
   * Convert an ExprOf<Class<T>> to a ClassType.
   * @see https://github.com/jasononeil/compiletime/blob/master/src/CompileTime.hx#L201
   * @param e The expression to convert.
   * @return The `ClassType`
   */
  public static function getClassTypeFromExpr(e:Expr):ClassType
  {
    var classType:ClassType = null;

    var parts:Array<String> = [];
    var nextSection:ExprDef = e.expr;

    while (nextSection != null)
    {
      var section:ExprDef = nextSection;
      nextSection = null;

      switch (section)
      {
        // Expression is a class name with no packages
        case EConst(c):
          switch (c)
          {
            case CIdent(cn):
              if (cn != "null") parts.unshift(cn);
            default:
          }
        // Expression is a fully qualified package name.
        // We need to traverse the expression tree to get the full package name.
        case EField(exp, field):
          nextSection = exp.expr;
          parts.unshift(field);

        // We've reached the end of the expression tree.
        default:
      }
    }

    var fullClassName:String = parts.join('.');
    if (fullClassName != "")
    {
      var classType:Type = Context.getType(fullClassName);
      // Follow typedefs to get the actual class type.
      var classTypeParsed:Type = Context.follow(classType, false);

      switch (classTypeParsed)
      {
        case TInst(t, params):
          return t.get();
        default:
          // We couldn't parse this class type.
          // This function may need to be updated to be more robust.
          throw 'Class type could not be parsed: ${fullClassName}';
      }
    }

    return null;
  }

  /**
   * Determine whether a field is static.
   * @param field The field to check.
   * @return Whether the field is static.
   */
  public static function isFieldStatic(field:haxe.macro.Expr.Field):Bool
  {
    return field.access.contains(AStatic);
  }

  /**
   * Converts a value to an equivalent macro expression.
   */
  public static function toExpr(value:Any):ExprOf<Any>
  {
    return Context.makeExpr(value, Context.currentPos());
  }

  /**
   * Determine whether two classes are equal.
   * @param class1 The first class to compare.
   * @param class2 The second class to compare.
   * @return Whether the two classes are equivalent.
   */
  public static function areClassesEqual(class1:ClassType, class2:ClassType):Bool
  {
    return class1.pack.join('.') == class2.pack.join('.') && class1.name == class2.name;
  }

  /**
   * Retrieve a ClassType from a string name.
   * @param name The name of the class to retrieve.
   * @return The `ClassType`
   */
  public static function getClassType(name:String):ClassType
  {
    switch (Context.getType(name))
    {
      case TInst(t, _params):
        return t.get();
      default:
        throw 'Class type could not be parsed: ${name}';
    }
  }

  /**
   * If we are in a build macro, return whether a field already exists on the current class.
   * @param name The name of the field to check for.
   * @return Whether the field already exists.
   */
  public static function fieldAlreadyExists(name:String):Bool
  {
    for (field in Context.getBuildFields())
    {
      if (field.name == name && !((field.access ?? []).contains(Access.AAbstract)))
      {
        return true;
      }
    }

    function fieldAlreadyExistsSuper(name:String, superClass:Null<ClassType>)
    {
      if (superClass == null)
      {
        return false;
      }

      for (field in superClass.fields.get())
      {
        if (field.name == name && !field.isAbstract)
        {
          return true;
        }
      }

      // recursively check superclasses
      return fieldAlreadyExistsSuper(name, superClass.superClass?.t.get());
    }

    return fieldAlreadyExistsSuper(name, Context.getLocalClass().get().superClass?.t.get());
  }

  /**
   * Determine whether a given ClassType is a subclass of a given superclass.
   * @param classType The class to check.
   * @param superClass The superclass to check for.
   * @return Whether the class is a subclass of the superclass.
   */
  public static function isSubclassOf(classType:ClassType, superClass:ClassType):Bool
  {
    if (areClassesEqual(classType, superClass)) return true;

    if (classType.superClass != null)
    {
      return isSubclassOf(classType.superClass.t.get(), superClass);
    }

    return false;
  }

  /**
   * Determine whether a given ClassType implements a given interface.
   * @param classType The class to check.
   * @param interfaceType The interface to check for.
   * @return Whether the class implements the interface.
   */
  public static function implementsInterface(classType:ClassType, interfaceType:ClassType):Bool
  {
    for (i in classType.interfaces)
    {
      if (areClassesEqual(i.t.get(), interfaceType))
      {
        return true;
      }
    }

    if (classType.superClass != null)
    {
      return implementsInterface(classType.superClass.t.get(), interfaceType);
    }

    return false;
  }
  #end
}
