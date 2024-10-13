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

    buildIdField(fields);

    build_dataField(entryData, fields);

    buildRegistryInstanceField(registryExpr, fields);

    build_fetchDataField(entryData, registryExpr, fields);

    return fields;
  }

  #if macro
  static function shouldBuildField(name:String, fields:Array<Field>):Bool
  {
    for (field in fields)
    {
      if (field.name == name)
      {
        return false;
      }
    }
    return true;
  }

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

  static function buildIdField(fields:Array<Field>):Void
  {
    if (!shouldBuildField('id', fields))
    {
      return;
    }

    fields.push(
      {
        name: 'id',
        access: [Access.APublic, Access.AFinal],
        kind: FieldType.FVar((macro :String)),
        pos: Context.currentPos()
      });
  }

  static function build_dataField(entryData:Dynamic, fields:Array<Field>):Void
  {
    if (!shouldBuildField('_data', fields))
    {
      return;
    }

    fields.push(
      {
        name: '_data',
        access: [Access.APublic, Access.AFinal],
        kind: FieldType.FVar(ComplexType.TPath(
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
          })),
        pos: Context.currentPos()
      });
  }

  static function buildRegistryInstanceField(registryExpr:ExprOf<Class<Dynamic>>, fields:Array<Field>):Void
  {
    if (!shouldBuildField('registryInstance', fields))
    {
      return;
    }

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
  }

  static function build_fetchDataField(entryData:Dynamic, registryExpr:ExprOf<Class<Dynamic>>, fields:Array<Field>):Void
  {
    if (!shouldBuildField('_fetchData', fields))
    {
      return;
    }

    fields.push(
      {
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
      });
  }
  #end
}
