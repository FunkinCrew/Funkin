package funkin.ui.transition.preload.hotreload;

import funkin.assets.Assets;
import funkin.assets.FunkinAssetCache;
import funkin.assets.Paths.AssetPath;
import funkin.data.BaseRegistry.LoadEntriesResult;
import funkin.data.character.CharacterRegistry;
import funkin.data.dialogue.ConversationRegistry;
import funkin.data.dialogue.DialogueBoxRegistry;
import funkin.data.dialogue.SpeakerRegistry;
import funkin.data.event.SongEventRegistry;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongRegistry;
import funkin.data.stage.StageRegistry;
import funkin.data.stickers.StickerRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.modding.module.ModuleHandler;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.util.tasks.TaskHandler;
import lime.app.Future;
import polymod.Polymod;

/**
 * Reloads the enabled mods, the scripts, and every registry, without touching the asset cache.
 *
 * This is everything `HotReloadState` does apart from purging assets. It's separate so it can run while another state
 * is still on screen (Like the mod menu does this during its electrocution sequence), and so the list of registries only lives in one place.
 * I love this, can't you tell? Hehehe.
 *
 * All callbacks are ran on the main thread
 */
class ModReloader
{
  /**
   * Whether a reload is currently running.
   */
  public static var isReloading(default, null):Bool = false;

  public static function cachePersistentAssets(?onProgress:Int->Int->Void, ?onComplete:Void->Void):Void
  {
    var progress = (loaded:Int, total:Int) ->
    {
      if (onProgress != null) onProgress(loaded, total);
    };

    var finish = () ->
    {
      if (onComplete != null) onComplete();
    };

    queueCachePersistentGraphics(progress, finish);
  }

  /**
   * Reloads the enabled mods, then the scripts, then the registry data, then calls `create()` on every module.
   * Failed steps are reported and skipped, like they are in `HotReloadState`, so `onComplete` is always called.
   *
   * @param onProgress Called with how far along the reload is, in the same units `HotReloadState` shows on its progress bar.
   * @param onComplete Called once everything has finished.
   */
  public static function reload(?onProgress:Int->Int->Void, ?onComplete:Void->Void):Void
  {
    if (isReloading)
    {
      trace('A mod reload is already running, ignoring the request.');
      return;
    }

    isReloading = true;

    var progress = (loaded:Int, total:Int) ->
    {
      if (onProgress != null) onProgress(loaded, total);
    };

    var finish = () ->
    {
      isReloading = false;
      if (onComplete != null) onComplete();
    };

    queueLoadEnabledMods(progress, finish);
  }

  /**
   * Step 1. Forcibly clear the script and module cache so they can be reloaded once mods are loaded.
   * Then, initialize mods.
   */
  static function queueLoadEnabledMods(progress:Int->Int->Void, finish:Void->Void):Void
  {
    beginStep('load enabled mods');

    TaskHandler.performSimpleTask(() ->
    {
      ModuleHandler.clearModuleCache();
      Polymod.clearScripts();

      funkin.modding.PolymodHandler.loadEnabledMods();

      // This task needs to be done immediately after changing the modlist.
      FunkinAssetCache.instance.cacheAssetLists(true);

      return true;
    }).onComplete((_) -> afterLoadEnabledMods(progress, finish)).onError((error) ->
      {
        reportStepFailed('load enabled mods', error);
        afterLoadEnabledMods(progress, finish);
      });
  }

  static function afterLoadEnabledMods(progress:Int->Int->Void, finish:Void->Void):Void
  {
    progress(2, 10);

    queueLoadScripts(progress, finish);
  }

  /**
   * Step 2. Asynchronously load scripts from base game and all enabled mods.
   */
  static function queueLoadScripts(progress:Int->Int->Void, finish:Void->Void):Void
  {
    beginStep('load scripts');

    var scriptFuture = funkin.modding.PolymodHandler.loadScripts(true);

    scriptFuture.onComplete((_result) -> afterLoadScripts(progress, finish)).onError((error) ->
    {
      reportStepFailed('load scripts', error);
      afterLoadScripts(progress, finish);
    });
  }

  static function afterLoadScripts(progress:Int->Int->Void, finish:Void->Void):Void
  {
    trace('Script loading complete');

    progress(3, 10);

    // Load registry data asynchronously.
    queueLoadRegistryData(progress, finish);
  }

