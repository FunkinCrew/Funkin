package funkin.modding.scripting;

#if desktop
import llua.Convert;
import llua.Lua;
import llua.LuaL;
import llua.State;
#end

/**
 * Fase 1.5: un estado de Lua por script, con despacho de hooks estilo Psych Engine.
 * Un hook es una función global de Lua (onCreate, onUpdate, onBeatHit...).
 * Si el script no define el hook, se ignora sin error.
 */
class LuaScriptHost
{
  public final path:String;
  public var closed(default, null):Bool = false;

  #if desktop
  var lua:State;
  #end

  public function new(path:String)
  {
    this.path = path;
  }

  /**
   * Crea el estado de Lua, registra las globales y ejecuta el script.
   * @return true si el script cargó sin errores.
   */
  public function load(globals:Map<String, Dynamic>):Bool
  {
    #if desktop
    lua = LuaL.newstate();
    LuaL.openlibs(lua);

    for (name => value in globals)
    {
      Convert.toLua(lua, value);
      Lua.setglobal(lua, name);
    }

    if (LuaL.dofile(lua, path) != 0)
    {
      trace("[LUA] ERROR al cargar " + path + ": " + Lua.tostring(lua, -1));
      Lua.pop(lua, 1);
      close();
      return false;
    }
    return true;
    #else
    return false;
    #end
  }

  /**
   * Llama al hook con los argumentos dados y devuelve su valor de retorno.
   * @return El valor devuelto por Lua, o null si no existe el hook o hubo error.
   */
  public function call(hook:String, args:Array<Dynamic>):Dynamic
  {
    #if desktop
    if (closed) return null;

    Lua.getglobal(lua, hook);
    if (Lua.type(lua, -1) != Lua.LUA_TFUNCTION)
    {
      Lua.pop(lua, 1);
      return null;
    }

    for (arg in args) Convert.toLua(lua, arg);

    if (Lua.pcall(lua, args.length, 1, 0) != 0)
    {
      trace("[LUA] Error en " + hook + " (" + path + "): " + Lua.tostring(lua, -1));
      Lua.pop(lua, 1);
      return null;
    }

    var ret:Dynamic = Convert.fromLua(lua, -1);
    Lua.pop(lua, 1);
    return ret;
    #else
    return null;
    #end
  }

  public function close():Void
  {
    if (closed) return;
    closed = true;
    #if desktop
    Lua.close(lua);
    #end
  }
}

/**
 * Carga todos los .lua de una carpeta y despacha hooks a todos ellos.
 */
class LuaScriptManager
{
  static var hosts:Array<LuaScriptHost> = [];

  /**
   * @return Cuántos scripts se cargaron.
   */
  public static function loadFolder(folder:String, globals:Map<String, Dynamic>):Int
  {
    #if desktop
    if (!sys.FileSystem.exists(folder)) return 0;

    var loaded:Int = 0;
    for (file in sys.FileSystem.readDirectory(folder))
    {
      if (!StringTools.endsWith(file, ".lua")) continue;

      var host:LuaScriptHost = new LuaScriptHost(folder + "/" + file);
      if (host.load(globals))
      {
        hosts.push(host);
        loaded++;
      }
    }
    trace("[LUA] " + loaded + " script(s) cargado(s) desde " + folder);
    return loaded;
    #else
    return 0;
    #end
  }

  /**
   * Llama a un hook en todos los scripts cargados.
   * @return Los valores devueltos (null cuando un script no tiene el hook).
   */
  public static function dispatch(hook:String, args:Array<Dynamic>):Array<Dynamic>
  {
    var results:Array<Dynamic> = [];
    for (host in hosts) results.push(host.call(hook, args));
    return results;
  }

  public static function clear():Void
  {
    for (host in hosts) host.close();
    hosts = [];
  }
}
