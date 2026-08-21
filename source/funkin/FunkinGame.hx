package funkin;

import flixel.FlxGame;
import funkin.modding.ScriptGuard;

class FunkinGame extends FlxGame
{
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
    }
    catch (e:Dynamic)
    {
      if (!ScriptGuard.handle(e, 'an update')) throw e;
    }
  }

  override function draw():Void
  {
    try
    {
      super.draw();
    }
    catch (e:Dynamic)
    {
      if (!ScriptGuard.handle(e, 'a draw')) throw e;
    }
  }
}
