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
      switch (type)
      {
        case Type.TAbstract(t, _):
          buildAbstract(t.get());
        default:
          throw 'BRUH';
      }

      // var type = Context.getType('funkin.Paths.PathsFunction');
      // switch (type)
      // {
      //   case Type.TAbstract(t, _):
      //     buildAbstract(t.get());
      //   default:
      //     throw 'BRUH';
      // }
    });
  }

  public static macro function getAbstractAliases():ExprOf<Map<String, String>>
  {
    var abstractAliases:Map<String, String> = new Map<String, String>();
    var abstractTypes = [
      Context.getType('flixel.util.FlxColor'),
      // Context.getType('funkin.Paths.PathsFunction')
    ];
    for (abstractType in abstractTypes)
    {
      var type = switch (abstractType)
      {
        case Type.TAbstract(t, _):
          t.get();
        default:
          throw 'BRUH';
      }

      // should this use `type.module` insead of `type.pack`?
      abstractAliases.set('${type.pack.join('.')}.${type.name}', 'polymod.abstracts.${type.pack.join('.')}.${type.name}');
    }
    return macro $v{abstractAliases};
  }

  #if macro
  static var skipFields:Array<String> = [];

  static function buildAbstract(abstractCls:AbstractType):Void
  {
    if (abstractCls.impl == null)
    {
      return;
    }

    skipFields = [];

    var cls = abstractCls.impl.get();

    // we use the functions to check whether we need to skip some fields
    // that is why we sort the fields, so that functions are handled first
    var sortedFields:Array<ClassField> = sortFields(cls.statics.get());

    var fields:Array<Field> = [];
    for (field in sortedFields)
    {
      if (field.name == '_new')
      {
        continue;
      }

      fields = fields.concat(createFields(abstractCls, field));
    };

    Context.defineType(
      {
        pos: Context.currentPos(),
        pack: ['polymod', 'abstracts'].concat(abstractCls.pack),
        name: abstractCls.name,
        kind: TypeDefKind.TDClass(null, [], false, false, false),
        fields: fields,
      }, null);
  }

  static function sortFields(fields:Array<ClassField>):Array<ClassField>
  {
    var sortedFields:Array<ClassField> = [];
    for (field in fields)
    {
      switch (field.type)
      {
        case Type.TLazy(f):
          switch (f())
          {
            case Type.TFun(_, _):
              sortedFields.insert(0, field);
            default:
              sortedFields.push(field);
          }
        case Type.TFun(_, _):
          sortedFields.insert(0, field);
        default:
          sortedFields.push(field);
      }
    }
    return sortedFields;
  }

  static function createFields(cls:AbstractType, field:ClassField):Array<Field>
  {
    if (skipFields.contains(field.name))
    {
      return [];
    }

    switch (field.type)
    {
      case Type.TLazy(f):
        return _createFields(cls, field, f());
      default:
        return _createFields(cls, field, field.type);
    }
  }

  static function _createFields(cls:AbstractType, field:ClassField, type:Type):Array<Field>
  {
    var fields = [];

    switch (type)
    {
      case Type.TFun(args, ret):
        var fieldArgs = [];
        var exprArgs:Array<String> = [];
        for (arg in args)
        {
          if (arg.name == 'this')
          {
            var memberVariable:String = field.name.replace('get_', '').replace('set_', '');
            if (memberVariable != field.name)
            {
              skipFields.push(memberVariable);
            }
            return [];
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

        var strExpr = Context.parse('${cls.module}.${cls.name}.${field.name}(${exprArgs.join(', ')})', Context.currentPos());

        fields.push(
          {
            name: field.name,
            doc: field.doc,
            access: [Access.AStatic].concat(getFieldAccess(field)),
            kind: FieldType.FFun(
              {
                args: fieldArgs,
                ret: Context.toComplexType(ret),
                expr: macro
                {
                  return ${strExpr};
                },
                params: fieldParams
              }),
            pos: Context.currentPos()
          });
      case Type.TAbstract(t, params):
        fields.push(
          {
            name: field.name,
            doc: field.doc,
            access: [Access.AStatic].concat(getFieldAccess(field)),
            kind: FieldType.FProp('get', 'never', Context.toComplexType(t.get().type), null),
            pos: Context.currentPos()
          });

        var fieldParams = [];
        for (param in field.params)
        {
          fieldParams.push(
            {
              name: param.name,
              defaultType: Context.toComplexType(param.defaultType),
            });
        }

        var strExpr = Context.parse('${cls.module}.${cls.name}.${field.name}', Context.currentPos());

        fields.push(
          {
            name: 'get_${field.name}',
            doc: field.doc,
            access: [Access.AStatic, field.isPublic ? Access.APublic : Access.APrivate],
            kind: FieldType.FFun(
              {
                args: [],
                ret: Context.toComplexType(t.get().type),
                expr: macro
                {
                  return ${strExpr};
                },
                params: fieldParams
              }),
            pos: Context.currentPos()
          });

      default:
        return [];
    };

    return fields;
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
