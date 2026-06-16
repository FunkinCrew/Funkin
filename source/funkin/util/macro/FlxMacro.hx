package funkin.util.macro;

#if !display
#if macro
@:nullSafety
class FlxMacro
{
  /**
   * A macro to be called targeting the `FlxSprite` class.
   * @return An array of fields that the class contains.
   */
  public static macro function buildFlxSprite():Array<haxe.macro.Expr.Field>
  {
    var pos:haxe.macro.Expr.Position = haxe.macro.Context.currentPos();
    // The FlxSprite class. We can add new properties to this class.
    var cls:haxe.macro.Type.ClassType = haxe.macro.Context.getLocalClass().get();
    // The fields of the FlxSprite.
    var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();

    var fieldsToAdd = [];
    fieldsToAdd.push({
      name: 'localX',
      kind: haxe.macro.Expr.FieldType.FVar(macro :Float, macro $v{0})
    });
    fieldsToAdd.push({
      name: 'localY',
      kind: haxe.macro.Expr.FieldType.FVar(macro :Float, macro $v{0})
    });
    fieldsToAdd.push({
      name: 'localAngle',
      kind: haxe.macro.Expr.FieldType.FVar(macro :Float, macro $v{0})
    });
    fieldsToAdd.push({
      name: 'localScale',
      kind: haxe.macro.Expr.FieldType.FVar(macro :flixel.math.FlxPoint, macro new flixel.math.FlxPoint(1, 1))
    });
    fieldsToAdd.push({
      name: 'localAlpha',
      kind: haxe.macro.Expr.FieldType.FVar(macro :Float, macro $v{1})
    });
    fieldsToAdd.push({
      name: 'localVisible',
      kind: haxe.macro.Expr.FieldType.FVar(macro :Bool, macro $v{true})
    });

    var alreadyOwnedFields = [];

    for (f in fields)
    {
      for (a in fieldsToAdd)
      {
        if (f.name == a.name) alreadyOwnedFields.push(a.name);
      }
    }

    for (f in fieldsToAdd)
    {
      if (alreadyOwnedFields.contains(f.name)) continue;

      fields.push({
        name: f.name, // Field name.
        access: [haxe.macro.Expr.Access.APublic], // Access level
        kind: f.kind, // Variable type and default value
        pos: pos, // The field's position in code.
      });
    }

    return fields;
  }
}
#end
#end
