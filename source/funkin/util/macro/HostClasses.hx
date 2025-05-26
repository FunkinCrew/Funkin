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
    // packages
    'funkin.api.newgrounds.*',
    'io.newgrounds.*',
    'sys.*',
    // unused classes
    'ManifestResources',
    'ApplicationMain',
  ];

  static function isBlacklisted(name:String):Bool
  {
    for (entry in BLACK_LIST)
    {
      if (entry.endsWith('.*'))
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
      var cps:Array<String> = [
        for (cp in Context.getClassPath())
          if (cp.length > 0) haxe.io.Path.normalize(sys.FileSystem.absolutePath(cp))
      ];
      cps = cps.filter((cp) -> !cp.contains('haxe/std'));

      var directoriesToCopy:Array<String> = [];

      for (type in types)
      {
        var file:String;
        switch (type)
        {
          case TInst(_.get() => t, _):
            file = t.pos.getInfos().file;
          case TType(_.get() => t, _):
            file = t.pos.getInfos().file;
          case TAbstract(_.get() => t, _):
            file = t.pos.getInfos().file;
          case TEnum(_.get() => t, _):
            file = t.pos.getInfos().file;
          default:
            throw 'Unsupported type: ${type}';
        }
        var directory:String = haxe.io.Path.normalize(haxe.io.Path.directory(file));

        for (cp in cps)
        {
          if (!directory.contains(cp)) continue;

          directory = haxe.io.Path.join([cp, directory.substr(cp.length + 1).split('/')[0]]);

          if (!directoriesToCopy.contains(directory)) directoriesToCopy.push(directory);

          break;
        }
      }

      // maybe rather copy the directories in PostBuildCppia.hx?
      // that way we don't do it twice
      for (directory in directoriesToCopy)
      {
        copyDirectory(directory, 'script_std/${directory.split('/').pop()}');
      }
    });

    return Context.getBuildFields();
  }

  static function copyDirectory(source:String, target:String):Void
  {
    if (!sys.FileSystem.exists(source)) throw 'Source directory does not exist: ${source}';

    if (!sys.FileSystem.exists(target)) sys.FileSystem.createDirectory(target);

    for (file in sys.FileSystem.readDirectory(source))
    {
      var sourceFile:String = haxe.io.Path.join([source, file]);
      var targetFile:String = haxe.io.Path.join([target, file]);

      if (sys.FileSystem.isDirectory(sourceFile)) copyDirectory(sourceFile, targetFile);
      else if (!isBlacklisted(haxe.io.Path.withoutExtension(sourceFile)) && !sys.FileSystem.exists(targetFile))
        sys.io.File.saveContent(targetFile, sys.io.File.getContent(sourceFile));
    }
  }
}
#end
