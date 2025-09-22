package funkin;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import funkin.util.MemoryUtil;

/**
 * Extension of FlxGame for optimization sake
 */
class FunkinGame extends FlxGame
{
  override public function new(gameWidth = 0, gameHeight = 0, ?initialState:Class<FlxState>, updateFramerate = 60, drawFramerate = 60, skipSplash = false,
      startFullscreen = false)
  {
    super(gameWidth, gameHeight, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen);

    #if FLX_SOUND_TRAY
    // FlxG.game._customSoundTray wants just the class, it calls new from
    // create() in there, which gets called when it's added to the stage
    _customSoundTray = funkin.ui.options.FunkinSoundTray;
    #end
  }

  function markCacheAsDestroyable():Void
  {
    @:privateAccess {
      if (FlxG.bitmap._cache == null) FlxG.bitmap._cache = new Map();

      FlxG.bitmap.__cacheCopy.clear();

      for (k => e in FlxG.bitmap._cache)
      {
        if (e == null) continue;
        else if (e.destroyOnNoUse)
        {
          FlxG.bitmap.removeByKey(k);
          continue;
        }
        FlxG.bitmap.__cacheCopy.set(k, e);
        e.isUnused = true;
      }
    }
  }

  function clearCache():Void
  {
    @:privateAccess {
      if (FlxG.bitmap._cache == null)
      {
        FlxG.bitmap._cache = new Map();
        return;
      }

      for (key in FlxG.bitmap.__cacheCopy.keys())
      {
        var obj = FlxG.bitmap.__cacheCopy.get(key);
        var objN = FlxG.bitmap.get(key);
        if (objN != null && objN != obj)
        {
          FlxG.bitmap.remove(objN);
          if (objN != null) objN.destroy();
        }
        if (obj.isUnused || (!obj.persist && obj.useCount <= 0))
        {
          FlxG.bitmap.remove(obj);
        }
      }

      FlxG.bitmap.__cacheCopy.clear();
    }
  }

  override function switchState():Void
  {
    @:privateAccess
    FlxG.bitmap.__dontClear = true;
    // We mark the entire cache as destroyable to make loading times faster
    markCacheAsDestroyable();

    super.switchState();
    draw(); // Draw only once to render all images and put them to gpu / ram
    @:privateAccess
    FlxG.bitmap.__dontClear = false;

    clearCache();

    #if cpp
    MemoryUtil.collect(true);
    MemoryUtil.compact();
    #end
  }
}
