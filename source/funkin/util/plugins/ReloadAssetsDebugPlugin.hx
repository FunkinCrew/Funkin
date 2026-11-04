package funkin.util.plugins;

import flixel.util.typeLimit.NextState;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import funkin.ui.transition.preload.hotreload.HotReloadState;
import funkin.ui.transition.preload.hotreload.HotReloadState.HotReloadStateParams;
import funkin.ui.MusicBeatState;
import funkin.ui.MusicBeatSubState;

/**
 * A plugin which adds functionality to press `F5` to reload all game assets, then reload the current state.
 * This is useful for hot reloading assets during development.
 */
@:nullSafety
class ReloadAssetsDebugPlugin extends FlxBasic
{
  public static var hotReloadInProgress:Bool = false;

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new ReloadAssetsDebugPlugin());
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (!hotReloadInProgress)
    {
      #if html5
      if (FlxG.keys.justPressed.FIVE && FlxG.keys.pressed.SHIFT)
      #else
      if (FlxG.keys.justPressed.F5)
      #end
      {
        reload();
      }

      #if html5
      if (FlxG.keys.justPressed.SEVEN && FlxG.keys.pressed.SHIFT)
      #else
      if (FlxG.keys.justPressed.F7)
      #end
      {
        funkin.assets.FunkinAssetCache.instance.debug_listCachedAssets();
      }
    }
  }

  @:noCompletion
  function reload():Void
  {
    hotReloadInProgress = true;
    FlxTransitionableState.skipNextTransIn = true;

    var state:Dynamic = cast FlxG.state;
    var isScripted:Bool = state._asc != null;

    var hotReloadParams:HotReloadStateParams = {};
    if (isScripted)
    {
      @:privateAccess
      var path:String = state._asc?.fullyQualifiedName ?? '';
      var constructorArgs:Array<Dynamic> = state._asc?.getConstructorArgs() ?? [];

      trace('Hot-reloading scripted state: ' + path);

      if (Std.isOfType(state, MusicBeatState) || Std.isOfType(state, MusicBeatSubState))
      {
        state.onPreHotReload();

        hotReloadParams = state.getHotReloadParams();
      }
      else
      {
        var newState:Null<FlxState> = null;

        // Just load the scripted FlxState instead.
        var scriptedNextState:NextState = () ->
        {
          if (Std.isOfType(state, FlxState))
          {
            newState = FlxState.scriptInit(path, ...constructorArgs);
          }
          else if (Std.isOfType(state, FlxSubState))
          {
            newState = FlxSubState.scriptInit(path, ...constructorArgs);
          }
          if (newState == null) return new funkin.ui.mainmenu.MainMenuState();
          return newState;
        }

        hotReloadParams = {
          targetState: scriptedNextState
        }
      }
      // Directly switch to HotReloadState; we don't need Transition since HotReloadState handles asset loading.
      FlxG.switchState(() -> new HotReloadState(hotReloadParams));
    }
    else
    {
      @:nullSafety(Off)
      var clsName:Null<String> = Type.getClassName(Type.getClass(state));
      if (clsName != null && funkin.modding.CppiaScripts.exists(clsName))
      {
        trace('Hot-reloading compiled state: ' + clsName);
        if (Std.isOfType(state, MusicBeatState) || Std.isOfType(state, MusicBeatSubState)) state.onPreHotReload();
        hotReloadParams = {
          targetState: () ->
          {
            var newState:Null<FlxState> = funkin.modding.CppiaScripts.exists(clsName) ? cast funkin.modding.CppiaScripts.create(clsName) : null;
            if (newState == null) return new funkin.ui.mainmenu.MainMenuState();
            return newState;
          }
        };
        // Directly switch to HotReloadState; we don't need Transition since HotReloadState handles asset loading.
        FlxG.switchState(() -> new HotReloadState(hotReloadParams));
        return;
      }
      // Fallback to using default params.
      hotReloadParams = {
        targetState: state._constructor
      };

      if (Std.isOfType(state, MusicBeatState) || Std.isOfType(state, MusicBeatSubState))
      {
        state.onPreHotReload();

        // Fetch the custom hot reload params for this state.
        hotReloadParams = state.getHotReloadParams();
      }
      // Directly switch to HotReloadState; we don't need Transition since HotReloadState handles asset loading.
      FlxG.switchState(() -> new HotReloadState(hotReloadParams));
    }
  }
}
