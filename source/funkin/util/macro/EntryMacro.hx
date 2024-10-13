package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class EntryMacro
{
  public static macro function build(registryExpr:ExprOf<Class<Dynamic>>):Array<Field>
  {
    var fields = Context.getBuildFields();

    fields = fields.concat(buildRegistryInstanceField(registryExpr));

    return fields;
  }

  #if macro
  static function buildRegistryInstanceField(registryExpr:ExprOf<Class<Dynamic>>):Array<Field>
  {
    var fields = [];

    var registryCls = MacroUtil.getClassTypeFromExpr(registryExpr);

    fields.push(
      {
        name: 'registryInstance',
        access: [Access.APrivate, Access.AStatic],
        kind: FieldType.FProp("get", "never", ComplexType.TPath(
          {
            pack: registryCls.pack,
            name: registryCls.name,
            params: []
          })),
        pos: Context.currentPos()
      });

    fields.push(
      {
        name: 'get_registryInstance',
        access: [Access.APrivate, Access.AStatic],
        kind: FFun(
          {
            args: [],
            expr: macro
            {
              return ${registryExpr}.instance;
            },
            params: [],
            ret: ComplexType.TPath(
              {
                pack: registryCls.pack,
                name: registryCls.name,
                params: []
              })
          }),
        pos: Context.currentPos()
      });

    return fields;
  }
  #end
}
