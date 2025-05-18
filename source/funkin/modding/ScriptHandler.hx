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
  var module:Null<Module>;
  #end

  public function new()
  {
    #if cpp
    this.module = null;
    #end
  }

  public function loadScripts():Void
  {
    #if cpp
    var scriptPath:String = 'script.cppia';
    var scriptBytes:Bytes = File.getBytes(scriptPath);
    if (scriptBytes == null) throw 'Could not get bytes from ${scriptPath}';

    module = Module.fromData(scriptBytes.getData());
    if (module == null) throw 'Could create module for ${scriptPath}';

    module.boot();
    #end
  }

  public function resolveClass<T>(classPath:String):Null<Class<T>>
  {
    #if cpp
    if (module == null) throw 'Scripts have not been loaded yet';
    return cast module.resolveClass(classPath);
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