  /**
   * Step 3. Asynchronously load registry data from base game and all enabled mods.
   */
  static function queueLoadRegistryData(progress:Int->Int->Void, finish:Void->Void):Void
  {
    beginStep('load registry data');

    var futures:Array<Future<LoadEntriesResult>> = [];

    // Do Song retrospeeds still load asynchronously?
    // What.
    // Song retrospeeds.
    // what..

    futures.push(SongRegistry.instance.loadEntriesAsync());
    futures.push(LevelRegistry.instance.loadEntriesAsync());
    futures.push(NoteStyleRegistry.instance.loadEntriesAsync());
    futures.push(PlayerRegistry.instance.loadEntriesAsync());
    futures.push(ConversationRegistry.instance.loadEntriesAsync());
    futures.push(DialogueBoxRegistry.instance.loadEntriesAsync());
    futures.push(SpeakerRegistry.instance.loadEntriesAsync());
    futures.push(AlbumRegistry.instance.loadEntriesAsync());
    futures.push(StageRegistry.instance.loadEntriesAsync());
    futures.push(StickerRegistry.instance.loadEntriesAsync());
    futures.push(FreeplayStyleRegistry.instance.loadEntriesAsync());
    futures.push(SongEventRegistry.loadEventCacheAsync());
    futures.push(NoteKindManager.loadNoteKindsAsync());
    futures.push(CharacterRegistry.instance.loadEntriesAsync());
    futures.push(ModuleHandler.loadModuleCacheAsync());

    var registryFuture = lime.app.Promises.allSettled(futures);

    registryFuture.onProgress((loaded:Int, total:Int) ->
    {
      trace('Registry loading completed: $loaded/$total');
      progress(3 + Std.int(5 * loaded / total), 10);
    });

    registryFuture.onComplete((_) -> afterLoadRegistryData(progress, finish)).onError((error) ->
    {
      reportStepFailed('load registry data', error);
      afterLoadRegistryData(progress, finish);
    });
  }

  static function afterLoadRegistryData(progress:Int->Int->Void, finish:Void->Void):Void
  {
    // Call create() on each module when the future is complte.
    try
    {
      ModuleHandler.callOnCreate();
    }
    catch (error:Dynamic)
    {
      reportStepFailed('module create', error);
    }

    cachePersistentAssets(progress, finish);
  }

  /**
   * Step 4. Restore the same persistent asset groups that the game preloads at startup.
   * Keep the groups sequential to avoid loading every image, sound, and data file at once.
   */
  static function queueCachePersistentGraphics(progress:Int->Int->Void, finish:Void->Void):Void
  {
    beginStep('cache persistent graphics');
    progress(8, 10);

    Assets.cacheAllFlxGraphics(Assets.queryPersistentAssets(IMAGE), true)
      .onComplete((_) -> queueCachePersistentFonts(progress, finish))
      .onError((error) ->
      {
        reportStepFailed('cache persistent graphics', error);
        queueCachePersistentFonts(progress, finish);
      });
  }

  static function queueCachePersistentFonts(progress:Int->Int->Void, finish:Void->Void):Void
  {
    beginStep('cache persistent fonts');

    Assets.cacheAllFonts(Assets.queryPersistentAssets(FONT))
      .onComplete((_) -> queueCachePersistentSounds(progress, finish))
      .onError((error) ->
      {
        reportStepFailed('cache persistent fonts', error);
        queueCachePersistentSounds(progress, finish);
      });
  }

  static function queueCachePersistentSounds(progress:Int->Int->Void, finish:Void->Void):Void
  {
    beginStep('cache persistent sounds');

    Assets.cacheAllSounds(Assets.queryPersistentAssets(SOUND), true)
      .onComplete((_) -> queueCachePersistentData(progress, finish))
      .onError((error) ->
      {
        reportStepFailed('cache persistent sounds', error);
        queueCachePersistentData(progress, finish);
      });
  }

  static function queueCachePersistentData(progress:Int->Int->Void, finish:Void->Void):Void
  {
    beginStep('cache persistent data');

    var assetsToCache:Array<AssetPath> = [];
    assetsToCache.append(Assets.queryPersistentAssets(TEXT));
    assetsToCache.append(Assets.queryPersistentAssets(JSON));
    assetsToCache.append(Assets.queryPersistentAssets(SHADER));
    assetsToCache.append(Assets.queryPersistentAssets(SCRIPTED_CLASS));
    assetsToCache.append(Assets.queryPersistentAssets(SCRIPT));
    assetsToCache.append(Assets.queryPersistentAssets(XML));
    assetsToCache.append(Assets.queryPersistentAssets(UNKNOWN));

    Assets.cacheAll(assetsToCache, true)
      .onComplete((_) -> afterCachePersistentAssets(progress, finish))
      .onError((error) ->
      {
        reportStepFailed('cache persistent data', error);
        afterCachePersistentAssets(progress, finish);
      });
  }

  static function afterCachePersistentAssets(progress:Int->Int->Void, finish:Void->Void):Void
  {
    progress(10, 10);
    finish();
  }

  static function beginStep(step:String):Void
  {
    trace('Queue task: $step...');
  }

  static function reportStepFailed(step:String, error:Dynamic):Void
  {
    var message:String = 'Hot reload step "$step" failed: $error';

    trace(message);
    FlxG.log.error(message);
  }
}
