package funkin.util.plugins;

import funkin.ui.ScriptedMusicBeatState;
import flixel.FlxG;
import flixel.FlxBasic;
import funkin.ui.MusicBeatState;
import funkin.ui.MusicBeatSubState;
import funkin.ui.transition.preload.hotreload.HotReloadState;

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
    var state:Dynamic = FlxG.state;
    var isScripted:Bool = state is ScriptedMusicBeatState;
    if (isScripted)
    {
      var s:ScriptedMusicBeatState = cast FlxG.state;
      @:privateAccess
      var path = s._asc.fullyQualifiedName;
      trace('Hot-reloading scripted state: ' + path);
      var state:Dynamic = ScriptedMusicBeatState.scriptInit(path);
      FlxG.switchState(() -> new HotReloadState(state));
    }
    else
    {
      var builder = state._constructor;

      trace('Hot-reloading unscripted state: ' + state);
      FlxG.switchState(() -> new HotReloadState(builder));
    }
  }
}
