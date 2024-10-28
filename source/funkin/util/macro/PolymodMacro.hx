package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using StringTools;

class PolymodMacro
{
  public static var aliases(get, never):Map<String, String>;

  static function get_aliases():Map<String, String>
  {
    // truly a sight to behold
    return Reflect.callMethod(null, Reflect.field(Type.resolveClass('funkin.util.macro.EnumAliases'), 'get'), []);
  }

  public static macro function buildPolymodEnums():Void
  {
    Context.onAfterTyping((types) -> {
      if (alreadyCalled)
      {
        return;
      }

      var aliases:Map<String, String> = new Map<String, String>();
      for (type in types)
      {
        switch (type)
        {
          case ModuleType.TEnumDecl(e):
            var enm = e.get();
            if (enm.isPrivate)
            {
              continue;
            }

            var enmName:String = enm.pack.length > 0 ? '${enm.pack.join('.')}.${enm.name}' : '${enm.name}';

            aliases.set('${enmName}', 'polymod.enums.${enmName}');
            buildEnum(enm);
          default:
            // do nothing
        }
      }

      Context.defineModule('funkin.util.macro.PolymodMacro', [
        {
          pack: ['funkin', 'util', 'macro'],
          name: 'EnumAliases',
          kind: TypeDefKind.TDClass(null, [], false, false, false),
          fields: [
            {
              name: 'get',
              access: [Access.APublic, Access.AStatic],
              kind: FieldType.FFun(
                {
                  args: [],
                  ret: (macro :Map<String, String>),
                  expr: macro
                  {
                    return $v{aliases};
                  }
                }),
              pos: Context.currentPos()
            }
          ],
          pos: Context.currentPos()
        }
      ]);

      // the callback is called twice, which this leads to issues
      alreadyCalled = true;
    });
  }

  #if macro
  static var alreadyCalled:Bool = false;

  static function buildEnum(enm:EnumType):Void
  {
    var enmName:String = enm.module != '' ? '${enm.module}.${enm.name}' : '${enm.name}';

    var fields:Array<Field> = [];

    for (fieldName => field in enm.constructs)
    {
      switch (field.type)
      {
        case Type.TFun(args, ret):
          var fieldArgs:Array<FunctionArg> = [];
          var fieldArgNames:Array<String> = [];
          for (arg in args)
          {
            fieldArgs.push(
              {
                name: arg.name,
                opt: arg.opt,
                type: (macro :Dynamic)
              });
            fieldArgNames.push(arg.name);
          }

          fields.push(
            {
              name: fieldName,
              access: [Access.APublic, Access.AStatic],
              kind: FieldType.FFun(
                {
                  args: fieldArgs,
                  ret: (macro :Dynamic),
                  expr: macro
                  {
                    return ${Context.parse(enmName + '.' + fieldName + '(' + fieldArgNames.join(', ') + ')', Context.currentPos())};
                  }
                }),
              pos: Context.currentPos()
            });
        case Type.TEnum(t, params):
          fields.push(
            {
              name: fieldName,
              access: [Access.APublic, Access.AStatic, Access.AFinal],
              kind: FieldType.FVar((macro :Dynamic), macro
                {
                  ${Context.parse(enmName + '.' + fieldName, Context.currentPos())};
                }),
              pos: Context.currentPos()
            });
        default:
          throw 'unhandled type';
      }
    }

    Context.defineType(
      {
        pos: Context.currentPos(),
        pack: ['polymod', 'enums'].concat(enm.pack),
        name: enm.name,
        kind: TypeDefKind.TDClass(null, [], false, false, false),
        fields: fields,
      }, null);
  }
  #end
}
