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

      var sortedAbstractClasses:Array<String> = [];
      for (abstractCls in abstractClasses)
      {
        if (abstractCls.startsWith('!'))
        {
          sortedAbstractClasses.insert(0, abstractCls);
        }
        else
        {
          sortedAbstractClasses.push(abstractCls);
        }
      }

      var aliases:Map<String, String> = new Map<String, String>();

      for (type in types)
      {
        switch (type)
        {
          case ModuleType.TAbstract(a):
            var cls = a.get();
            if (cls.isPrivate)
            {
              continue;
            }

            for (abstractCls in sortedAbstractClasses)
            {
              var negate:Bool = abstractCls.startsWith('!');
              var name:String = abstractCls.replace('!', '').replace('.*', '');
              if (!negate && !cls.module.startsWith(name) && moduleTypePath(cls) != name && packTypePath(cls) != name)
              {
                continue;
              }
              else if (negate)
              {
                if (cls.module.startsWith(name) || moduleTypePath(cls) == name || packTypePath(cls) == name)
                {
                  break;
                }
                else
                {
                  continue;
                }
              }

              aliases.set('${packTypePath(cls)}', 'polymod.abstracts.${packTypePath(cls)}');
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

  static function buildCreateField(cls:AbstractType, field:ClassField):Field
  {
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

    var expr:String = '${newExpr(cls, field)}(${funcArgNames.join(', ')})';

    return {
      name: 'create',
      access: [Access.APublic, Access.AStatic],
      kind: FieldType.FFun(
        {
          args: funcArgs,
          ret: (macro :Dynamic),
          expr: macro
          {
            @:privateAccess
            return ${Context.parse(expr, Context.currentPos())};
          },
        }),
      pos: Context.currentPos()
    };
  }

  static function newExpr(cls:AbstractType, field:ClassField):Null<String>
  {
    if ('${moduleTypePath(cls)}' == 'flixel.util.FlxSignal.FlxTypedSignal')
    {
      return 'new flixel.util.FlxSignal.FlxTypedSignal<Dynamic->Void>';
    }

    if (cls.params.length <= 0)
    {
      return 'new ${moduleTypePath(cls)}';
    }

    return 'new ${moduleTypePath(cls)}< ${[for (_ in 0...cls.params.length) 'Dynamic'].join(', ')} >';
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

        var returnStr:String = 'return ';
        var returnType:ComplexType = (macro :Dynamic);
        switch (ret)
        {
          case Type.TAbstract(t, _):
            if (t.get().name == 'Void')
            {
              returnStr = '';
              returnType = (macro :Void);
            }
          default:
        }

        var expr:String = '${returnStr}${moduleTypePath(cls)}.${field.name}(${exprArgs.join(', ')})';

        fields.push(
          {
            name: field.name,
            doc: field.doc,
            access: [Access.APublic, Access.AStatic],
            kind: FieldType.FFun(
              {
                args: fieldArgs,
                ret: returnType,
                expr: macro
                {
                  @:privateAccess
                  ${Context.parse(expr, Context.currentPos())};
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
            access: [Access.APublic, Access.AStatic],
            kind: FieldType.FProp('get', 'never', (macro :Dynamic), null),
            pos: Context.currentPos()
          });

        var expr:String = '${moduleTypePath(cls)}.${field.name}';

        fields.push(
          {
            name: 'get_${field.name}',
            doc: field.doc,
            access: [Access.APublic, Access.AStatic],
            kind: FieldType.FFun(
              {
                args: [],
                ret: (macro :Dynamic),
                expr: macro
                {
                  @:privateAccess
                  return ${Context.parse(expr, Context.currentPos())};
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
            access: [Access.APublic, Access.AStatic],
            kind: FieldType.FProp('get', 'never', (macro :Dynamic), null),
            pos: Context.currentPos()
          });

        var expr:String = '${moduleTypePath(cls)}.${field.name}';

        fields.push(
          {
            name: 'get_${field.name}',
            doc: field.doc,
            access: [Access.APublic, Access.AStatic],
            kind: FieldType.FFun(
              {
                args: [],
                ret: (macro :Dynamic),
                expr: macro
                {
                  @:privateAccess
                  return ${Context.parse(expr, Context.currentPos())};
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

  // Dynamic so any kind of type with `module` and `name` fields works
  static function moduleTypePath(type:Dynamic):String
  {
    var dot:String = type.module.length != 0 ? '.' : '';
    return '${type.module}${dot}${type.name}';
  }

  // Dynamic so any kind of type with `pack` and `name` fields works
  static function packTypePath(type:Dynamic):String
  {
    var dot:String = type.pack.length != 0 ? '.' : '';
    return '${type.pack.join('.')}${dot}${type.name}';
  }
  #end
}
