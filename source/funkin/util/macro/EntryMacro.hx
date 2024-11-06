package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using StringTools;

class EntryMacro
{
  public static macro function build(registryExpr:ExprOf<Class<Dynamic>>, ...additionalReferencedRegistries:ExprOf<Class<Dynamic>>):Array<Field>
  {
    var fields = Context.getBuildFields();

    var cls = Context.getLocalClass().get();

    var entryData = getEntryData(cls);

    makeReferenceRegistryFieldsCallable(additionalReferencedRegistries.append(registryExpr), fields);

    buildIdField(fields);

    buildDataField(entryData, fields);

    buildFetchDataField(entryData, registryExpr, fields);

    buildToStringField(cls, fields);

    buildDestroyField(cls, fields);

    return fields;
  }

  #if macro
  static function shouldBuildField(name:String, fields:Array<Dynamic>):Bool // fields can be Array<Field> or Array<ClassField>
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

  static function buildDataField(entryData:Dynamic, fields:Array<Field>):Void
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

  static function makeReferenceRegistryFieldsCallable(registryExprs:Array<ExprOf<Class<Dynamic>>>, fields:Array<Field>):Void
  {
    for (registryExpr in registryExprs)
    {
      var registryCls = MacroUtil.getClassTypeFromExpr(registryExpr);
      var expr:String = '${registryExpr.toString()}.instance';

      fields.push(
        {
          name: '_${registryCls.pack.join('_')}_${registryCls.name}',
          access: [Access.APrivate, Access.AStatic],
          kind: FFun(
            {
              args: [],
              expr: macro
              {
                return ${registryExpr}.instance;
              },
              params: []
            }),
          pos: Context.currentPos()
        });
    }
  }

  static function buildFetchDataField(entryData:Dynamic, registryExpr:ExprOf<Class<Dynamic>>, fields:Array<Field>):Void
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

  static function buildToStringField(cls:ClassType, fields:Array<Field>):Void
  {
    if (!shouldBuildField('toString', fields))
    {
      return;
    }

    fields.push(
      {
        name: 'toString',
        access: [Access.APublic],
        kind: FieldType.FFun(
          {
            args: [],
            expr: macro
            {
              return $v{cls.name} + '(' + id + ')';
            },
            params: [],
            ret: (macro :String)
          }),
        pos: Context.currentPos()
      });
  }

  static function buildDestroyField(cls:ClassType, fields:Array<Field>):Void
  {
    if (!shouldBuildField('destroy', fields) || !shouldBuildField('destroy', cls.superClass?.t.get().fields.get() ?? []))
    {
      return;
    }

    fields.push(
      {
        name: 'destroy',
        access: [Access.APublic],
        kind: FieldType.FFun(
          {
            args: [],
            expr: macro
            {
              return;
            },
            params: []
          }),
        pos: Context.currentPos()
      });
  }
  #end
}
