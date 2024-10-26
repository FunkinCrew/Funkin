package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class PolymodMacro
{
  public static macro function buildPolymodAbstracts():Void
  {
    Context.onAfterInitMacros(() -> {
      var type = Context.getType('flixel.util.FlxColor');
      var abst = switch (type)
      {
        case Type.TAbstract(t, _):
          t.get();
        default:
          throw 'BRUH';
      }
      if (abst.impl == null)
      {
        return;
      }
      var cls = abst.impl.get();
      var fields:Array<Field> = [];
      for (field in cls.statics.get())
      {
        if (field.name == '_new')
        {
          continue;
        }

        var polymodField = createField(field);

        if (polymodField == null)
        {
          continue;
        }

        fields.push(polymodField);
      };

      Context.defineType(
        {
          pos: Context.currentPos(),
          pack: ['polymod', 'abstract'].concat(abst.pack),
          name: abst.name,
          kind: TypeDefKind.TDClass(null, [], false, false, false),
          fields: fields,
        }, null);
    });
  }

  public static macro function getAbstractAliases():ExprOf<Map<String, String>>
  {
    var abstractAliases:Map<String, String> = new Map<String, String>();
    var abstractTypes = [Context.getType('flixel.util.FlxColor')];
    for (abstractType in abstractTypes)
    {
      var type = switch (abstractType)
      {
        case Type.TAbstract(t, _):
          t.get();
        default:
          throw 'BRUH';
      }

      abstractAliases.set('${type.pack.join('.')}.${type.name}', 'polymod.abstract.${type.pack.join('.')}.${type.name}');
    }
    return macro $v{abstractAliases};
  }

  #if macro
  static function createField(field:ClassField):Field
  {
    switch (field.type)
    {
      case Type.TLazy(f):
        return _createField(field, f());
      default:
        return _createField(field, field.type);
    }
  }

  static function _createField(field:ClassField, type:Type):Field
  {
    var access = null;
    var kind = null;

    switch (type)
    {
      case Type.TFun(args, ret):
        var fieldArgs = [];
        var exprArgs:Array<String> = [];
        for (arg in args)
        {
          if (arg.name == 'this')
          {
            return null;
          }
          exprArgs.push(arg.name);
          fieldArgs.push(
            {
              name: arg.name,
              type: Context.toComplexType(arg.t),
              opt: arg.opt,
            });
        }
        var fieldParams = [];
        for (param in field.params)
        {
          fieldParams.push(
            {
              name: param.name,
              defaultType: Context.toComplexType(param.defaultType),
            });
        }

        var strExpr = Context.parse('flixel.util.FlxColor.${field.name}(${exprArgs.join(', ')})', Context.currentPos());

        access = [Access.AStatic].concat(getFieldAccess(field));
        kind = FieldType.FFun(
          {
            args: fieldArgs,
            ret: Context.toComplexType(ret),
            expr: macro
            {
              return ${strExpr};
            },
            params: fieldParams
          });
      case Type.TAbstract(t, params):
        access = [Access.AStatic].concat(getFieldAccess(field));
        kind = FieldType.FVar(Context.toComplexType(t.get().type), null);
      default:
        return null;
    };

    if (access == null || kind == null)
    {
      return null;
    }

    return {
      name: field.name,
      doc: field.doc,
      access: access,
      kind: kind,
      pos: Context.currentPos()
    };
  }

  static function getFieldAccess(field:ClassField):Array<Access>
  {
    var access = [];
    access.push(field.isPublic ? Access.APublic : Access.APrivate);
    if (field.isFinal)
    {
      access.push(Access.AFinal);
    }
    if (field.isAbstract)
    {
      access.push(Access.AAbstract);
    }
    if (field.isExtern)
    {
      access.push(Access.AExtern);
    }
    return access;
  }
  #end
}
