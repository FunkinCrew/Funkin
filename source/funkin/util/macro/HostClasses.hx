package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr.Field;

using haxe.macro.Tools;
using StringTools;

#if !macro
#if (cpp && scriptable)
@:build(funkin.util.macro.HostClasses.generate())
class HostClasses {}
#end
#else
class HostClasses
{
  static function generate():Array<Field>
  {
    Context.onGenerate((types) -> {
      var modules:Map<String, Array<Type>> = new Map<String, Array<Type>>();
      var typeMap:Map<String, Bool> = new Map<String, Bool>();

      var binDir:String;
      for (cp in Context.getClassPath())
      {
        if (cp.contains('export'))
        {
          binDir = haxe.io.Path.normalize(haxe.io.Path.join([haxe.io.Path.normalize(cp), '..', 'bin']));
          break;
        }
      }
      if (binDir == null) throw 'Could not find export directory in class path';

      for (type in types)
      {
        switch (type)
        {
          case TInst(_.get() => t, _):
            if (haxe.io.Path.normalize(t.pos.getInfos().file).contains('haxe/std')) continue;
            if (t.name.endsWith('_Impl_')) continue;
            typeMap.set('${t.module}.${t.name}', true);
            typeMap.set('${t.pack.join('.')}.${t.name}', true);
            var types:Array<Type> = modules.get(t.module) ?? [];
            modules.set(t.module, types.concat([type]));
          case TType(_.get() => t, _):
            if (haxe.io.Path.normalize(t.pos.getInfos().file).contains('haxe/std')) continue;
            typeMap.set('${t.module}.${t.name}', true);
            typeMap.set('${t.pack.join('.')}.${t.name}', true);
            var types:Array<Type> = modules.get(t.module) ?? [];
            modules.set(t.module, types.concat([type]));
          case TAbstract(_.get() => t, _):
            if (haxe.io.Path.normalize(t.pos.getInfos().file).contains('haxe/std')) continue;
            typeMap.set('${t.module}.${t.name}', true);
            typeMap.set('${t.pack.join('.')}.${t.name}', true);
            var types:Array<Type> = modules.get(t.module) ?? [];
            modules.set(t.module, types.concat([type]));
          case TEnum(_.get() => t, _):
            if (haxe.io.Path.normalize(t.pos.getInfos().file).contains('haxe/std')) continue;
            typeMap.set('${t.module}.${t.name}', true);
            typeMap.set('${t.pack.join('.')}.${t.name}', true);
            var types:Array<Type> = modules.get(t.module) ?? [];
            modules.set(t.module, types.concat([type]));
          default:
            throw 'Unsupported type: ${type}';
        }
      }

      for (module => types in modules)
      {
        var content:String = 'package ${module.split('.').slice(0, -1).join('.')};\n\n';

        var file:String = switch (types[0])
        {
          case TInst(_.get() => t, _):
            t.pos.getInfos().file;
          case TType(_.get() => t, _):
            t.pos.getInfos().file;
          case TAbstract(_.get() => t, _):
            t.pos.getInfos().file;
          case TEnum(_.get() => t, _):
            t.pos.getInfos().file;
          default:
            throw 'Unsupported type: ${types[0]}';
        }

        var typeReplace:Map<String, String> = new Map<String, String>();
        var typeReplaceContent:Map<String, String> = new Map<String, String>();

        var importContent:String = sys.io.File.getContent(file);
        var importRegex:EReg = ~/import\s+([a-zA-Z0-9_.]+)\s+as\s+([a-zA-Z0-9_]+)\s*;/;
        while (importRegex.match(importContent))
        {
          var imp:String = importRegex.matched(1);
          var name:String = importRegex.matched(2);
          importContent = importRegex.matchedRight();
          if (typeMap.exists(imp) && !imp.contains('flash'))
          {
            // i am too lazy to parse preprocessors
            // so i am just going to override these overlapping imports
            for (i => n in typeReplace)
            {
              if (n == name) typeReplace.remove(i);
            }
            typeReplace.set('${module}.${name}', name);
            typeReplaceContent.set(name, imp);
          }
        }

        for (n => i in typeReplaceContent)
        {
          content += 'import ${i} as ${n};\n\n';
        }

        for (type in types)
        {
          switch (type)
          {
            case TInst(_.get() => t, params):
              content += t.isPrivate ? 'private ' : '';
              content += '${t.isInterface ? 'interface' : 'class'} ${t.name}${paramsToString(typeReplace, params)} ';
              if (t.superClass != null) content += 'extends ${typeToString(TInst(t.superClass.t, t.superClass.params), typeReplace, params)} ';
              content += t.interfaces.map((i) -> (t.isInterface ? 'extends' : 'implements') + ' ${typeToString(TInst(i.t, i.params), typeReplace, params)}')
                .join(' ');
              content += '\n';
              content += '{\n';

              for (f in removeGeneratedGenerics(t.statics.get()))
              {
                content += '  static ${fieldToString(f, typeReplace, params, Class)};\n';
              }

              for (f in removeGeneratedGenerics(t.fields.get()).concat(t.constructor != null ? [t.constructor.get()] : []))
              {
                content += '  ${fieldToString(f, typeReplace, params, Class)};\n';
              }

              content += '}\n\n';

            case TAbstract(_.get() => t, params):
              content += t.isPrivate ? 'private ' : '';
              content += t.meta.has(':enum') ? 'enum ' : '';
              content += 'abstract ${t.name}${paramsToString(typeReplace, params)}(${typeToString(t.type, typeReplace, params)}) ';
              content += t.from.map((from) -> from.field == null ? 'from ${typeToString(from.t, typeReplace, params)} ' : '').join(' ');
              content += t.to.map((to) -> to.field == null ? 'to ${typeToString(to.t, typeReplace, params)} ' : '').join(' ');
              content += '\n';
              content += '{\n';

              var isEnum:Bool = t.meta.has(':enum');

              if (t.impl != null)
              {
                var abstractFields:{fields:Array<ClassField>, statics:Array<ClassField>} = abstractFields(t);

                for (f in removeGeneratedGenerics(abstractFields.statics))
                {
                  content += '  static ${fieldToString(f, typeReplace, params, Abstract(isEnum))};\n';
                }

                for (f in removeGeneratedGenerics(abstractFields.fields))
                {
                  content += '  ${fieldToString(f, typeReplace, params, Abstract(isEnum))};\n';
                }
              }
              content += '}\n\n';

            case TEnum(_.get() => t, params):
              content += t.isPrivate ? 'private ' : '';
              content += 'enum ${t.name}${paramsToString(typeReplace, params)}\n';
              content += '{\n';

              for (n in t.names)
              {
                content += '  ${n};\n';
              }

              content += '}\n\n';

            case TType(_.get() => t, params):
              content += t.isPrivate ? 'private ' : '';
              content += 'typedef ${t.name}${paramsToString(typeReplace, params)} = ${typeToString(t.type, typeReplace, params)};\n\n';

            default:
              throw 'Unsupported type: ${type}';
          }
        }

        var directory:String = haxe.io.Path.join([binDir, 'haxe', 'std'].concat(module.split('.').slice(0, -1)));
        if (!sys.FileSystem.exists(directory)) sys.FileSystem.createDirectory(directory);

        var file:String = haxe.io.Path.join([directory, module.split('.').pop() + '.hx']);

        sys.io.File.saveContent(file, content);
      }
    });
    return Context.getBuildFields();
  }

