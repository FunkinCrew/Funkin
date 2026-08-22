package funkin.util.plugins;

import flixel.util.typeLimit.NextState;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import funkin.ui.transition.preload.hotreload.HotReloadState;
import funkin.ui.transition.preload.hotreload.HotReloadState.HotReloadStateParams;
import funkin.ui.MusicBeatState;

/**
 * A plugin which adds functionality to press `F5` to reload all game assets, then reload the current state.
 * This is useful for hot reloading assets during development.
 */
@:nullSafety
class ReloadAssetsDebugPlugin extends FlxBasic
{
  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new ReloadAssetsDebugPlugin());
  }

  override public function update(elapsed:Float):Void
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

  @:noCompletion
  function reload():Void
  {
    FlxTransitionableState.skipNextTransIn = true;

    var isScripted:Bool = FlxG.state._asc != null;

    var hotReloadParams:HotReloadStateParams = {};
    if (isScripted)
    {
      @:privateAccess
      var path:String = FlxG.state._asc?.fullyQualifiedName ?? '';

      trace('Hot-reloading scripted state: ' + path);

      // FlxState is a scripted state, give it a different constructor
      if (FlxG.state is MusicBeatState)
      {
        var s:MusicBeatState = cast FlxG.state;
        s.onPreHotReload();

        hotReloadParams = s.getHotReloadParams();
      }
      else
      {
        // Just load the scripted FlxState instead.
        var scriptedNextState:NextState = () ->
        {
          var newState:Null<FlxState> = FlxState.scriptInit(path);
          if (newState == null) return new funkin.ui.mainmenu.MainMenuState();
          return newState;
        }

        hotReloadParams = {
          targetState: scriptedNextState
        }
      }
      FlxG.switchState(() -> new HotReloadState(hotReloadParams));
    }
    else
    {
      // Fallback to using default params.
      @:privateAccess
      hotReloadParams = {
        targetState: FlxG.state._constructor
      };

      if (Std.isOfType(FlxG.state, MusicBeatState))
      {
        var s:MusicBeatState = cast FlxG.state;
        s.onPreHotReload();

        // Fetch the custom hot reload params for this state.
        hotReloadParams = s.getHotReloadParams();
      }
      FlxG.switchState(() -> new HotReloadState(hotReloadParams));
    }
  }
}
