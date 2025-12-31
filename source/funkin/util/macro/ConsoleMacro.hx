package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
#if !macro
import flixel.FlxG;
#end

using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;
using funkin.util.AnsiUtil;

class ConsoleMacro
{
  #if !macro
  /**
   * Gets called in `Main.hx` after FlxGame is initalized, and is what we use to easy add debug functions to flixel console
   */
  public static function init():Void
  {
    for (className in classes)
    {
      var classInstance = Type.resolveClass(className);
      if (classInstance != null) FlxG.console.registerClass(classInstance);
    }
  }
  #end

  // Runtime-accessible array of console classes
  static var classes:Array<String> = [];

  /**
   * Called at runtime to register a class with the console
   */
  public static function registerClass(className:String):Void
  {
    classes.push(className);
    trace("Registered console class: " + className);
  }

  #if macro
  static macro function buildConsoleClass():Array<Field>
  {
    var cl = Context.getLocalClass().toString();
    var fields = Context.getBuildFields();

    // Generate a static field with initialization expression that runs at class load time
    var initFieldName = "__consoleRegistration_" + StringTools.replace(cl, ".", "_");
    var initField =
      {
        name: initFieldName,
        access: [AStatic, APrivate],
        kind: FVar(macro :Bool, macro
          {
            funkin.util.macro.ConsoleMacro.registerClass($v{cl});
            true;
          }),
        pos: Context.currentPos()
      };

    fields.push(initField);
    Sys.println(' INFO '.bold().bg_blue() + ' Generated console registration for: $cl');
    return fields;
  }
  #end
}

@:autoBuild(funkin.util.macro.ConsoleMacro.buildConsoleClass())
interface ConsoleClass {}