  static function fieldToString(field:ClassField, typeReplace:Map<String, String>, params:Array<Type>, typeInfo:TypeInfo):String
  {
    var string:String = '';
    string += 'extern ';
    string += field.isPublic ? 'public ' : 'public '; // 'private ';
    string += field.isFinal ? 'final ' : '';
    string += field.isAbstract ? 'abstract ' : '';
    params = params.concat(field.params.map((p) -> p.t));

    switch (field.kind)
    {
      case FVar(read, write):
        var getter:String = switch (read)
        {
          case AccNormal: 'default';
          case AccNo: 'null';
          case AccNever: 'never';
          case AccCall: 'get';
          default: 'default';
        };

        var setter:String = switch (write)
        {
          case AccNormal: 'default';
          case AccNo: 'null';
          case AccNever: 'never';
          case AccCall: 'set';
          default: 'default';
        };

        if (!field.isFinal) string += 'var ';

        string += '${field.name}';
        if (!field.isFinal && !(field.expr() != null && setter == 'never')) string += '($getter, $setter)';
        string += ' : ${typeToString(field.type, typeReplace, params)}';
        if (typeInfo.match(Abstract(true)) && field.expr() != null)
        {
          string = string.replace('extern ', '');
          string += ' = ${field.expr().toString(true)}';
        }

      case FMethod(k):
        string += switch (k)
        {
          case MethNormal: '';
          case MethInline: ''; // 'inline ';
          case MethMacro: ''; // 'macro ';
          case MethDynamic: 'dynamic ';
        }

        var isConstructor:Bool = field.name == 'new' || (typeInfo.match(Abstract(_)) && field.name == '_new');

        string += 'function ${isConstructor ? 'new' : field.name}${paramsToString(typeReplace, field.params.map((p) -> p.t))}';

        // using the expr() to get default values for arguments
        // sadly if there is no expr() it means we can't get the default values
        if (field.expr() != null)
        {
          switch (field.expr().expr)
          {
            case TFunction(f):
              var args:Array<String> = [];
              if (typeInfo.match(Abstract(_)) && !isAbstractStaticFunction(field)) f.args.shift();
              for (a in f.args)
              {
                var arg:String = '${a.v.name} : ${typeToString(a.v.t, typeReplace, params)}';
                if (a.value != null) arg += ' = cast ${a.value.toString(true)}';
                //if (a.value != null) arg = '?${arg}';
                args.push(arg);
              }
              string += '(${args.join(', ')})';
              if (!isConstructor) string += ' : ${typeToString(f.t, typeReplace, params)}';
            default:
              throw 'Should not happen, right?';
          }
        }
        else
        {
          switch (field.type)
          {
            case TFun(args_, ret):
              var args:Array<String> = [];
              if (typeInfo.match(Abstract(_)) && !isAbstractStaticFunction(field)) args_.shift();
              for (a in args_)
              {
                args.push((a.opt ? '?' : '') + '${a.name} : ${typeToString(a.t, typeReplace, params)}');
              }
              string += '(${args.join(', ')})';
              if (!isConstructor) string += ' : ${typeToString(ret, typeReplace, params)}';
            default:
              throw 'Should not happen, right?';
          }
        }
    }

    return string;
  }

