package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr.Field;

using haxe.macro.Tools;
using StringTools;

#if !macro
#if (cpp && scriptable)
@:build(funkin.util.macro.HostClasses.exclude())
class HostClasses {}
#end
#else
class HostClasses
{
  static final BLACK_LIST:Array<String> = [
    // classes
    'Sys',
    'Reflect',
    'Type',
    'cpp.Lib',
    'Unserializer',
    'lime.system.CFFI',
    'lime.system.JNI',
    'lime.system.System',
    'lime.utils.Assets',
    'openfl.utils.Assets',
    'openfl.Lib',
    'openfl.system.ApplicationDomain',
    'openfl.net.SharedObject',
    'openfl.desktop.NativeProcess',
    // packages
    'funkin.api.newgrounds.*',
    'io.newgrounds.*',
    'sys.*'
  ];

  /**
   * TODO: Handle generics correctly
   */
  static function onGenerate(types:Array<Type>):Void
  {
    for (type in types)
    {
      var classPath:String = type.toString();

      var isBlackListed:Bool = false;
      for (black in BLACK_LIST)
      {
        if ((black.endsWith('.*') && classPath.startsWith(black.substr(0, black.length - 2))) || (black == classPath))
        {
          isBlackListed = true;
          break;
        }
      }
      if (isBlackListed) continue;

      var filePath:String = classPath.indexOf('<') == -1 ? classPath : classPath.substr(0, classPath.indexOf('<'));
      var parts:Array<String> = filePath.split('.');
      if (parts.length == 0) continue;
      var typeName:String = parts.pop();

      // skip abstract implementations
      if (parts.length > 0 && parts[parts.length - 1].charAt(0).toUpperCase() == parts[parts.length - 1].charAt(0)) continue;

      var folderPath:String = parts.join('/');

      var folderPath:String = 'script_std/' + folderPath;

      sys.FileSystem.createDirectory(folderPath);

      var filePath:String = folderPath + '/' + typeName + '.hx';
      var content:String = 'package ' + parts.join('.') + ';\n\n';

      switch (type)
      {
        case TInst(_.get() => t, _):
          content += 'extern class ' + typeName + '\n{\n';
          for (f in t.fields.get())
          {
            var fieldCode:String = fieldToString(f, false);
            fieldCode = 'extern ' + fieldCode;
            content += '  ' + fieldCode + '\n';
          }

          for (f in t.statics.get())
          {
            var fieldCode:String = fieldToString(f, false);
            fieldCode = 'extern static ' + fieldCode;
            content += '  ' + fieldCode + '\n';
          }
          content += '}\n';

        case TEnum(_.get() => e, _):
          content += 'extern enum ' + typeName + '\n{\n';
          for (n in e.names)
          {
            content += '  ' + n + ';\n';
          }

          for (_ => c in e.constructs)
          {
            switch (c.type)
            {
              case TFun(args, _):
                var argList:String = args.map(arg -> '${arg.name}: ${arg.t.toString()}').join(', ');
                content += '  ' + c.name + '(' + argList + ');\n';
              default:
                content += '  ' + c.name + ';\n';
            }
          }
          content += '}\n';

        case TType(_.get() => t, _):
          content += 'typedef ' + typeName + ' = ' + t.type.toString() + ';\n';

        case TAbstract(_.get() => a, _):
          content += 'abstract ' + typeName + '(' + a.type.toString() + ')';
          for (from in a.from)
          {
            content += ' from ' + from.t.toString();
          }
          for (to in a.to)
          {
            content += ' to ' + to.t.toString();
          }
          content += '\n{\n';

          if (a.impl == null) continue;

          for (f in a.impl.get().statics.get())
          {
            var fieldCode:String = fieldToString(f, true);
            fieldCode = 'extern ' + fieldCode;
            content += '  ' + fieldCode + '\n';
          }
          content += '}\n';

        default:
          Context.warning('funkin.util.macro.HostClasses.onGenerate(): Type not handled: ' + type.toString(), Context.currentPos());
      }

      sys.io.File.saveContent(filePath, content);
    }
  }

  static function exclude():Array<Field>
  {
    Context.onGenerate(onGenerate);

    return Context.getBuildFields();
  }

  static function fieldToString(field:ClassField, fromAbstractType:Bool):String
  {
    var fieldCode:String = '';

    fieldCode += field.isPublic ? 'public ' : 'private ';
    if (field.isAbstract) fieldCode += 'abstract ';
    if (field.isFinal) fieldCode += 'final ';

    switch (field.kind)
    {
      case FVar(read, write):
        var getStr:String = switch (read)
        {
          case AccNormal: 'default';
          case AccNo: 'null';
          case AccResolve: 'resolve';
          case AccCall: 'get';
          case AccNever: 'never';
          default: 'default';
        };

        var setStr:String = switch (write)
        {
          case AccNormal: 'default';
          case AccNo: 'null';
          case AccResolve: 'resolve';
          case AccCall: 'set';
          case AccNever: 'never';
          default: 'default';
        };

        if (fromAbstractType && getStr == 'default') fieldCode += 'static ';

        fieldCode += 'var ${field.name}';

        fieldCode += '(';
        fieldCode += getStr;
        fieldCode += ', ';
        fieldCode += setStr;
        fieldCode += ')';

        fieldCode += ': ' + field.type.toString() + ';';

      case FMethod(kind):
        var kindStr:String = switch (kind)
        {
          case MethNormal: '';
          case MethInline: ''; // inline is not supported in externs
          case MethDynamic: 'dynamic ';
          case MethMacro: 'macro ';
        }

        fieldCode += kindStr;

        switch (field.type)
        {
          case TFun(args, ret):
            if (fromAbstractType)
            {
              if (args.length > 0 && args[0].name == 'this') args.shift();
              else if (args.length == 0 || (args.length > 0 && args[0].name != 'this')) fieldCode += 'static ';
            }

            fieldCode += 'function ${field.name}(';
            var argList:String = args.map(a -> (a.opt ? '?' : '') + '${a.name}: ${a.t.toString()}').join(', ');
            fieldCode += argList;
            fieldCode += '): ' + ret.toString() + ';';
          default:
            throw 'Should not happen';
        }
    }

    return fieldCode;
  }
}
#end
