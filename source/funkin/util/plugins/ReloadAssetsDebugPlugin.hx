package funkin.util.plugins;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import funkin.ui.transition.preload.hotreload.HotReloadState;
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

    var state:Dynamic = FlxG.state;
    var isScripted:Bool = state._asc != null;
    if (isScripted)
    {
      var s:MusicBeatState = cast FlxG.state;
      @:privateAccess
      var path:String = s._asc?.fullyQualifiedName ?? '';
      trace('Hot-reloading scripted state: ' + path);
      FlxG.switchState(() -> new HotReloadState(() ->
      {
        var newState:Null<funkin.ui.MusicBeatState> = MusicBeatState.scriptInit(path);
        if (newState == null) return new funkin.ui.mainmenu.MainMenuState();
        return newState;
      }));
    }
    else
    {
      var builder = state._constructor;

      trace('Hot-reloading unscripted state: ' + state);
      FlxG.switchState(() -> new HotReloadState(builder));
    }
  }
}
