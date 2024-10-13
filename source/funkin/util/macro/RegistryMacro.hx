package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class RegistryMacro
{
  public static macro function build():Array<Field>
  {
    var fields = Context.getBuildFields();

    var cls = Context.getLocalClass().get();

    var typeParams = getTypeParams(cls);
    var entryCls = typeParams.entryCls;
    var jsonCls = typeParams.jsonCls;
    var scriptedEntryCls = getScriptedEntryClass(entryCls);

    buildInstanceField(cls, fields);

    buildGetScriptedClassNamesField(scriptedEntryCls, fields);

    buildCreateScriptedEntryField(entryCls, scriptedEntryCls, fields);

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

  static function getTypeParams(cls:ClassType):RegistryTypeParams
  {
    switch (cls.superClass.t.get().kind)
    {
      case KGenericInstance(_, params):
        var typeParams:Array<Dynamic> = [];
        for (param in params)
        {
          switch (param)
          {
            case TInst(t, _):
              typeParams.push(t.get());
            case TType(t, _):
              typeParams.push(t.get());
            default:
              throw 'Not a class';
          }
        }
        return {entryCls: typeParams[0], jsonCls: typeParams[1]};
      default:
        throw 'Not in the correct format';
    }
  }

  static function getScriptedEntryClass(entryCls:ClassType):ClassType
  {
    var scriptedEntryClsName = entryCls.pack.join('.') + '.Scripted' + entryCls.name;
    switch (Context.getType(scriptedEntryClsName))
    {
      case Type.TInst(t, _):
        return t.get();
      default:
        throw 'Not A Class (${scriptedEntryClsName})';
    };
  }

  static function buildInstanceField(cls:ClassType, fields:Array<Field>):Void
  {
    if (!shouldBuildField('instasnce', fields))
    {
      return;
    }

    fields.push(
      {
        name: '_instance',
        access: [Access.APrivate, Access.AStatic],
        kind: FieldType.FVar(ComplexType.TPath(
          {
            pack: [],
            name: 'Null',
            params: [
              TypeParam.TPType(ComplexType.TPath(
                {
                  pack: cls.pack,
                  name: cls.name,
                  params: []
                }))
            ]
          })),
        pos: Context.currentPos()
      });

    fields.push(
      {
        name: 'instance',
        access: [Access.APublic, Access.AStatic],
        kind: FieldType.FProp("get", "never", ComplexType.TPath(
          {
            pack: cls.pack,
            name: cls.name,
            params: []
          })),
        pos: Context.currentPos()
      });

    var newStrExpr = 'new ${cls.pack.join('.')}.${cls.name}()';
    var newExpr = Context.parse(newStrExpr, Context.currentPos());

    fields.push(
      {
        name: 'get_instance',
        access: [Access.APrivate, Access.AStatic],
        kind: FFun(
          {
            args: [],
            expr: macro
            {
              if (_instance == null)
              {
                _instance = ${newExpr};
              }
              return _instance;
            },
            params: [],
            ret: ComplexType.TPath(
              {
                pack: cls.pack,
                name: cls.name,
                params: []
              })
          }),
        pos: Context.currentPos()
      });
  }

  static function buildGetScriptedClassNamesField(scriptedEntryCls:ClassType, fields:Array<Field>):Void
  {
    if (!shouldBuildField('getScriptedClassNames', fields))
    {
      return;
    }

    var scriptedEntryExpr = Context.parse('${scriptedEntryCls.pack.join('.')}.${scriptedEntryCls.name}', Context.currentPos());

    fields.push(
      {
        name: 'getScriptedClassNames',
        access: [Access.APrivate],
        kind: FieldType.FFun(
          {
            args: [],
            expr: macro
            {
              return ${scriptedEntryExpr}.listScriptClasses();
            },
            params: [],
            ret: (macro :Array<String>)
          }),
        pos: Context.currentPos()
      });
  }

  static function buildCreateScriptedEntryField(entryCls:ClassType, scriptedEntryCls:ClassType, fields:Array<Field>):Void
  {
    if (!shouldBuildField('createScriptedEntry', fields))
    {
      return;
    }

    var scriptedStrExpr = '${scriptedEntryCls.pack.join('.')}.${scriptedEntryCls.name}.init(clsName, \'unknown\')';
    var scriptedInitExpr = Context.parse(scriptedStrExpr, Context.currentPos());

    fields.push(
      {
        name: 'createScriptedEntry',
        access: [Access.APrivate],
        kind: FieldType.FFun(
          {
            args: [
              {
                name: 'clsName',
                type: (macro :String)
              }
            ],
            expr: macro
            {
              return ${scriptedInitExpr};
            },
            params: [],
            ret: ComplexType.TPath(
              {
                pack: [],
                name: 'Null',
                params: [
                  TypeParam.TPType(ComplexType.TPath(
                    {
                      pack: entryCls.pack,
                      name: entryCls.name
                    }))
                ]
              })
          }),
        pos: Context.currentPos()
      });
  }
  #end
}

#if macro
typedef RegistryTypeParams =
{
  var entryCls:ClassType;
  var jsonCls:Dynamic; // DefType or ClassType
}
#end
