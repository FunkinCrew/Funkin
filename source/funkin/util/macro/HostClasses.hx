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
            var types:Array<Type> = modules.get(t.module) ?? [];
            modules.set(t.module, types.concat([type]));
          case TType(_.get() => t, _):
            if (haxe.io.Path.normalize(t.pos.getInfos().file).contains('haxe/std')) continue;
            var types:Array<Type> = modules.get(t.module) ?? [];
            modules.set(t.module, types.concat([type]));
          case TAbstract(_.get() => t, _):
            if (haxe.io.Path.normalize(t.pos.getInfos().file).contains('haxe/std')) continue;
            var types:Array<Type> = modules.get(t.module) ?? [];
            modules.set(t.module, types.concat([type]));
          case TEnum(_.get() => t, _):
            if (haxe.io.Path.normalize(t.pos.getInfos().file).contains('haxe/std')) continue;
            var types:Array<Type> = modules.get(t.module) ?? [];
            modules.set(t.module, types.concat([type]));
          default:
            throw 'Unsupported type: ${type}';
        }
      }

      for (module => types in modules)
      {
        var content:String = 'package ${module.split('.').slice(0, -1).join('.')};\n\n';

        for (type in types)
        {
          switch (type)
          {
            case TInst(_.get() => t, params):
              content += t.isPrivate ? 'private ' : '';
              content += '${t.isInterface ? 'interface' : 'class'} ${t.name}${paramsToString(params)}\n';
              content += '{\n';
              for (f in t.statics.get())
                content += '  extern static ${fieldToString(f, params, false)};\n';

              for (f in t.fields.get().concat(t.constructor != null ? [t.constructor.get()] : []))
                content += '  extern ${fieldToString(f, params, false)};\n';

              content += '}\n\n';

            case TAbstract(_.get() => t, params):
              content += 'abstract ${t.name}${paramsToString(params)}(${typeToString(t.type, params)}) ';
              content += t.from.map((from) -> from.field == null ? 'from ${typeToString(from.t, params)} ' : '').join(' ');
              content += t.to.map((to) -> to.field == null ? 'to ${typeToString(to.t, params)} ' : '').join(' ');
              content += '\n';
              content += '{\n';

              if (t.impl != null) for (f in t.impl.get().statics.get())
                content += '  extern ${fieldToString(f, params, true)};\n';

              content += '}\n\n';

            case TEnum(_.get() => t, params):
              content += 'enum ${t.name}${paramsToString(params)}\n';
              content += '{\n';

              for (n in t.names)
                content += '  ${n};\n';

              content += '}\n\n';

            case TType(_.get() => t, params):
              content += 'typedef ${t.name}${paramsToString(params)} = ${typeToString(t.type, params)};\n\n';

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

  static function fieldToString(field:ClassField, params:Array<Type>, fromAbstractType:Bool):String
  {
    var string:String = '';
    string += field.isPublic ? 'public ' : 'private ';
    string += field.isFinal ? 'final ' : '';
    string += field.isAbstract ? 'abstract ' : '';

    params = params.concat(field.params.map((p) -> p.t));

    switch (field.kind)
    {
      case FVar(ra, wa):
        var rs:String = getter(ra);
        var ws:String = setter(wa);

        if (!field.isFinal) string += 'var ';

        if (fromAbstractType && rs == 'default') string = 'static ' + string;

        string += '${field.name}';
        if (!field.isFinal) string += '($rs, $ws)';
        string += ' : ${typeToString(field.type, params)}';

      case FMethod(k):
        string += switch (k)
        {
          case MethNormal: '';
          case MethInline: ''; // 'inline ';
          case MethMacro: ''; // 'macro ';
          case MethDynamic: 'dynamic ';
        }

        string += 'function ${(fromAbstractType && field.name == '_new') ? 'new' : field.name}${paramsToString(field.params.map((p) -> p.t))}';

        var noRet:Bool = field.name == 'new' || (fromAbstractType && field.name == '_new');

        // using the expr() to get default values for arguments
        // sadly if there is no expr() it means we can't get the default values
        if (field.expr() != null)
        {
          switch (field.expr().expr)
          {
            case TFunction(f):
              var args:Array<String> = [];
              if (fromAbstractType
                && field.name != '_new'
                && (f.args.length == 0 || (f.args.length > 0 && !f.args[0].v.name.startsWith('this')))) string = 'static ' + string;
              for (a in f.args)
              {
                if (fromAbstractType && a.v.name.startsWith('this')) continue;
                var arg:String = '${a.v.name} : ${typeToString(a.v.t, params)}';
                if (a.value != null) arg += ' = ${a.value.toString(true)}';
                args.push(arg);
              }
              string += '(${args.join(', ')})';
              if (!noRet) string += ' : ${typeToString(f.t, params)}';
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
              if (fromAbstractType
                && field.name != '_new'
                && (args_.length == 0 || (args_.length > 0 && !args_[0].name.startsWith('this')))) string = 'static ' + string;
              for (a in args_)
              {
                if (fromAbstractType && a.name.startsWith('this')) continue;
                args.push((a.opt ? '?' : '') + '${a.name} : ${typeToString(a.t, params)}');
              }
              string += '(${args.join(',')})';
              if (!noRet) string += ' : ${typeToString(ret, params)}';
            default:
              throw 'Should not happen, right?';
          }
        }
    }

    return string;
  }

  static function getter(access:VarAccess):String
  {
    return switch (access)
    {
      case AccNormal: 'default';
      case AccNo: 'null';
      case AccNever: 'never';
      case AccCall: 'get';
      case AccInline: 'default'; // 'inline';
      default: 'default';
    };
  }

  static function setter(access:VarAccess):String
  {
    return switch (access)
    {
      case AccNormal: 'default';
      case AccNo: 'null';
      case AccNever: 'never';
      case AccCall: 'set';
      case AccInline: 'default'; // 'inline';
      default: 'default';
    };
  }

  static function typeToString(type:Type, params:Array<Type>):String
  {
    function typeParams(underlyingParams:Array<Type>):String
    {
      if (underlyingParams.length == 0) return '';
      return '<' + underlyingParams.map((t) -> typeToString(t, params)).join(', ') + '>';
    }

    function typePath(type:Type):String
    {
      return switch (type)
      {
        case TInst(_.get() => t, params):
          '${t.module}.${t.name}${typeParams(params)}';
        case TAbstract(_.get() => t, params):
          '${t.module}.${t.name}${typeParams(params)}';
        case TEnum(_.get() => t, params):
          '${t.module}.${t.name}${typeParams(params)}';
        case TType(_.get() => t, params):
          '${t.module}.${t.name}${typeParams(params)}';
        case TAnonymous(_.get() => t):
          '{\n${[for (f in t.fields) '  ${f.name} : ${typeToString(f.type, params)}'].join(',\n')}\n}';
        default:
          type.toString();
      };
    }

    var string:String = typePath(type);
    for (p in params)
    {
      var p1:String = switch (p) {
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

  static function paramsToString(params:Array<Type>):String
  {
    if (params.length == 0) return '';
    return '<' + params.map((t) -> typeToString(t, params)).join(', ') + '>';
  }
}
#end
