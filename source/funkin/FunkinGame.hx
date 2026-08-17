package funkin;

import flixel.FlxGame;
import funkin.modding.ScriptGuard;
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
    try
    {
      super.update(deltaTime);
      unknownErrors = 0;
    }
    catch (e:Dynamic)
    {
      if (!absorb(e, 'an update')) throw e;
    }
  }

  override function draw():Void
  {
    try
    {
      super.draw();
      unknownErrors = 0;
    }
    catch (e:Dynamic)
    {
      if (!absorb(e, 'a draw')) throw e;
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
