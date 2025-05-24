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
    'sys.*'
  ];

  /**
   * TODO: remove as many function bodies as possible from the generated code,
   * in order to reduce the size of the generated code. Abstract inline functions require
   * the function body to be present, so we cannot remove them.
   */
  static function generate():Array<Field>
  {
    Context.onGenerate((types) -> {
      var files:Map<String, String> = new Map<String, String>();

      for (type in types)
      {
        switch (type)
        {
          case TInst(_.get() => t, _):
            if (files.exists(t.pos.getInfos().file)) continue;
            files.set(t.pos.getInfos().file, t.module.split('.').join('/'));
          case TEnum(_.get() => e, _):
            if (files.exists(e.pos.getInfos().file)) continue;
            files.set(e.pos.getInfos().file, e.module.split('.').join('/'));
          case TType(_.get() => t, _):
            if (files.exists(t.pos.getInfos().file)) continue;
            files.set(t.pos.getInfos().file, t.module.split('.').join('/'));
          case TAbstract(_.get() => a, _):
            if (files.exists(a.pos.getInfos().file)) continue;
            files.set(a.pos.getInfos().file, a.module.split('.').join('/'));
          default:
            Context.warning('funkin.util.macro.HostClasses.generate(): Type not handled: ' + type.toString(), Context.currentPos());
        }
      }

      for (file => module in files)
      {
        var content = sys.io.File.getContent(file);

        var folderPath:String = 'script_std/' + module.split('/').slice(0, -1).join('/');
        var filePath:String = 'script_std/' + module + '.hx';

        sys.FileSystem.createDirectory(folderPath);
        sys.io.File.saveContent(filePath, content);
      }
    });

    return Context.getBuildFields();
  }
}
#end
