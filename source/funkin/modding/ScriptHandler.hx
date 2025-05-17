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

  public function resolveClass(classPath:String):Null<Class<Dynamic>>
  {
    #if cpp
    for (m in modules)
    {
      var cls:Null<Class<Dynamic>> = m.resolveClass(classPath);
      if (cls != null) return cls;
    }
    return null;
    #else
    return Type.resolveClass(classPath);
    #end
  }

  public function instantiateClass(classPath:String, ?args:Array<Dynamic>):Null<Dynamic>
  {
    var cls:Null<Class<Dynamic>> = resolveClass(classPath);
    return cls != null ? Type.createInstance(cls, args ?? []) : null;
  }
}
