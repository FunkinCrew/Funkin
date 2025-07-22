package funkin.util.macro;

#if macro
using funkin.util.tools.ArrayTools;
#end

/**
 * A macro to make fields inline.
 */
@:nullSafety
class InlineMacro
{
  /**
   * For the given class, find the (static?) field with the given name and make it inline.
   * @param field
   * @param isStatic
   */
  public static macro function makeInline(field:String, isStatic:Bool = false):Array<haxe.macro.Expr.Field>
  {
    var pos:haxe.macro.Expr.Position = haxe.macro.Context.currentPos();
    // The FlxBasic class. We can add new properties to this class.
    var cls:haxe.macro.Type.ClassType = haxe.macro.Context.getLocalClass().get();
    // The fields of the FlxClass.
    var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();

    // Find the field with the given name.
    var targetField:Null<haxe.macro.Expr.Field> = thx.Arrays.find(fields, function(f) return f.name == field
      && (MacroUtil.isFieldStatic(f) == isStatic));

    // If the field was not found, throw an error.
    if (targetField == null) haxe.macro.Context.error("Field " + field + " not found in class " + cls.name, pos);

    // Add the inline access modifier to the field.
    targetField.access.push(AInline);

    return fields;
  }
}
