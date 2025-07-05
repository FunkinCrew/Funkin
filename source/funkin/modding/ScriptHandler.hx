package funkin.modding;

#if cpp
import haxe.ds.List;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import sys.io.Process;
import haxe.io.Bytes;
import cpp.cppia.Module;
#end
import funkin.util.tools.ISingleton;

@:nullSafety
class ScriptHandler implements ISingleton
{
  #if cpp
  var classMap:Map<String, Class<Dynamic>>;
  #end

  public function new()
  {
    #if cpp
    this.classMap = new Map<String, Class<Dynamic>>();
    #end
  }

  public function loadScripts():Void
  {
    #if cpp
    var oldStdPath:String = Sys.getEnv('HAXE_STD_PATH');
    Sys.putEnv('HAXE_STD_PATH', Path.join([Path.normalize(Sys.getCwd()), 'haxe', 'std']));

    var cmd:Process = new Process('"haxe/haxe.exe" -debug --cppia script.cppia -cp assets/scripts __Boot__ -D dll_import=export_classes.info --macro "include(\\"\\", true, [], [\\"assets/scripts\\"])"');

    if (cmd.exitCode() != 0)
    {
      Sys.putEnv('HAXE_STD_PATH', oldStdPath);
      trace('Failed to compile scripts: ${cmd.stderr.readAll().toString()}');
      return;
    }

    var scriptPath:String = 'script.cppia';
    var scriptBytes:Bytes = File.getBytes(scriptPath);
    if (scriptBytes == null) throw 'Could not get bytes from ${scriptPath}';

    var module:Module = Module.fromData(scriptBytes.getData());
    if (module == null) throw 'Could not create module for ${scriptPath}';

    module.boot();

    var __boot__:Class<Dynamic> = module.resolveClass('__Boot__');
    var classes:Array<String> = haxe.rtti.Meta.getType(__boot__).classList.map((c) -> cast(c, String));

    for (clazz in classes)
    {
      classMap.set(clazz, module.resolveClass(clazz));
    }

    trace('Loaded ${classMap.size()} scripted classes');

    FileSystem.deleteFile(scriptPath);

    cmd.close();

    Sys.putEnv('HAXE_STD_PATH', oldStdPath);
    #end
  }

  public function resolveClass<T>(classPath:String):Null<Class<T>>
  {
    #if cpp
    return classMap.exists(classPath) ? cast classMap.get(classPath) : null;
    #else
    return cast Type.resolveClass(classPath);
    #end
  }

  public function instantiateClass<T>(classPath:String, ?args:Array<Dynamic>):Null<T>
  {
    var clazz:Null<Class<T>> = resolveClass(classPath);
    return clazz != null ? Type.createInstance(clazz, args ?? []) : null;
  }

  #if cpp
  function listClasses():Array<Class<Dynamic>>
  {
    return classMap.values();
  }

  public function listSubclassesOf<T>(parentClass:Class<T>):List<Class<T>>
  {
    var classes:List<Class<T>> = new List<Class<T>>();
    for (clazz in listClasses())
    {
      var o:Any = Type.createEmptyInstance(clazz);
      if (Std.isOfType(o, parentClass))
      {
        classes.add(cast clazz);
      }
    }
    return classes;
  }
  #else
  public function listSubclassesOf<T>(parentClass:Class<T>):List<Class<T>>
  {
    throw 'Temporary throw';
  }
  #end
}
