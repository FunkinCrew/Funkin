package funkin.modding;

#if cpp
import sys.io.File;
import haxe.io.Bytes;
import cpp.cppia.Module;
#end
import funkin.util.tools.ISingleton;

@:nullSafety
class ScriptHandler implements ISingleton
{
  #if cpp
  var modules:Array<Module>;
  #end

  public function new()
  {
    #if cpp
    this.modules = [];
    #end
  }

  public function clearModules():Void
  {
    #if cpp
    modules.clear();
    #end
  }

  public function registerModule(scriptPath:String):Void
  {
    #if cpp
    var scriptBytes:Bytes = File.getBytes(scriptPath);
    if (scriptBytes == null) throw 'Could not get bytes from ${scriptPath}';

    var module:Module = Module.fromData(scriptBytes.getData());
    if (module == null) throw 'Could create module for ${scriptPath}';

    module.boot();
    modules.push(module);
    #end
  }

  public function resolveClass<T>(classPath:String):Null<Class<T>>
  {
    #if cpp
    for (m in modules)
    {
      var cls:Null<Class<T>> = m.resolveClass(classPath);
      if (cls != null) return cls;
    }
    return null;
    #else
    return cast Type.resolveClass(classPath);
    #end
  }

  public function instantiateClass<T>(classPath:String, ?args:Array<Dynamic>):Null<T>
  {
    var cls:Null<Class<T>> = resolveClass(classPath);
    return cls != null ? Type.createInstance(cls, args ?? []) : null;
  }
}
