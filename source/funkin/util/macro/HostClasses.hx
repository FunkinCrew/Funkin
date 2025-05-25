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
    // big classes that are probably not needed
    // they just take a long time to process
    'ManifestResources',
    'lime._internal.backend.native.NativeCFFI',
    // packages
    'funkin.api.newgrounds.*',
    'io.newgrounds.*',
    'sys.*'
  ];

  static function isBlacklisted(name:String):Bool
  {
    for (entry in BLACK_LIST)
    {
      if (entry.endsWith(".*"))
      {
        var prefix:String = entry.substr(0, entry.length - 2);
        if (name.startsWith(prefix)) return true;
      }
      else
      {
        if (name == entry) return true;
      }
    }
    return false;
  }

  static function generate():Array<Field>
  {
    Context.onGenerate((types) -> {
      var files:Map<String, Null<String>> = new Map<String, Null<String>>();

      for (type in types)
      {
        var module:String;
        var file:String;

        switch (type)
        {
          case TInst(_.get() => t, _):
            module = t.module;
            file = t.pos.getInfos().file;
          case TEnum(_.get() => e, _):
            module = e.module;
            file = e.pos.getInfos().file;
          case TType(_.get() => t, _):
            module = t.module;
            file = t.pos.getInfos().file;
          case TAbstract(_.get() => a, _):
            module = a.module;
            file = a.pos.getInfos().file;
          default:
            throw 'funkin.util.macro.HostClasses.generate(): Type not handled: ${type.toString()}';
        }

        if (isBlacklisted(module)) files.set(file, null);
        else if (!files.exists(file)) files.set(file, module.split('.').join('/'));
      }

      var count:Int = [for (m in files.iterator()) if (m != null) 0].length;
      var finished:Int = 0;

      for (file => module in files)
      {
        if (module == null) continue;

        var content:String = sys.io.File.getContent(file);

        var regex:EReg = ~/\b((?:public|private|static|override|dynamic|final|\s)*function\s+\w+\s*\([^)]*\)(?:\s*:\s*[\w<>\[\], ?]+)?)/g;

        var contentCopy:String = content;
        while (regex.match(contentCopy))
        {
          var signature:String = regex.matched(1);
          var body:String = regex.matchedRight();
          contentCopy = regex.matchedRight();

          if (~/\b(?:inline|macro|extern)\b/.match(regex.matchedLeft())) continue;

          var doCheck:Bool = false;
          var braces:Int = 0;

          var i:Int = 0;
          while (true)
          {
            var c:String = body.charAt(i++);
            if (c.length == 0) break;

            if (c == '{')
            {
              doCheck = true;
              braces++;
            }
            else if (c == '}')
            {
              braces--;
            }

            if (doCheck && braces == 0)
            {
              content = content.replace(body.substr(0, i), '');
              contentCopy = contentCopy.replace(body.substr(0, i), '');
              content = content.replace(signature, 'extern ${signature};');
              break;
            }
          }
        }
        var folderPath:String = 'script_std/${module.split('/').slice(0, -1).join('/')}';
        var filePath:String = 'script_std/${module}.hx';

        sys.FileSystem.createDirectory(folderPath);
        sys.io.File.saveContent(filePath, content);

        trace('Generated ${++finished}/${count}');
      }
    });

    return Context.getBuildFields();
  }
}
#end
