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
    return Reflect.callMethod(null, Reflect.field(Type.resolveClass('funkin.util.macro.AbstractAliases'), 'get'), []);
  }

  public static macro function buildPolymodAbstracts(abstractClasses:Array<String>):Void
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
          case ModuleType.TAbstract(a):
            var cls = a.get();
            for (abstractCls in abstractClasses)
            {
              if (!cls.module.startsWith(abstractCls.replace('.*', ''))
                && cls.module + cls.name != abstractCls
                && cls.pack.join('.') + '.' + cls.name != abstractCls)
              {
                continue;
              }
              aliases.set('${cls.pack.join('.')}.${cls.name}', 'polymod.abstracts.${cls.pack.join('.')}.${cls.name}');
              buildAbstract(cls);
              break;
            }
          default:
            // do nothing
        }
      }

      Context.defineModule('funkin.util.macro.PolymodMacro', [
        {
          pack: ['funkin', 'util', 'macro'],
          name: 'AbstractAliases',
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

  static function buildAbstract(abstractCls:AbstractType):Void
  {
    if (abstractCls.impl == null)
    {
      return;
    }

    skipFields = [];

    var cls:ClassType = abstractCls.impl.get();

    // we use the functions to check whether we need to skip some fields
    // that is why we sort the fields, so that functions are handled first
    var sortedFields:Array<ClassField> = sortFields(cls.statics.get());

    var fields:Array<Field> = [];
    for (field in sortedFields)
    {
      if (field.name == '_new')
      {
        fields.push(buildCreateField(abstractCls, field));
        continue;
      }

      fields = fields.concat(createFields(abstractCls, field));
    };

    Context.defineType(
      {
        pos: Context.currentPos(),
        pack: ['polymod', 'abstracts'].concat(abstractCls.module.split('.')),
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

  static function buildCreateField(cls:AbstractType, field:ClassField):Field
  {
    var newExprStr = trialAndError(cls, field) ?? 'new ${cls.module}.${cls.name}';

    var funcArgs = [];
    var funcArgNames:Array<String> = [];
    switch (field.type)
    {
      case Type.TFun(args, _):
        for (arg in args)
        {
          funcArgs.push(
            {
              name: arg.name,
              type: (macro :Dynamic),
              opt: arg.opt
            });
          funcArgNames.push(arg.name);
        }
      default:
        throw 'how is this not a function';
    }

    return {
      name: 'create',
      access: [Access.APublic, Access.AStatic],
      kind: FieldType.FFun(
        {
          args: funcArgs,
          ret: (macro :Dynamic),
          expr: macro
          {
            return ${Context.parse(newExprStr + '(' + funcArgNames.join(', ') + ')', Context.currentPos())};
          },
        }),
      pos: Context.currentPos()
    };
  }

  static function trialAndError(cls:AbstractType, field:ClassField):Null<String>
  {
    if (cls.params.length <= 0)
    {
      return null;
    }

    function getCombinations(num:Int):Array<Array<String>>
    {
      if (num == 0)
      {
        return [[]];
      }

      var combinations:Array<Array<String>> = [];
      for (combination in getCombinations(num - 1))
      {
        // combinations.push(combination.concat(['Dynamic']));
        combinations.push(combination.concat(['Dynamic->Void']));
      }

      return combinations;
    }
    var typeArgss:Array<Array<String>> = getCombinations(cls.params.length);

    for (typeArgs in typeArgss)
    {
      // TODO: figure out a way to find out whether a typeparameter is valid or not
      try
      {
        // var expr = Context.parse('new ${cls.module}.${cls.name}<' + typeArgs.join(', ') + '>()', Context.currentPos());
        // return expr;
        return 'new ${cls.module}.${cls.name} <' + typeArgs.join(', ') + '>';
      }
      catch (e)
      {
        trace(e);
      }
    }

    return null;
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
    if (field.meta.has(':to'))
    {
      return [];
    }

    var fields:Array<Field> = [];

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
              type: (macro :Dynamic),
              opt: arg.opt,
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
                ret: (macro :Dynamic),
                expr: macro
                {
                  @:privateAccess
                  return ${strExpr};
                },
                params: []
              }),
            pos: Context.currentPos()
          });
      case Type.TAbstract(t, params):
        fields.push(
          {
            name: field.name,
            doc: field.doc,
            access: [Access.AStatic].concat(getFieldAccess(field)),
            kind: FieldType.FProp('get', 'never', (macro :Dynamic), null),
            pos: Context.currentPos()
          });

        var strExpr = Context.parse('${cls.module}.${cls.name}.${field.name}', Context.currentPos());

        fields.push(
          {
            name: 'get_${field.name}',
            doc: field.doc,
            access: [Access.AStatic, field.isPublic ? Access.APublic : Access.APrivate],
            kind: FieldType.FFun(
              {
                args: [],
                ret: (macro :Dynamic),
                expr: macro
                {
                  @:privateAccess
                  return ${strExpr};
                },
                params: []
              }),
            pos: Context.currentPos()
          });
      case TType(t, params):
        fields.push(
          {
            name: field.name,
            doc: field.doc,
            access: [Access.AStatic].concat(getFieldAccess(field)),
            kind: FieldType.FProp('get', 'never', (macro :Dynamic), null),
            pos: Context.currentPos()
          });

        var strExpr = Context.parse('${cls.module}.${cls.name}.${field.name}', Context.currentPos());

        fields.push(
          {
            name: 'get_${field.name}',
            doc: field.doc,
            access: [Access.AStatic, field.isPublic ? Access.APublic : Access.APrivate],
            kind: FieldType.FFun(
              {
                args: [],
                ret: (macro :Dynamic),
                expr: macro
                {
                  @:privateAccess
                  return ${strExpr};
                },
                params: []
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
