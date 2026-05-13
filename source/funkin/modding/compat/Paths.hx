package funkin.modding.compat;

import openfl.utils.AssetType as OpenFLAssetType;

/**
 * A utility class which evaluates asset paths,
 * checking known previous paths for backwards compatibility.
 */
class Paths
{
  /**
   * A static map of known previous paths for certain assets, or paths older mods may try to access files at.
   * Used for maintaining backwards compatibility by redirecting file queries.
   * Try not to remove any, even if they're super old!
   */
  static final PATHS:Map<String, String> = [
    // ===
    //
    // Pre-Great Sorting asset paths, with library.
    //
    'assets/preload/music/chartEditorLoop/chartEditorLoop.ogg' => 'assets/ui/editors/chart-editor/artistic-expression/artistic-expression.ogg',
    'assets/preload/music/chartEditorLoop/chartEditorLoop-metadata.json' =>
    'assets/ui/editors/chart-editor/artistic-expression/artistic-expression-metadata.json',
    'assets/preload/music/freakyMenu/freakyMenu.ogg' => 'assets/ui/main-menu/freaky-menu/freaky-menu.ogg',
    'assets/preload/music/freakyMenu/freakyMenu-metadata.json' => 'assets/ui/main-menu/freaky-menu/freaky-menu-metadata.json',
    'assets/preload/music/freeplayRandom/freeplayRandom.ogg' => 'assets/ui/freeplay/freeplay-random/freeplay-random.ogg',
    'assets/preload/music/freeplayRandom/freeplayRandom-metadata.json' => 'assets/ui/freeplay/freeplay-random/freeplay-random-metadata.json',
    'assets/preload/music/girlfriendsRingtone/girlfriendsRingtone.ogg' => 'assets/ui/title/girlfriends-ringtone/girlfriends-ringtone.ogg',
    'assets/preload/music/girlfriendsRingtone/girlfriendsRingtone-metadata.json' => 'assets/ui/title/girlfriends-ringtone/girlfriends-ringtone-metadata.json',
    'assets/preload/music/offsetsLoop/drumsLoop.ogg' => 'assets/ui/input-offsets/drums-loop/drums-loop.ogg',
    'assets/preload/music/offsetsLoop/offsetsLoop.ogg' => 'assets/ui/input-offsets/offsets-loop/offsets-loop.ogg',
    'assets/preload/music/stayFunky/stayFunky.ogg' => 'assets/ui/character-select/stay-funky/stay-funky.ogg',
    'assets/preload/music/stayFunky/stayFunky-intro.ogg' => 'assets/ui/character-select/stay-funky/stay-funky-intro.ogg',
    'assets/preload/music/stayFunky/stayFunky-metadata.json' => 'assets/ui/character-select/stay-funky/stay-funky-metadata.json',
    'assets/preload/images/storymenu/props/bf.png' => 'assets/ui/story-mode/props/bf.png',
    'assets/preload/images/storymenu/props/bf.xml' => 'assets/ui/story-mode/props/bf.xml',
    'assets/preload/images/storymenu/props/dad.png' => 'assets/ui/story-mode/props/dad.png',
    'assets/preload/images/storymenu/props/dad.xml' => 'assets/ui/story-mode/props/dad.xml',
    'assets/preload/images/storymenu/props/darnell.png' => 'assets/ui/story-mode/props/darnell.png',
    'assets/preload/images/storymenu/props/darnell.xml' => 'assets/ui/story-mode/props/darnell.xml',
    'assets/preload/images/storymenu/props/gf.png' => 'assets/ui/story-mode/props/gf.png',
    'assets/preload/images/storymenu/props/gf.xml' => 'assets/ui/story-mode/props/gf.xml',
    'assets/preload/images/storymenu/props/mom.png' => 'assets/ui/story-mode/props/mom.png',
    'assets/preload/images/storymenu/props/mom.xml' => 'assets/ui/story-mode/props/mom.xml',
    'assets/preload/images/storymenu/props/nene.png' => 'assets/ui/story-mode/props/nene.png',
    'assets/preload/images/storymenu/props/nene.xml' => 'assets/ui/story-mode/props/nene.xml',
    'assets/preload/images/storymenu/props/parents-xmas.png' => 'assets/ui/story-mode/props/parents-xmas.png',
    'assets/preload/images/storymenu/props/parents-xmas.xml' => 'assets/ui/story-mode/props/parents-xmas.xml',
    'assets/preload/images/storymenu/props/pico-player.png' => 'assets/ui/story-mode/props/pico-player.png',
    'assets/preload/images/storymenu/props/pico-player.xml' => 'assets/ui/story-mode/props/pico-player.xml',
    'assets/preload/images/storymenu/props/pico.png' => 'assets/ui/story-mode/props/pico.png',
    'assets/preload/images/storymenu/props/pico.xml' => 'assets/ui/story-mode/props/pico.xml',
    'assets/preload/images/storymenu/props/senpai.png' => 'assets/ui/story-mode/props/senpai.png',
    'assets/preload/images/storymenu/props/senpai.xml' => 'assets/ui/story-mode/props/senpai.xml',
    'assets/preload/images/storymenu/props/spaghetti.png' => 'assets/ui/story-mode/props/spaghetti.png',
    'assets/preload/images/storymenu/props/spaghetti.xml' => 'assets/ui/story-mode/props/spaghetti.xml',
    'assets/preload/images/storymenu/props/spooky.png' => 'assets/ui/story-mode/props/spooky.png',
    'assets/preload/images/storymenu/props/spooky.xml' => 'assets/ui/story-mode/props/spooky.xml',
    'assets/preload/images/storymenu/props/tankman.png' => 'assets/ui/story-mode/props/tankman.png',
    'assets/preload/images/storymenu/props/tankman.xml' => 'assets/ui/story-mode/props/tankman.xml',
    'assets/shared/images/characters/bf/Animation.json' => 'assets/gameplay/characters/bf/boyfriend/Animation.json',
    'assets/shared/images/characters/bf/spritemap1.json' => 'assets/gameplay/characters/bf/boyfriend/spritemap1.json',
    'assets/shared/images/characters/bf/spritemap1.png' => 'assets/gameplay/characters/bf/boyfriend/spritemap1.png',
    'assets/shared/images/characters/bf-death/Animation.json' => 'assets/gameplay/characters/bf/bf-dead/Animation.json',
    'assets/shared/images/characters/bf-death/spritemap1.json' => 'assets/gameplay/characters/bf/bf-dead/spritemap1.json',
    'assets/shared/images/characters/bf-death/spritemap1.png' => 'assets/gameplay/characters/bf/bf-dead/spritemap1.png',
    'assets/shared/images/characters/bfFakeOut/Animation.json' => 'assets/gameplay/characters/bf/bf-fakeout/Animation.json',
    'assets/shared/images/characters/bfFakeOut/spritemap1.json' => 'assets/gameplay/characters/bf/bf-fakeout/spritemap1.json',
    'assets/shared/images/characters/bfFakeOut/spritemap1.png' => 'assets/gameplay/characters/bf/bf-fakeout/spritemap1.png',
    //
    // Pre-Great Sorting asset paths, without library.
    //
    'assets/music/chartEditorLoop/chartEditorLoop.ogg' => 'assets/ui/editors/chart-editor/artistic-expression/artistic-expression.ogg',
    'assets/music/chartEditorLoop/chartEditorLoop-metadata.json' => 'assets/ui/editors/chart-editor/artistic-expression/artistic-expression-metadata.json',
    'assets/music/freakyMenu/freakyMenu.ogg' => 'assets/ui/main-menu/freaky-menu/freaky-menu.ogg',
    'assets/music/freakyMenu/freakyMenu-metadata.json' => 'assets/ui/main-menu/freaky-menu/freaky-menu-metadata.json',
    'assets/music/freeplayRandom/freeplayRandom.ogg' => 'assets/ui/freeplay/freeplay-random/freeplay-random.ogg',
    'assets/music/freeplayRandom/freeplayRandom-metadata.json' => 'assets/ui/freeplay/freeplay-random/freeplay-random-metadata.json',
    'assets/music/girlfriendsRingtone/girlfriendsRingtone.ogg' => 'assets/ui/title/girlfriends-ringtone/girlfriends-ringtone.ogg',
    'assets/music/girlfriendsRingtone/girlfriendsRingtone-metadata.json' => 'assets/ui/title/girlfriends-ringtone/girlfriends-ringtone-metadata.json',
    'assets/music/offsetsLoop/drumsLoop.ogg' => 'assets/ui/input-offsets/drums-loop/drums-loop.ogg',
    'assets/music/offsetsLoop/offsetsLoop.ogg' => 'assets/ui/input-offsets/offsets-loop/offsets-loop.ogg',
    'assets/music/stayFunky/stayFunky.ogg' => 'assets/ui/character-select/stay-funky/stay-funky.ogg',
    'assets/music/stayFunky/stayFunky-intro.ogg' => 'assets/ui/character-select/stay-funky/stay-funky-intro.ogg',
    'assets/music/stayFunky/stayFunky-metadata.json' => 'assets/ui/character-select/stay-funky/stay-funky-metadata.json',
    'assets/images/storymenu/props/bf.png' => 'assets/ui/story-mode/props/bf.png',
    'assets/images/storymenu/props/bf.xml' => 'assets/ui/story-mode/props/bf.xml',
    'assets/images/storymenu/props/dad.png' => 'assets/ui/story-mode/props/dad.png',
    'assets/images/storymenu/props/dad.xml' => 'assets/ui/story-mode/props/dad.xml',
    'assets/images/storymenu/props/darnell.png' => 'assets/ui/story-mode/props/darnell.png',
    'assets/images/storymenu/props/darnell.xml' => 'assets/ui/story-mode/props/darnell.xml',
    'assets/images/storymenu/props/gf.png' => 'assets/ui/story-mode/props/gf.png',
    'assets/images/storymenu/props/gf.xml' => 'assets/ui/story-mode/props/gf.xml',
    'assets/images/storymenu/props/mom.png' => 'assets/ui/story-mode/props/mom.png',
    'assets/images/storymenu/props/mom.xml' => 'assets/ui/story-mode/props/mom.xml',
    'assets/images/storymenu/props/nene.png' => 'assets/ui/story-mode/props/nene.png',
    'assets/images/storymenu/props/nene.xml' => 'assets/ui/story-mode/props/nene.xml',
    'assets/images/storymenu/props/parents-xmas.png' => 'assets/ui/story-mode/props/parents-xmas.png',
    'assets/images/storymenu/props/parents-xmas.xml' => 'assets/ui/story-mode/props/parents-xmas.xml',
    'assets/images/storymenu/props/pico-player.png' => 'assets/ui/story-mode/props/pico-player.png',
    'assets/images/storymenu/props/pico-player.xml' => 'assets/ui/story-mode/props/pico-player.xml',
    'assets/images/storymenu/props/pico.png' => 'assets/ui/story-mode/props/pico.png',
    'assets/images/storymenu/props/pico.xml' => 'assets/ui/story-mode/props/pico.xml',
    'assets/images/storymenu/props/senpai.png' => 'assets/ui/story-mode/props/senpai.png',
    'assets/images/storymenu/props/senpai.xml' => 'assets/ui/story-mode/props/senpai.xml',
    'assets/images/storymenu/props/spaghetti.png' => 'assets/ui/story-mode/props/spaghetti.png',
    'assets/images/storymenu/props/spaghetti.xml' => 'assets/ui/story-mode/props/spaghetti.xml',
    'assets/images/storymenu/props/spooky.png' => 'assets/ui/story-mode/props/spooky.png',
    'assets/images/storymenu/props/spooky.xml' => 'assets/ui/story-mode/props/spooky.xml',
    'assets/images/storymenu/props/tankman.png' => 'assets/ui/story-mode/props/tankman.png',
    'assets/images/storymenu/props/tankman.xml' => 'assets/ui/story-mode/props/tankman.xml',
    'assets/images/characters/bf/Animation.json' => 'assets/gameplay/characters/bf/boyfriend/Animation.json',
    'assets/images/characters/bf/spritemap1.json' => 'assets/gameplay/characters/bf/boyfriend/spritemap1.json',
    'assets/images/characters/bf/spritemap1.png' => 'assets/gameplay/characters/bf/boyfriend/spritemap1.png',
    'assets/images/characters/bf-death/Animation.json' => 'assets/gameplay/characters/bf/bf-dead/Animation.json',
    'assets/images/characters/bf-death/spritemap1.json' => 'assets/gameplay/characters/bf/bf-dead/spritemap1.json',
    'assets/images/characters/bf-death/spritemap1.png' => 'assets/gameplay/characters/bf/bf-dead/spritemap1.png',
    'assets/images/characters/bfFakeOut/Animation.json' => 'assets/gameplay/characters/bf/bf-fakeout/Animation.json',
    'assets/images/characters/bfFakeOut/spritemap1.json' => 'assets/gameplay/characters/bf/bf-fakeout/spritemap1.json',
    'assets/images/characters/bfFakeOut/spritemap1.png' => 'assets/gameplay/characters/bf/bf-fakeout/spritemap1.png',
    //
    // The output of a call to `funkin.Paths`, which no longer uses prefixes.
    //
    'assets/chartEditorLoop/chartEditorLoop.ogg' => 'assets/ui/editors/chart-editor/artistic-expression/artistic-expression.ogg',
    'assets/chartEditorLoop/chartEditorLoop-metadata.json' => 'assets/ui/editors/chart-editor/artistic-expression/artistic-expression-metadata.json',
    'assets/freakyMenu/freakyMenu.ogg' => 'assets/ui/main-menu/freaky-menu/freaky-menu.ogg',
    'assets/freakyMenu/freakyMenu-metadata.json' => 'assets/ui/main-menu/freaky-menu/freaky-menu-metadata.json',
    'assets/freeplayRandom/freeplayRandom.ogg' => 'assets/ui/freeplay/freeplay-random/freeplay-random.ogg',
    'assets/freeplayRandom/freeplayRandom-metadata.json' => 'assets/ui/freeplay/freeplay-random/freeplay-random-metadata.json',
    'assets/girlfriendsRingtone/girlfriendsRingtone.ogg' => 'assets/ui/title/girlfriends-ringtone/girlfriends-ringtone.ogg',
    'assets/girlfriendsRingtone/girlfriendsRingtone-metadata.json' => 'assets/ui/title/girlfriends-ringtone/girlfriends-ringtone-metadata.json',
    'assets/offsetsLoop/drumsLoop.ogg' => 'assets/ui/input-offsets/drums-loop/drums-loop.ogg',
    'assets/offsetsLoop/offsetsLoop.ogg' => 'assets/ui/input-offsets/offsets-loop/offsets-loop.ogg',
    'assets/stayFunky/stayFunky.ogg' => 'assets/ui/character-select/stay-funky/stay-funky.ogg',
    'assets/stayFunky/stayFunky-intro.ogg' => 'assets/ui/character-select/stay-funky/stay-funky-intro.ogg',
    'assets/stayFunky/stayFunky-metadata.json' => 'assets/ui/character-select/stay-funky/stay-funky-metadata.json',
    'assets/storymenu/props/bf.png' => 'assets/ui/story-mode/props/bf.png',
    'assets/storymenu/props/bf.xml' => 'assets/ui/story-mode/props/bf.xml',
    'assets/storymenu/props/dad.png' => 'assets/ui/story-mode/props/dad.png',
    'assets/storymenu/props/dad.xml' => 'assets/ui/story-mode/props/dad.xml',
    'assets/storymenu/props/darnell.png' => 'assets/ui/story-mode/props/darnell.png',
    'assets/storymenu/props/darnell.xml' => 'assets/ui/story-mode/props/darnell.xml',
    'assets/storymenu/props/gf.png' => 'assets/ui/story-mode/props/gf.png',
    'assets/storymenu/props/gf.xml' => 'assets/ui/story-mode/props/gf.xml',
    'assets/storymenu/props/mom.png' => 'assets/ui/story-mode/props/mom.png',
    'assets/storymenu/props/mom.xml' => 'assets/ui/story-mode/props/mom.xml',
    'assets/storymenu/props/nene.png' => 'assets/ui/story-mode/props/nene.png',
    'assets/storymenu/props/nene.xml' => 'assets/ui/story-mode/props/nene.xml',
    'assets/storymenu/props/parents-xmas.png' => 'assets/ui/story-mode/props/parents-xmas.png',
    'assets/storymenu/props/parents-xmas.xml' => 'assets/ui/story-mode/props/parents-xmas.xml',
    'assets/storymenu/props/pico-player.png' => 'assets/ui/story-mode/props/pico-player.png',
    'assets/storymenu/props/pico-player.xml' => 'assets/ui/story-mode/props/pico-player.xml',
    'assets/storymenu/props/pico.png' => 'assets/ui/story-mode/props/pico.png',
    'assets/storymenu/props/pico.xml' => 'assets/ui/story-mode/props/pico.xml',
    'assets/storymenu/props/senpai.png' => 'assets/ui/story-mode/props/senpai.png',
    'assets/storymenu/props/senpai.xml' => 'assets/ui/story-mode/props/senpai.xml',
    'assets/storymenu/props/spaghetti.png' => 'assets/ui/story-mode/props/spaghetti.png',
    'assets/storymenu/props/spaghetti.xml' => 'assets/ui/story-mode/props/spaghetti.xml',
    'assets/storymenu/props/spooky.png' => 'assets/ui/story-mode/props/spooky.png',
    'assets/storymenu/props/spooky.xml' => 'assets/ui/story-mode/props/spooky.xml',
    'assets/storymenu/props/tankman.png' => 'assets/ui/story-mode/props/tankman.png',
    'assets/storymenu/props/tankman.xml' => 'assets/ui/story-mode/props/tankman.xml',
    'assets/shared/characters/bf/Animation.json' => 'assets/gameplay/characters/bf/boyfriend/Animation.json',
    'assets/shared/characters/bf/spritemap1.json' => 'assets/gameplay/characters/bf/boyfriend/spritemap1.json',
    'assets/shared/characters/bf/spritemap1.png' => 'assets/gameplay/characters/bf/boyfriend/spritemap1.png',
    'assets/shared/characters/bf-death/Animation.json' => 'assets/gameplay/characters/bf/bf-dead/Animation.json',
    'assets/shared/characters/bf-death/spritemap1.json' => 'assets/gameplay/characters/bf/bf-dead/spritemap1.json',
    'assets/shared/characters/bf-death/spritemap1.png' => 'assets/gameplay/characters/bf/bf-dead/spritemap1.png',
    'assets/shared/characters/bfFakeOut/Animation.json' => 'assets/gameplay/characters/bf/bf-fakeout/Animation.json',
    'assets/shared/characters/bfFakeOut/spritemap1.json' => 'assets/gameplay/characters/bf/bf-fakeout/spritemap1.json',
    'assets/shared/characters/bfFakeOut/spritemap1.png' => 'assets/gameplay/characters/bf/bf-fakeout/spritemap1.png',
  ];

