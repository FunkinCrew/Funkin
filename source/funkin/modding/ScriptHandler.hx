package funkin.modding;

#if cpp
import sys.io.File;
import sys.FileSystem;
import haxe.Timer;
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

  static final DEFINES:String = funkin.util.macro.MacroUtil.getDefinesAsCommand();
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
    var cmd:Process = new Process('"haxe/haxe.exe" --cppia script.cppia -cp assets/scripts __Boot__ -D dll_import=export_classes.info $DEFINES');

    if (cmd.exitCode() != 0)
    {
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
    var classes:Array<Class<Dynamic>> = Reflect.callMethod(__boot__, Reflect.field(__boot__, '__boot__'), []);

    trace(classes);
    for (clazz in classes)
    {
      trace(Type.getClassName(clazz), clazz);
      classMap.set(Type.getClassName(clazz), clazz);
    }

    trace('Loaded ${classMap.size()} scripted classes');

    FileSystem.deleteFile(scriptPath);

    cmd.close();
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

  public function listClasses():Array<Class<Dynamic>>
  {
    #if cpp
    return classMap.values();
    #else
    throw 'Temporary throw';
    #end
  }

  public function listSubclassesOf<T>(parentClass:Class<T>):Array<T>
  {
    #if cpp
    var classes:Array<T> = [];
    for (clazz in listClasses())
    {
      if (Std.isOfType(clazz, parentClass))
      {
        classes.push(cast clazz);
      }
    }
    return classes;
    #else
    throw 'Temporary throw';
    #end
  }
}
