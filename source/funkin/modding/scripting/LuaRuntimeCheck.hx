package funkin.modding.scripting;

#if desktop
import llua.Convert;
import llua.Lua;
import llua.LuaL;
import llua.State;
#end

/**
 * Fases 1.1 y 1.2 de compatibilidad con Psych Engine.
 * 1.1: comprueba que el runtime de Lua (linc_luajit) ejecuta código.
 * 1.2: carga un .lua desde disco y llama a su función onCreate.
 * 1.3: pasa datos de Haxe a Lua (qtEngineName, qtData).
 * 1.4: pasa argumentos (tabla, número, texto) a onCreate y lee su valor de retorno (tabla) en Haxe.
 * 1.5: despacho de hooks (LuaScriptManager) sobre todos los .lua de una carpeta.
 * Solo escribe en el log; nada más depende de esto todavía.
 */
class LuaRuntimeCheck
{
  /**
   * Ruta de prueba, relativa a la carpeta donde corre el juego.
   */
  public static final TEST_FILE:String = 'mods/luacheck/test.lua';

  /**
   * Carpeta de prueba para el despacho de hooks (fase 1.5).
   */
  public static final TEST_FOLDER:String = 'mods/luacheck';

  public static function run():Void
  {
    #if desktop
    var lua:State = LuaL.newstate();
    LuaL.openlibs(lua);

    var status:Int = LuaL.dostring(lua, "_G.qtLuaCheck = 6 * 7");
    if (status != 0)
    {
      trace("[LUA] ERROR al ejecutar el script de prueba: " + Lua.tostring(lua, -1));
      Lua.pop(lua, 1);
    }
    else
    {
      Lua.getglobal(lua, "qtLuaCheck");
      var answer:String = Lua.tostring(lua, -1);
      Lua.pop(lua, 1);
      trace("[LUA] Runtime OK. Resultado de prueba (esperado 42): " + answer);
    }

    runHost();

    Lua.close(lua);
    #end
  }

  /**
   * Fase 1.5: carga todos los .lua de TEST_FOLDER y despacha hooks.
   */
  public static function runHost():Void
  {
    #if desktop
    var globals:Map<String, Dynamic> = [
      "qtEngineName" => "QT Slice",
      "qtData" => {name: "QT Slice", fps: 60, tags: ["a", "b", "c"]}
    ];

    if (LuaScriptManager.loadFolder(TEST_FOLDER, globals) == 0)
    {
      trace("[LUA] Sin scripts en " + TEST_FOLDER + ". Se omite la prueba de hooks.");
      return;
    }

    var results:Array<Dynamic> = LuaScriptManager.dispatch("onCreate", [globals.get("qtData"), 21, "hola"]);
    for (ret in results)
    {
      if (ret != null) trace("[LUA] host onCreate -> ok=" + Reflect.field(ret, "ok") + ", message=" + Reflect.field(ret, "message"));
    }

    LuaScriptManager.dispatch("onUpdate", [0.016]);
    LuaScriptManager.clear();
    trace("[LUA] Fase 1.5 OK: hooks despachados y estados cerrados.");
    #end
  }

  /**
   * Carga TEST_FILE, ejecuta su código y llama a onCreate() si existe.
   */
  public static function runFile():Void
  {
    #if desktop
    if (!sys.FileSystem.exists(TEST_FILE))
    {
      trace("[LUA] No existe " + TEST_FILE + ". Se omite la prueba de archivo.");
      return;
    }

    var lua:State = LuaL.newstate();
    LuaL.openlibs(lua);

    // 1.3 Haxe -> Lua: una variable global.
    Convert.toLua(lua, "QT Slice");
    Lua.setglobal(lua, "qtEngineName");

    var data:Dynamic = {name: "QT Slice", fps: 60, tags: ["a", "b", "c"]};
    Convert.toLua(lua, data);
    Lua.setglobal(lua, "qtData");

    // 1.3 Lua -> Haxe: pendiente (Lua.add_callback no está disponible en la versión instalada).

    if (LuaL.dofile(lua, TEST_FILE) != 0)
    {
      trace("[LUA] ERROR al cargar " + TEST_FILE + ": " + Lua.tostring(lua, -1));
      Lua.pop(lua, 1);
      Lua.close(lua);
      return;
    }

    // 1.4 Haxe -> Lua: argumentos de onCreate(data, number, text).
    // 1.4 Lua -> Haxe: onCreate devuelve una tabla que leemos aquí.
    Lua.getglobal(lua, "onCreate");
    Convert.toLua(lua, data);
    Convert.toLua(lua, 21);
    Convert.toLua(lua, "hola");
    if (Lua.pcall(lua, 3, 1, 0) != 0)
    {
      trace("[LUA] onCreate no se pudo ejecutar: " + Lua.tostring(lua, -1));
      Lua.pop(lua, 1);
    }
    else
    {
      var ret:Dynamic = Convert.fromLua(lua, -1);
      Lua.pop(lua, 1);

      if (ret == null)
      {
        trace("[LUA] onCreate no devolvió una tabla.");
      }
      else
      {
        trace("[LUA] onCreate devolvió ok=" + Reflect.field(ret, "ok") + ", doubled=" + Reflect.field(ret, "doubled") + ", message=" + Reflect.field(ret, "message"));
      }
    }

    Lua.close(lua);
    #end
  }
}
