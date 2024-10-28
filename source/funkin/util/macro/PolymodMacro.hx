package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using StringTools;

enum TestEnum
{
  Windows(x:Float, y:Float);
  Linux(str:String);
  Mac();
}

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
            if (enm.name != 'TestEnum')
            {
              continue;
            }
            for (value in enm.constructs)
            {
              trace(value.type);
            }
            aliases.set('${enm.pack.join('.')}.${enm.name}', 'polymod.enums.${enm.pack.join('.')}.${enm.name}');
          // buildEnum(enm);
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
  static var skipFields:Array<String> = [];

  static function buildEnum(enm:EnumType):Void
  {
    var fields:Array<Field> = [];
    Context.defineType(
      {
        pos: Context.currentPos(),
        pack: ['polymod', 'enums'].concat(enm.module.split('.')),
        name: enm.name,
        kind: TypeDefKind.TDClass(null, [], false, false, false),
        fields: fields,
      }, null);
  }
  #end
}
