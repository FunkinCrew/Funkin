package funkin.ui.charSelect;

import animate.FlxAnimateFrames;
import flixel.FlxG;

/**
 * Utility class for handling the atlases loaded by CharSelect & co. in an efficient way.
 * TODO: Maybe this should be a general utility class instead?
 */
class CharSelectAtlasHandler
{
  static final framesCache:Map<String, FlxAnimateFrames> = [];

  public static function loadAtlas(path:String, ?settings:FlxAnimateSettings):Null<FlxAnimateFrames>
  {
    if (framesCache.exists(path)) return framesCache.get(path);

    var result:FlxAnimateFrames = FlxAnimateFrames.fromAnimate(Paths.animateAtlas(path),
      {
        swfMode: settings?.swfMode ?? true,
        filterQuality: settings?.filterQuality ?? MEDIUM,
        cacheOnLoad: settings?.cacheOnLoad ?? false
      });

    if (result == null)
    {
      FlxG.log.error('Failed to load atlas at path $path!');
      return null;
    }

    result.parent.destroyOnNoUse = false;
    framesCache.set(path, result);
    return result;
  }

  public static function clearAtlasCache():Void
  {
    for (frames in framesCache.iterator())
    {
      // NOTE: Doing this already calls checkUseCount!
      frames.parent.destroyOnNoUse = true;
    }
    framesCache.clear();
  }
}
