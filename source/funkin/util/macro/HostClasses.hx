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
        var directory:String = haxe.io.Path.normalize(haxe.io.Path.directory(sys.FileSystem.absolutePath(file)));

        for (cp in cps)
        {
          if (!directory.contains(cp)) continue;

          directory = haxe.io.Path.join([cp, directory.substr(cp.length + 1).split('/')[0]]);

          if (!directoriesToCopy.contains(directory)) directoriesToCopy.push(directory);

          break;
        }
      }

      // necessary because some macros depend on the assets
      directoriesToCopy.push(haxe.io.Path.normalize(sys.FileSystem.absolutePath('.haxelib/flixel/git/assets')));

      sys.io.File.saveContent('.copy_libs', directoriesToCopy.join('\n'));
    });

    return Context.getBuildFields();
  }
}
#end
