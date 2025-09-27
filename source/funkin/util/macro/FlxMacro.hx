package funkin.util.macro;

#if !display
#if macro
import haxe.macro.Expr.Access;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

@:nullSafety
class FlxMacro
{
  /**
   * A macro to be called targeting the `FlxBasic` class.
   * @return An array of fields that the class contains.
   */
  public static macro function buildFlxBasic():Array<Field>
  {
    var pos:Position = Context.currentPos();
    // The FlxBasic class. We can add new properties to this class.
    var cls:ClassType = Context.getLocalClass().get();
    // The fields of the FlxClass.
    var fields:Array<Field> = Context.getBuildFields();

    // Context.info('[INFO] ${cls.name}: Adding zIndex attribute...', pos);

    // Here, we add the zIndex attribute to all FlxBasic objects.
    // This has no functional code tied to it, but it can be used as a target value
    // for the FlxTypedGroup.sort method, to rearrange the objects in the scene.
    fields = fields.concat([
      {
        name: "zIndex", // Field name.
        access: [APublic], // Access level
        kind: FVar(macro :Int, macro $v{0}), // Variable type and default value
        pos: pos, // The field's position in code.
      }
    ]);
    return fields;
  }

  public static macro function buildBitmapFrontEnd():Array<Field>
  {
    var pos:Position = Context.currentPos();
    var fields:Array<Field> = Context.getBuildFields();

    for (f in fields)
    {
      if (f.name == "get")
      {
        f.name = "__get";
        f.access.remove(APublic);
        f.access.push(APrivate);
      }
    }

    fields = fields.concat([
      {
        name: "__cacheCopy",
        access: [APrivate],
        kind: FVar(macro :Map<String, flixel.graphics.FlxGraphic>, macro $v{[]}),
        pos: pos
      },
      {
        name: "__dontClear",
        access: [APublic],
        kind: FVar(macro :Bool, macro $v{false}),
        pos: pos
      },
      {
        name: "get",
        access: [APublic],
        kind: FFun(
          {
            args: [
              {
                name: "key",
                type: macro :String,
                opt: false,
                value: null
              }
            ],
            ret: macro :flixel.graphics.FlxGraphic,
            expr: macro
            {
              // See FunkinGame.hx to see how this is used
              var graphic = this.__get(key);
              if (graphic != null) graphic.isUnused = false;
              return graphic;
            }
          }),
        pos: pos
      }
    ]);
    return fields;
  }

  public static macro function buildFlxGraphic():Array<Field>
  {
    var pos:Position = Context.currentPos();
    var fields:Array<Field> = Context.getBuildFields();

    for (f in fields)
    {
      if (f.name == "checkUseCount")
      {
        f.name = "__checkUseCount";
      }
    }

    fields = fields.concat([
      {
        name: "isUnused",
        access: [APublic],
        kind: FVar(macro :Bool, macro $v{false}),
        pos: pos
      },
      {
        name: "checkUseCount", // Override the checkUseCount
        access: [],
        kind: FFun(
          {
            args: [],
            ret: macro :Void,
            expr: macro
            {
              if (FlxG.bitmap.__dontClear) return;
              __checkUseCount();
            }
          }),
        pos: pos
      }
    ]);
    return fields;
  }
}
#end
#end