  /**
   * @param id The base path of the asset, including the extension.
   * @param type The type of asset.
   * @param library The library
   * @return String
   */
  public static function getPath(id:String, type:OpenFLAssetType, library:String = 'default'):String
  {
    // Don't use library:path since new Funkin' doesn't use asset libraries.
    var filePath:String = (library == 'default') ? 'assets/$id' : 'assets/$library/$id';

    // If the path just exists, return it. This is the most common case.
    if (funkin.assets.Assets.exists(filePath, type))
    {
      return filePath;
    }

    // If the path doesn't exist, it might be a mod backwards compatibility issue.

    // Check the list of known paths.
    if (PATHS.exists(filePath))
    {
      trace(' WARNING '.warning() + ' Converting legacy asset path $filePath to ${PATHS[filePath]}');
      return PATHS[filePath];
    }

    // Try to guess some other paths.
    var result:Null<String> = tryGuessPath(id, filePath, type);
    if (result != null) return result;

    // I guess just use the filePath and suffer whatever errors result.
    trace(' ERROR '.error() + ' Could not convert legacy asset path "$filePath" ($type), expect lots of errors!');
    return filePath;
  }

  /**
   * @param id The base ID of the asset, including the extension.
   * @param filePath The original guess at the file path, used for caching the result later if we find the true path.
   * @param type The type of asset.
   * @param library The library. Start with the `default` library, then iterate through others if we can't find it.
   * @return `String`, or `null` if a valid path couldn't be found.
   */
  static function tryGuessPath(id:String, filePath:String, type:OpenFLAssetType, library:String = 'default'):Null<String>
  {
    var result:Null<String> = null;

    // Try to guess where the path would be, pre-Great Sorting.
    // If we figure it out, add it to the list of known paths.
    var extension = haxe.io.Path.extension(id);
    switch (extension)
    {
      case 'png': // Images
        var typeFilePath = (library == 'default') ? 'assets/images/$id' : 'assets/$library/images/$id';
        // Paths for health icons.
        var fileName = haxe.io.Path.withoutDirectory(id);
        var iconFilePath = (library == 'default') ? 'assets/images/icons/$fileName' : 'assets/$library/images/icons/$fileName';
        if (funkin.assets.Assets.exists(typeFilePath, type))
        {
          result = typeFilePath;
        }
        else if (funkin.assets.Assets.exists(iconFilePath, type))
        {
          result = iconFilePath;
        }
      case 'frag' | 'vert': // Shader text
        var typeFilePath = (library == 'default') ? 'assets/shaders/$id' : 'assets/$library/shaders/$id';
        if (funkin.assets.Assets.exists(typeFilePath, type))
        {
          result = typeFilePath;
        }
      case 'txt': // Data text
        var typeFilePath = (library == 'default') ? 'assets/data/$id' : 'assets/$library/data/$id';
        if (funkin.assets.Assets.exists(typeFilePath, type))
        {
          result = typeFilePath;
        }
      case 'xml': // Data or image text
        var dataFilePath = (library == 'default') ? 'assets/data/$id' : 'assets/$library/data/$id';
        var imageFilePath = (library == 'default') ? 'assets/images/$id' : 'assets/$library/images/$id';

        if (funkin.assets.Assets.exists(dataFilePath, type))
        {
          result = dataFilePath;
        }
        else if (funkin.assets.Assets.exists(imageFilePath, type))
        {
          result = imageFilePath;
        }
      case 'json': // Data or image text
        var dataFilePath = (library == 'default') ? 'assets/data/$id' : 'assets/$library/data/$id';
        var imageFilePath = (library == 'default') ? 'assets/images/$id' : 'assets/$library/images/$id';
        var songFilePath:String = (library == 'default') ? 'assets/${id.replace('gameplay/songs/', 'songs/')}' : 'assets/$library/${id.replace('gameplay/songs/', 'songs/')}';
        var songDataFilePath:String = (library == 'default') ? 'assets/data/${id.replace('gameplay/songs/', 'songs/')}' : 'assets/$library/data/${id.replace('gameplay/songs/', 'songs/')}';

        if (funkin.assets.Assets.exists(dataFilePath, type))
        {
          result = dataFilePath;
        }
        else if (funkin.assets.Assets.exists(imageFilePath, type))
        {
          result = imageFilePath;
        }
        else if (funkin.assets.Assets.exists(songFilePath, type))
        {
          result = songFilePath;
        }
        else if (funkin.assets.Assets.exists(songDataFilePath, type))
        {
          result = songDataFilePath;
        }
      case 'ogg': // Music or sound
        var musicFilePath:String = (library == 'default') ? 'assets/music/$id' : 'assets/$library/music/$id';
        var soundFilePath:String = (library == 'default') ? 'assets/sound/$id' : 'assets/$library/sound/$id';
        var songFilePath:String = (library == 'default') ? 'assets/${id.replace('gameplay/songs/', 'songs/')}' : 'assets/$library/${id.replace('gameplay/songs/', 'songs/')}';

        if (funkin.assets.Assets.exists(musicFilePath, type))
        {
          result = musicFilePath;
        }
        else if (funkin.assets.Assets.exists(soundFilePath, type))
        {
          result = soundFilePath;
        }
        else if (funkin.assets.Assets.exists(songFilePath, type))
        {
          result = songFilePath;
        }
      case 'mp4' | 'mkv': // videos, without or with subtitles
        var videoFilePath:String = (library == 'default') ? 'assets/videos/$id' : 'assets/$library/videos/$id';

        if (funkin.assets.Assets.exists(videoFilePath, type))
        {
          result = videoFilePath;
        }

      default:
        // No idea, sorry.
    }

    if (result != null)
    {
      trace(' WARNING '.warning() + ' Converting legacy asset path $filePath to $result');
      PATHS[filePath] = result;
      return result;
    }

    // Try some other asset libraries?
    if (library == 'default')
    {
      for (libraryToTry in ['shared', 'songs', 'videos'])
      {
        result = tryGuessPath(id, filePath, type, libraryToTry);
        if (result != null) return result;
      }
    }

    // No idea, sorry.
    return null;
  }
}
