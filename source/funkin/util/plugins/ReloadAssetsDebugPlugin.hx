package funkin.util.plugins;

import flixel.FlxG;
import flixel.FlxBasic;
import funkin.ui.MusicBeatState;
import funkin.ui.MusicBeatSubState;
#if android
import funkin.mobile.external.android.CallbackUtil;
#end

/**
 * A plugin which adds functionality to press `F5` to reload all game assets, then reload the current state.
 * This is useful for hot reloading assets during development.
 */
@:nullSafety
class ReloadAssetsDebugPlugin extends FlxBasic
{
  public function new()
  {
    super();

    #if android
    CallbackUtil.onActivityResult.add(onActivityResult);
    #end
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new ReloadAssetsDebugPlugin());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    #if html5
    if (FlxG.keys.justPressed.FIVE && FlxG.keys.pressed.SHIFT)
    #else
    if (FlxG.keys.justPressed.F5)
    #end
    {
      reload();
    }
  }

  public override function destroy():Void
  {
    super.destroy();

    #if android
    if (CallbackUtil.onActivityResult.has(onActivityResult))
    {
      CallbackUtil.onActivityResult.remove(onActivityResult);
    }
    #end
  }

  @:noCompletion
  function reload():Void
  {
    var state:Dynamic = FlxG.state;
    if (state is MusicBeatState || state is MusicBeatSubState) state.reloadAssets();
    else
    {
      funkin.modding.PolymodHandler.forceReloadAssets();

      // Create a new instance of the current state, so old data is cleared.
      FlxG.resetState();
    }
  }

  #if android
  @:noCompletion
  function onActivityResult(resultCode:Int, requestCode:Int):Void
  {
    if (resultCode == CallbackUtil.DATA_FOLDER_CLOSED)
    {
      reload();
    }
  }
  #end
}
