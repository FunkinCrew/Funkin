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

    var cls = Context.getLocalClass().get();

    var entryData = getEntryData(cls);

    fields = fields.concat(buildRegistryInstanceField(registryExpr));

    fields.push(build_fetchDataField(entryData, registryExpr));

    return fields;
  }

  #if macro
  static function getEntryData(cls:ClassType):Dynamic // DefType or ClassType
  {
    switch (cls.interfaces[0].params[0])
    {
      case Type.TInst(t, _):
        return t.get();
      case Type.TType(t, _):
        return t.get();
      default:
        throw 'Entry Data is not a class or typedef';
    }
  }

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

  static function build_fetchDataField(entryData:Dynamic, registryExpr:ExprOf<Class<Dynamic>>):Field
  {
    return {
      name: '_fetchData',
      access: [Access.AStatic, Access.APrivate],
      kind: FieldType.FFun(
        {
          args: [
            {
              name: 'id',
              type: (macro :String)
            }
          ],
          expr: macro
          {
            return ${registryExpr}.instance.parseEntryDataWithMigration(id, ${registryExpr}.instance.fetchEntryVersion(id));
          },
          params: [],
          ret: ComplexType.TPath(
            {
              pack: [],
              name: 'Null',
              params: [
                TypeParam.TPType(ComplexType.TPath(
                  {
                    pack: entryData.pack,
                    name: entryData.name
                  }))
              ]
            })
        }),
      pos: Context.currentPos()
    };
  }
  #end
}
