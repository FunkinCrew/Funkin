package funkin.modding;

import haxe.CallStack;

/**
 * Guards the game against errors thrown by scripts, so scripts can be stopped without crashing the game.
 * (for cppia)
 */
class ScriptGuard
{
  static final brokenClasses:Map<String, Bool> = new Map<String, Bool>();
  static final brokenObjects:haxe.ds.ObjectMap<Dynamic, Bool> = new haxe.ds.ObjectMap<Dynamic, Bool>();
  public static var brokenCount(default, null):Int = 0;

  /**
   * Every frame with the class it belongs to, which the usual stack string leaves out.
   */
  static function describe(stack:Array<StackItem>):String
  {
    var lines:Array<String> = [];

    for (item in stack)
    {
      switch (item)
      {
        case Method(c, f):
          lines.push('  $c.$f()');
        case FilePos(Method(c, f), file, line):
          lines.push('  $c.$f() at $file#$line');
        case FilePos(_, file, line):
          lines.push('  $file#$line');
        default:
          lines.push('  $item');
      }
    }

    return lines.join('\n');
  }

  public static function clear():Void
  {
    if (brokenCount == 0) return;

    brokenClasses.clear();
    brokenObjects.clear();
    brokenCount = 0;
  }

  public static function isBroken(target:Dynamic):Bool
  {
    if (brokenCount == 0 || target == null) return false;
    if (brokenObjects.exists(target)) return true;

    var name:Null<String> = classNameOf(target);
    return name != null && brokenClasses.exists(name);
  }

  public static function run(target:Dynamic, context:String, body:Void->Void):Void
  {
    if (brokenCount > 0 && isBroken(target)) return;

    try
    {
      body();
    }
    catch (e:Dynamic)
    {
      if (!handle(e, context, target)) throw e;
    }
  }

  public static function get<T>(target:Dynamic, context:String, body:Void->T, fallback:T):T
  {
    if (brokenCount > 0 && isBroken(target)) return fallback;

    try
    {
      return body();
    }
    catch (e:Dynamic)
    {
      if (!handle(e, context, target)) throw e;
      return fallback;
    }
  }

  public static function handle(error:Dynamic, context:String, ?target:Dynamic):Bool
  {
    var stack:Array<StackItem> = [];

    try
    {
      stack = CallStack.exceptionStack(true);
    }
    catch (_:Dynamic) {}

    // Only compiled scripts are guarded. Everything else keeps the reporting it already had,
    // which for hscript means the error polymod reports with the script's own position.
    var frame:Null<ScriptFrame> = findScriptFrame(stack);
    if (frame == null) return false;

    var culprit:String = frame.cls;

    if (target != null && !brokenObjects.exists(target))
    {
      brokenObjects.set(target, true);
      brokenCount++;
    }

    if (brokenClasses.exists(culprit)) return true;

    brokenClasses.set(culprit, true);
    brokenCount++;

    freezeInstances(culprit);
    report(culprit, frame, context, error, stack);

    return true;
  }

  static function findScriptFrame(stack:Array<StackItem>):Null<ScriptFrame>
  {
    for (item in stack)
    {
      switch (item)
      {
        case Method(c, f):
          if (c != null && isScriptClass(c)) return {cls: c, func: f, where: null};
        case FilePos(Method(c, f), file, line):
          if (c != null && isScriptClass(c)) return {cls: c, func: f, where: '$file#$line'};
        default:
      }
    }

    return null;
  }

  static function isScriptClass(name:String):Bool
  {
    #if (hxcpp && POLYMOD_CPPIA)
    return polymod.hscript._internal.PolymodCppiaClassReference.isScriptClass(name);
    #else
    return false;
    #end
  }

  static function scriptClass(name:String):Null<Class<Dynamic>>
  {
    #if (hxcpp && POLYMOD_CPPIA)
    return polymod.hscript._internal.PolymodCppiaClassReference.resolveScriptClass(name);
    #else
    return null;
    #end
  }

  static function classNameOf(target:Dynamic):Null<String>
  {
    if (target == null) return null;

    var cls:Null<Class<Dynamic>> = Type.getClass(target);
    return cls == null ? null : Type.getClassName(cls);
  }

  static function freezeInstances(clsName:String):Void
  {
    try
    {
      var cls:Null<Class<Dynamic>> = scriptClass(clsName);
      if (cls == null || flixel.FlxG.state == null) return;

      flixel.FlxG.state.forEachExists(function(basic:flixel.FlxBasic) {
        if (!Std.isOfType(basic, cls)) return;

        basic.active = false;
        basic.visible = false;
      }, true);
    }
    catch (_:Dynamic) {}
  }

  static function report(culprit:String, frame:Null<ScriptFrame>, context:String, error:Dynamic, stack:Array<StackItem>):Void
  {
    var where:String = context;

    if (frame != null)
    {
      where = '$culprit.${frame.func ?? "?"}()';
      if (frame.where != null) where += ' (${frame.where})';
      where += ', during $context';
    }

    var stackText:String = '';

    try
    {
      stackText = CallStack.toString(stack);
    }
    catch (_:Dynamic) {}

    var message:String = 'Script "$culprit" threw at $where, so it has been stopped.\n\n$error$stackText';

    polymod.Polymod.error(SCRIPT_RUNTIME_EXCEPTION, message, SCRIPT_RUNTIME);
  }
}

typedef ScriptFrame =
{
  var cls:String;
  var func:Null<String>;

  var where:Null<String>;
}
