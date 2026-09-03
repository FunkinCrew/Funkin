package funkin;

import flixel.FlxGame;
import funkin.modding.ScriptGuard;
import funkin.util.logging.CrashHandler;
import funkin.modding.PolymodHandler;

class FunkinGame extends FlxGame
{
  static final UNKNOWN_LIMIT:Int = 30;

  var unknownErrors:Int = 0;

  public function new(gameWidth:Int = 0, gameHeight:Int = 0, ?initialState:flixel.util.typeLimit.NextState.InitialState, updateFramerate:Int = 60,
      drawFramerate:Int = 60, skipSplash:Bool = false, startFullscreen:Bool = false)
  {
    super(gameWidth, gameHeight, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen);
  }

  override function update(deltaTime:Float):Void
  {
    if (!guarding())
    {
      super.update(deltaTime);
      return;
    }

    try
    {
      super.update(deltaTime);
      unknownErrors = 0;
    }
    catch (e:Dynamic)
    {
      var stack:Array<haxe.CallStack.StackItem> = captureStack();
      if (!absorb(e, 'an update'))
      {
        CrashHandler.pendingStack = stack;
        throw e;
      }
    }
  }

  override function draw():Void
  {
    if (!guarding())
    {
      super.draw();
      return;
    }

    try
    {
      super.draw();
      unknownErrors = 0;
    }
    catch (e:Dynamic)
    {
      var stack:Array<haxe.CallStack.StackItem> = captureStack();
      if (!absorb(e, 'a draw'))
      {
        CrashHandler.pendingStack = stack;
        throw e;
      }
    }
  }

  function guarding():Bool
  {
    return PolymodHandler.loadedModIds.length > 0;
  }

  function captureStack():Array<haxe.CallStack.StackItem>
  {
    try
    {
      return haxe.CallStack.exceptionStack(true);
    }
    catch (_:Dynamic)
    {
      return [];
    }
  }

  function absorb(error:Dynamic, context:String):Bool
  {
    if (ScriptGuard.handle(error, context))
    {
      unknownErrors = 0;
      return true;
    }

    if (PolymodHandler.loadedModIds.length == 0) return false;

    unknownErrors++;
    if (unknownErrors >= UNKNOWN_LIMIT) return false;

    if (unknownErrors == 1) ScriptGuard.reportUnknown(error, context);

    return true;
  }
}
