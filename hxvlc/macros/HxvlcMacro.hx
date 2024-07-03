package macros;

#if !display
#if macro
// Mostly a copy of funkin.util.macro.FlxMacro lmao
class HxvlcMacro
{
  /**
   * A macro to be called targeting the `Video` class.
   * @return An array of fields that the class contains.
   */
  public static macro function buildOpenFLVideo():Array<haxe.macro.Expr.Field>
  {
    var pos:haxe.macro.Expr.Position = haxe.macro.Context.currentPos();
    // The Video class. We can add new properties to this class.
    var cls:haxe.macro.Type.ClassType = haxe.macro.Context.getLocalClass().get();
    // The fields of the FlxClass.
    var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();

    // haxe.macro.Context.info('[INFO] ${cls.name}: Adding onTextureSetup attribute...', pos);

    // Here, we add the onTextureSetup attribute to all Video objects.
    // This has no functional code tied to it, but it can be used as a target value
    fields = fields.concat([
      {
        name: "onTextureSetup", // Field name.
        access: [haxe.macro.Expr.Access.APublic], // Access level
        kind: haxe.macro.Expr.FieldType.FVar(macro :lime.app.Event<Void->Void>, macro $v{null}), // Variable type and default value
        pos: pos, // The field's position in code.
      }
    ]);

    return fields;
  }

  /**
   * A macro that adds 2 new parameters to the `play` method.
   * @return An array of fields that the class contains.
   */
  public static macro function addPlayMethodParams():Array<haxe.macro.Expr.Field>
  {
    var pos:haxe.macro.Expr.Position = haxe.macro.Context.currentPos();
    // The Video class. We can add new properties to this class.
    var cls:haxe.macro.Type.ClassType = haxe.macro.Context.getLocalClass().get();
    // The fields of the FlxClass.
    var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();

    // Here, we add extra parameters to the play method
    // haxe.macro.Context.info('[INFO] ${cls.name}: Adding new parameters to the play method...', pos);

    for (field in fields)
    {
      // Check if the field/method name is indeed called play
      if (field.name == "play")
      {
        switch (field.kind)
        {
          case FFun(func):
            // Push all the new args into an array.
            var newArgs = [];
            newArgs.push(
              {
                name: "location",
                type: macro :String,
                opt: true,
                pos: pos
              });

            newArgs.push(
              {
                name: "shouldLoop",
                type: macro :Bool,
                opt: true,
                pos: pos
              });

            // Connect the main args with the new ones
            func.args = func.args.concat(newArgs);
          default:
        }
      }
    }

    return fields;
  }
}
#end
#end
