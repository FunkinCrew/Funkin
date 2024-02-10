package funkin.util.plugins;

import flixel.FlxBasic;

/**
 * A plugin which adds functionality to press `F5` to reload all game assets, then reload the current state.
 * This is useful for hot reloading assets during development.
 */
class ReloadAssetsDebugPlugin extends FlxBasic
{
  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new ReloadAssetsDebugPlugin());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.F5)
    {
      funkin.modding.PolymodHandler.forceReloadAssets();

      // Create a new instance of the current state, so old data is cleared.
      FlxG.resetState();
    }
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