  static function typeToString(type:Type, typeReplace:Map<String, String>, params:Array<Type>):String
  {
    function typeParams(underlyingParams:Array<Type>):String
    {
      if (underlyingParams.length == 0) return '';
      return '<' + underlyingParams.map((t) -> typeToString(t, typeReplace, params)).join(', ') + '>';
    }

    function typePath(type:Type):String
    {
      return switch (type)
      {
        case TInst(_.get() => t, params):
          var path:String = (t.module == 'StdTypes' ? t.name : (t.module.split('.').pop() == t.name ? t.module : '${t.module}.${t.name}'));
          '${path}${typeParams(params)}';
        case TAbstract(_.get() => t, params):
          var path:String = (t.module == 'StdTypes' ? t.name : (t.module.split('.').pop() == t.name ? t.module : '${t.module}.${t.name}'));
          '${path}${typeParams(params)}';
        case TEnum(_.get() => t, params):
          var path:String = (t.module == 'StdTypes' ? t.name : (t.module.split('.').pop() == t.name ? t.module : '${t.module}.${t.name}'));
          '${path}${typeParams(params)}';
        case TType(_.get() => t, params):
          var path:String = (t.module == 'StdTypes' ? t.name : (t.module.split('.').pop() == t.name ? t.module : '${t.module}.${t.name}'));
          '${path}${typeParams(params)}';
        case TAnonymous(_.get() => t):
          '{\n${[for (f in t.fields) '  ${f.name} : ${typeToString(f.type, typeReplace, params)}'].join(',\n')}\n}';
        case TFun(args, ret):
          var args:String = args.map((a) -> (a.opt ? '?' : '') + '${typeToString(a.t, typeReplace, params)}').join(', ');
          '(${args}) -> ${typeToString(ret, typeReplace, params)}';
        case TDynamic(t):
          'Dynamic${typeParams(t != null ? [t] : [])}';
        case TMono(t):
          'Dynamic';
        case TLazy(_() => t):
          typeToString(t, typeReplace, params);
        default:
          throw 'Unsupported type: ${type}';
      };
    }

    var string:String = typePath(type);
    for (i => n in typeReplace)
    {
      string = string.replace(i, n);
    }
    for (p in params)
    {
      var p1:String = switch (p)
      {
        case TInst(_.get() => t, _):
          '${t.module}.${t.name}';
        default:
          throw 'Should not happen, right?';
      };
      var p2:String = p.toString();
      string = string.replace(p1, p1.split('.').pop());
      string = string.replace(p2, p2.split('.').pop());
    }
    return string;
  }

  static function paramsToString(typeReplace:Map<String, String>, params:Array<Type>):String
  {
    if (params.length == 0) return '';
    return '<' + params.map((t) -> typeToString(t, typeReplace, params)).join(', ') + '>';
  }

  static function removeGeneratedGenerics(fields:Array<ClassField>):Array<ClassField>
  {
    var generics:Array<String> = [];
    for (f in fields)
    {
      if (f.meta.has(':generic')) generics.push('${f.name}_');
    }
    return fields.filter((f) -> {
      for (g in generics)
      {
        if (f.name.startsWith(g)) return false;
      }
      return true;
    });
  }

  static function abstractFields(type:AbstractType):{fields:Array<ClassField>, statics:Array<ClassField>}
  {
    if (type.impl == null) throw '${type.module}.${type.name} has no implementation';

    var fields:Array<ClassField> = [];
    var statics:Array<ClassField> = [];

    for (f in type.impl.get().statics.get())
    {
      switch (f.kind)
      {
        case FVar(ra, wa):
          if (ra == AccNormal || ra == AccInline)
          {
            statics.push(f);
            continue;
          }

          for (f2 in type.impl.get().statics.get())
          {
            if (f2.name == 'get_${f.name}' || f2.name == 'set_${f.name}')
            {
              switch (f2.type)
              {
                case TFun(args, _):
                  if (isAbstractStaticFunction(f2)) statics.push(f); else fields.push(f);
                default:
                  throw 'Should not happen, right? (${type.module}.${type.name}, ${f.name})';
              }

              break;
            }
          }

        case FMethod(_):
          switch (f.type)
          {
            case TFun(args, _):
              if (isAbstractStaticFunction(f)) statics.push(f); else fields.push(f);
            default:
              throw 'Should not happen, right? (${type.module}.${type.name}, ${f.name})';
          }
      }
    }

    return {fields: fields, statics: statics};
  }

  static function isAbstractStaticFunction(fun:ClassField):Bool
  {
    switch (fun.type)
    {
      case TFun(args, _):
        return (args.length == 0 || !(['this', 'this1'].contains(args[0].name))) && fun.name != '_new';
      default:
        throw 'Invalid type';
    }
  }
}

enum TypeInfo
{
  Class;
  Abstract(isEnum:Bool);
}
#end
